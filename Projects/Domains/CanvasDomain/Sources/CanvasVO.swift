import Foundation

public struct SharedCanvasVO: Equatable, Sendable, Codable {
    public let id: String
    public let sharedSpaceId: String
    public let title: String?
    public let latestSnapshotVersion: Int
    public let latestSnapshotUrl: String?
    public let localSnapshotPath: String?

    public init(id: String, sharedSpaceId: String, title: String? = nil, latestSnapshotVersion: Int = 0, latestSnapshotUrl: String? = nil, localSnapshotPath: String? = nil) {
        self.id = id
        self.sharedSpaceId = sharedSpaceId
        self.title = title
        self.latestSnapshotVersion = latestSnapshotVersion
        self.latestSnapshotUrl = latestSnapshotUrl
        self.localSnapshotPath = localSnapshotPath
    }
}

public struct CanvasStrokeVO: Equatable, Sendable, Identifiable, Codable {
    public let id: String
    public let canvasId: String
    public let sharedSpaceId: String
    public let authorId: String
    public let sequence: Int
    public let tool: CanvasTool
    public let colorHex: String
    public let lineWidth: Double
    public let points: [CanvasPointVO]

    public init(id: String, canvasId: String, sharedSpaceId: String, authorId: String, sequence: Int, tool: CanvasTool, colorHex: String, lineWidth: Double, points: [CanvasPointVO]) {
        self.id = id
        self.canvasId = canvasId
        self.sharedSpaceId = sharedSpaceId
        self.authorId = authorId
        self.sequence = sequence
        self.tool = tool
        self.colorHex = colorHex
        self.lineWidth = lineWidth
        self.points = points.map { $0.normalized() }
    }
}

public enum CanvasTool: String, Equatable, Sendable, Codable {
    case pen
    case eraser
}

public struct CanvasPointVO: Equatable, Sendable, Codable {
    public let x: Double
    public let y: Double
    public let t: Double?
    public let pressure: Double?

    public init(x: Double, y: Double, t: Double? = nil, pressure: Double? = nil) {
        self.x = min(max(x, 0), 1)
        self.y = min(max(y, 0), 1)
        self.t = t
        self.pressure = pressure.map { min(max($0, 0), 1) }
    }

    public func normalized() -> CanvasPointVO {
        CanvasPointVO(x: x, y: y, t: t, pressure: pressure)
    }
}

public struct CanvasSnapshotVO: Equatable, Sendable, Codable {
    public let id: String
    public let canvasId: String
    public let sharedSpaceId: String
    public let version: Int
    public let imageUrl: String?
    public let localPath: String?
    public let width: Int
    public let height: Int

    public init(id: String, canvasId: String, sharedSpaceId: String, version: Int, imageUrl: String? = nil, localPath: String? = nil, width: Int, height: Int) {
        self.id = id
        self.canvasId = canvasId
        self.sharedSpaceId = sharedSpaceId
        self.version = version
        self.imageUrl = imageUrl
        self.localPath = localPath
        self.width = width
        self.height = height
    }
}
