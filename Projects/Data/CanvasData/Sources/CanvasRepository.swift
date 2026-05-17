import Foundation
import ComposableArchitecture
import CanvasDomain
import Core
import Moya

public final class CanvasJsonStore: @unchecked Sendable {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(fileURL: URL = CanvasJsonStore.defaultFileURL()) {
        self.fileURL = fileURL
        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.decoder = JSONDecoder()
    }

    public static func defaultFileURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("canvas/canvas_store.json")
    }

    public func read() -> CanvasStoreSnapshot {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return CanvasStoreSnapshot() }
        return (try? decoder.decode(CanvasStoreSnapshot.self, from: Data(contentsOf: fileURL))) ?? CanvasStoreSnapshot()
    }

    public func write(_ snapshot: CanvasStoreSnapshot) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try encoder.encode(snapshot).write(to: fileURL, options: [.atomic])
    }
}

public final class CanvasRepositoryImpl: CanvasRepository {
    private let store: CanvasJsonStore
    private let idProvider: @Sendable () -> String
    private lazy var provider = MoyaProvider<CanvasAPI>()

    public init(store: CanvasJsonStore = CanvasJsonStore(), idProvider: @escaping @Sendable () -> String = { UUID().uuidString }) {
        self.store = store
        self.idProvider = idProvider
    }

    public func fetchCanvas(sharedSpaceId: String) -> Effect<DataResult<SharedCanvasVO>> {
        guard let sharedSpaceId = valid(sharedSpaceId) else { return failure("sharedSpaceId is required") }
        let store = store
        let idProvider = idProvider
        return Effect.run { send in
            var snapshot = store.read()
            if let canvas = snapshot.canvases.first(where: { $0.sharedSpaceId == sharedSpaceId }) {
                await send(DataResult(isSuccess: true, data: canvas.toVO()))
                return
            }
            let canvas = SharedCanvasDTO(id: idProvider(), sharedSpaceId: sharedSpaceId, title: "우리 낙서장", latestSnapshotVersion: 0, latestSnapshotUrl: nil, localSnapshotPath: nil)
            snapshot.canvases.append(canvas)
            try? store.write(snapshot)
            await send(DataResult(isSuccess: true, data: canvas.toVO()))
        }
    }

    public func fetchStrokes(sharedSpaceId: String, afterSequence: Int?) -> Effect<DataResult<[CanvasStrokeVO]>> {
        guard let sharedSpaceId = valid(sharedSpaceId) else { return failure("sharedSpaceId is required") }
        let store = store
        return Effect.run { send in
            let strokes = store.read().strokes
                .filter { $0.sharedSpaceId == sharedSpaceId && (afterSequence == nil || $0.sequence > afterSequence!) }
                .sorted { $0.sequence < $1.sequence }
                .map { $0.toVO() }
            await send(DataResult(isSuccess: true, data: strokes))
        }
    }

    public func appendStroke(_ stroke: CanvasStrokeVO) -> Effect<DataResult<CanvasStrokeVO>> {
        guard valid(stroke.sharedSpaceId) != nil else { return failure("sharedSpaceId is required") }
        let store = store
        return Effect.run { send in
            var snapshot = store.read()
            snapshot.strokes.removeAll { $0.id == stroke.id }
            snapshot.strokes.append(CanvasStrokeDTO(stroke, pendingSync: true))
            try? store.write(snapshot)
            await send(DataResult(isSuccess: true, data: stroke))
        }
    }

    public func clearCanvas(sharedSpaceId: String) -> Effect<DataResult<SharedCanvasVO>> {
        guard let sharedSpaceId = valid(sharedSpaceId) else { return failure("sharedSpaceId is required") }
        let store = store
        let idProvider = idProvider
        return Effect.run { send in
            var snapshot = store.read()
            snapshot.strokes.removeAll { $0.sharedSpaceId == sharedSpaceId }
            let existing = snapshot.canvases.first(where: { $0.sharedSpaceId == sharedSpaceId })
            let canvas = SharedCanvasDTO(id: existing?.id ?? idProvider(), sharedSpaceId: sharedSpaceId, title: existing?.title ?? "우리 낙서장", latestSnapshotVersion: (existing?.latestSnapshotVersion ?? 0) + 1, latestSnapshotUrl: nil, localSnapshotPath: existing?.localSnapshotPath)
            snapshot.canvases.removeAll { $0.sharedSpaceId == sharedSpaceId }
            snapshot.canvases.append(canvas)
            try? store.write(snapshot)
            await send(DataResult(isSuccess: true, data: canvas.toVO()))
        }
    }

    public func updateSnapshot(_ snapshotVO: CanvasSnapshotVO) -> Effect<DataResult<CanvasSnapshotVO>> {
        guard valid(snapshotVO.sharedSpaceId) != nil else { return failure("sharedSpaceId is required") }
        let store = store
        return Effect.run { send in
            var snapshot = store.read()
            var storedSnapshot = snapshotVO
            if let localPath = storedSnapshot.localPath {
                let sourceURL = URL(fileURLWithPath: localPath)
                if let appGroupURL = try? CanvasSnapshotFileStore.copyLatestSnapshot(from: sourceURL) {
                    storedSnapshot = CanvasSnapshotVO(id: snapshotVO.id, canvasId: snapshotVO.canvasId, sharedSpaceId: storedSnapshot.sharedSpaceId, version: storedSnapshot.version, imageUrl: storedSnapshot.imageUrl, localPath: appGroupURL.path, width: snapshotVO.width, height: snapshotVO.height)
                }
            }
            snapshot.snapshots.removeAll { $0.sharedSpaceId == storedSnapshot.sharedSpaceId && $0.canvasId == storedSnapshot.canvasId }
            snapshot.snapshots.append(CanvasSnapshotDTO(storedSnapshot))
            if let index = snapshot.canvases.firstIndex(where: { $0.sharedSpaceId == storedSnapshot.sharedSpaceId }) {
                snapshot.canvases[index].latestSnapshotVersion = storedSnapshot.version
                snapshot.canvases[index].latestSnapshotUrl = storedSnapshot.imageUrl
                snapshot.canvases[index].localSnapshotPath = storedSnapshot.localPath
            }
            try? store.write(snapshot)
            await send(DataResult(isSuccess: true, data: storedSnapshot))
        }
    }

    public func pollRemoteStrokes(sharedSpaceId: String, afterSequence: Int?) -> Effect<DataResult<[CanvasStrokeVO]>> {
        guard let sharedSpaceId = valid(sharedSpaceId) else { return failure("sharedSpaceId is required") }
        guard ConfigManager.shared.hasValidAPIBaseURL else { return failure(ConfigManager.missingAPIBaseURLMessage) }
        let localProvider = provider
        return Effect.run { send in
            let result = await localProvider.request(.strokes(sharedSpaceId: sharedSpaceId, afterSequence: afterSequence))
            let mapped: DataResult<[CanvasStrokeVO]> = DataResult(result, dtoType: [CanvasStrokeDTO].self) { $0.map { $0.toVO() } }
            await send(mapped)
        }
    }

    public func appendRemoteStroke(_ stroke: CanvasStrokeVO) -> Effect<DataResult<CanvasStrokeVO>> {
        guard ConfigManager.shared.hasValidAPIBaseURL else { return failure(ConfigManager.missingAPIBaseURLMessage) }
        let localProvider = provider
        return Effect.run { send in
            let result = await localProvider.request(.appendStroke(sharedSpaceId: stroke.sharedSpaceId, stroke: stroke))
            let mapped: DataResult<CanvasStrokeVO> = DataResult(result, dtoType: CanvasStrokeDTO.self) { $0.toVO() }
            await send(mapped)
        }
    }

    public func updateRemoteSnapshot(_ snapshot: CanvasSnapshotVO) -> Effect<DataResult<CanvasSnapshotVO>> {
        guard ConfigManager.shared.hasValidAPIBaseURL else { return failure(ConfigManager.missingAPIBaseURLMessage) }
        let localProvider = provider
        return Effect.run { send in
            let result = await localProvider.request(.updateSnapshot(sharedSpaceId: snapshot.sharedSpaceId, snapshot: snapshot))
            let mapped: DataResult<CanvasSnapshotVO> = DataResult(result, dtoType: CanvasSnapshotDTO.self) { $0.toVO() }
            await send(mapped)
        }
    }

    private func valid(_ sharedSpaceId: String) -> String? {
        let value = sharedSpaceId.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private func failure<T>(_ message: String) -> Effect<DataResult<T>> {
        Effect.run { send in await send(DataResult(message: message)) }
    }
}

private enum CanvasRepoKey: DependencyKey {
    static var liveValue: CanvasRepository = CanvasRepositoryImpl()
}

public extension DependencyValues {
    var canvasRepository: CanvasRepository {
        get { self[CanvasRepoKey.self] }
        set { self[CanvasRepoKey.self] = newValue }
    }
}
