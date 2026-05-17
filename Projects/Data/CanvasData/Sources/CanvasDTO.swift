import Foundation
import CanvasDomain

public struct CanvasStoreSnapshot: Codable, Equatable {
    public var canvases: [SharedCanvasDTO]
    public var strokes: [CanvasStrokeDTO]
    public var snapshots: [CanvasSnapshotDTO]
    public var lastSyncedSequenceBySharedSpaceId: [String: Int]

    public init(canvases: [SharedCanvasDTO] = [], strokes: [CanvasStrokeDTO] = [], snapshots: [CanvasSnapshotDTO] = [], lastSyncedSequenceBySharedSpaceId: [String: Int] = [:]) {
        self.canvases = canvases
        self.strokes = strokes
        self.snapshots = snapshots
        self.lastSyncedSequenceBySharedSpaceId = lastSyncedSequenceBySharedSpaceId
    }
}

public struct SharedCanvasDTO: Codable, Equatable {
    public var id: String
    public var sharedSpaceId: String
    public var title: String?
    public var latestSnapshotVersion: Int
    public var latestSnapshotUrl: String?
    public var localSnapshotPath: String?

    public func toVO() -> SharedCanvasVO {
        SharedCanvasVO(id: id, sharedSpaceId: sharedSpaceId, title: title, latestSnapshotVersion: latestSnapshotVersion, latestSnapshotUrl: latestSnapshotUrl, localSnapshotPath: localSnapshotPath)
    }
}

public struct CanvasStrokeDTO: Codable, Equatable {
    public var id: String
    public var canvasId: String
    public var sharedSpaceId: String
    public var authorId: String
    public var sequence: Int
    public var tool: String
    public var colorHex: String
    public var lineWidth: Double
    public var points: [CanvasPointDTO]
    public var pendingSync: Bool

    public init(_ vo: CanvasStrokeVO, pendingSync: Bool = true) {
        self.id = vo.id
        self.canvasId = vo.canvasId
        self.sharedSpaceId = vo.sharedSpaceId
        self.authorId = vo.authorId
        self.sequence = vo.sequence
        self.tool = vo.tool.rawValue
        self.colorHex = vo.colorHex
        self.lineWidth = vo.lineWidth
        self.points = vo.points.map(CanvasPointDTO.init)
        self.pendingSync = pendingSync
    }

    public func toVO() -> CanvasStrokeVO {
        CanvasStrokeVO(id: id, canvasId: canvasId, sharedSpaceId: sharedSpaceId, authorId: authorId, sequence: sequence, tool: CanvasTool(rawValue: tool) ?? .pen, colorHex: colorHex, lineWidth: lineWidth, points: points.map { $0.toVO() })
    }
}

public struct CanvasPointDTO: Codable, Equatable {
    public var x: Double
    public var y: Double
    public var t: Double?
    public var pressure: Double?

    public init(_ vo: CanvasPointVO) {
        self.x = vo.x
        self.y = vo.y
        self.t = vo.t
        self.pressure = vo.pressure
    }

    public func toVO() -> CanvasPointVO { CanvasPointVO(x: x, y: y, t: t, pressure: pressure) }
}

public struct CanvasSnapshotDTO: Codable, Equatable {
    public var id: String
    public var canvasId: String
    public var sharedSpaceId: String
    public var version: Int
    public var imageUrl: String?
    public var localPath: String?
    public var width: Int
    public var height: Int

    public init(_ vo: CanvasSnapshotVO) {
        self.id = vo.id
        self.canvasId = vo.canvasId
        self.sharedSpaceId = vo.sharedSpaceId
        self.version = vo.version
        self.imageUrl = vo.imageUrl
        self.localPath = vo.localPath
        self.width = vo.width
        self.height = vo.height
    }

    public func toVO() -> CanvasSnapshotVO {
        CanvasSnapshotVO(id: id, canvasId: canvasId, sharedSpaceId: sharedSpaceId, version: version, imageUrl: imageUrl, localPath: localPath, width: width, height: height)
    }
}
