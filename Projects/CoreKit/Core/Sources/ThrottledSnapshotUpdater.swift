import Foundation

public struct ThrottledSnapshotUpdater: Equatable, Sendable {
    public let minimumInterval: TimeInterval
    private var lastUpdateDate: Date?

    public init(minimumInterval: TimeInterval = 2.0, lastUpdateDate: Date? = nil) {
        self.minimumInterval = minimumInterval
        self.lastUpdateDate = lastUpdateDate
    }

    public mutating func shouldUpdate(now: Date = Date()) -> Bool {
        guard let lastUpdateDate else {
            self.lastUpdateDate = now
            return true
        }
        guard now.timeIntervalSince(lastUpdateDate) >= minimumInterval else { return false }
        self.lastUpdateDate = now
        return true
    }
}
