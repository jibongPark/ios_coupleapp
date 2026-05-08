import Foundation
import ComposableArchitecture
import CanvasDomain
import Core

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
            snapshot.snapshots.removeAll { $0.sharedSpaceId == snapshotVO.sharedSpaceId && $0.canvasId == snapshotVO.canvasId }
            snapshot.snapshots.append(CanvasSnapshotDTO(snapshotVO))
            if let index = snapshot.canvases.firstIndex(where: { $0.sharedSpaceId == snapshotVO.sharedSpaceId }) {
                snapshot.canvases[index].latestSnapshotVersion = snapshotVO.version
                snapshot.canvases[index].latestSnapshotUrl = snapshotVO.imageUrl
                snapshot.canvases[index].localSnapshotPath = snapshotVO.localPath
            }
            try? store.write(snapshot)
            await send(DataResult(isSuccess: true, data: snapshotVO))
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
