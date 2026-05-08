import Foundation

public enum CanvasSnapshotFileStore {
    public static let appGroupIdentifier = "group.com.bongbong.coupleapp"
    public static let latestFileName = "LiveCanvas/latest_canvas.png"

    public static func appGroupSnapshotURL(fileName: String = latestFileName) -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?
            .appendingPathComponent(fileName)
    }

    @discardableResult
    public static func copyLatestSnapshot(from sourceURL: URL, fileName: String = latestFileName) throws -> URL? {
        guard let destination = appGroupSnapshotURL(fileName: fileName) else { return nil }
        try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: sourceURL, to: destination)
        return destination
    }
}
