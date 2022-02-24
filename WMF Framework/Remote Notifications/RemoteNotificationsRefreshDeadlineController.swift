import Foundation

final class RemoteNotificationsRefreshDeadlineController {
    private let deadline: TimeInterval = 30 // 30 seconds
    private var now: CFAbsoluteTime {
        return CFAbsoluteTimeGetCurrent()
    }

    public var shouldRefresh: Bool {
        
        guard let lastRefreshTime = lastRefreshTime else {
            return true
        }
        
        return now - lastRefreshTime > deadline
    }

    private var lastRefreshTime: CFAbsoluteTime?

    public func reset() {
        lastRefreshTime = now
    }
}
