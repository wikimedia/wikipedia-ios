import Foundation

public class Funnel {
    public let name: String?
    public let token: String
    public private(set) var sequence: Int = 1
    private var startTime: Date
    private var pauseTime: Date?

    public init(name: String? = nil) {
        self.name = name
        self.token = Funnel.generateTokenId()
        self.startTime = Date()
    }

    /// Generates a 20-character hex string representing a uniformly random 80-bit integer
    static func generateTokenId() -> String {
        let a = UInt32.random(in: 0...UInt32.max)
        let b = UInt32.random(in: 0...UInt32.max)
        let c = UInt16.random(in: 0...UInt16.max)
        return String(format: "%08x%08x%04x", a, b, c)
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
