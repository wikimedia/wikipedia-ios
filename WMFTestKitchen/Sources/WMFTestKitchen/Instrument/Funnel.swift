import Foundation

public class Funnel {
    public let name: String?
    public let token: String
    public private(set) var sequence: Int = 1
    private var startTime: Date
    private var pauseTime: Date?

    public init(name: String? = nil) {
        self.name = name
        self.token = SessionController.generateSessionId()
        self.startTime = Date()
    }

    public func touch() {
        sequence += 1
    }

    public var duration: Int {
        return Int(Date().timeIntervalSince(startTime) * 1000)
    }

    public func pause() {
        pauseTime = Date()
    }

    public func resume() {
        if let pauseTime {
            startTime = startTime.addingTimeInterval(Date().timeIntervalSince(pauseTime))
        }
        pauseTime = nil
    }

    public func reset() {
        startTime = Date()
    }

    public func addActionContext(_ actionContext: inout [String: String]) {
        actionContext["time_spent_ms"] = String(duration)
    }
}
