import Foundation

public class SessionController {
    private let lock = NSLock()
    private var _sessionId: String
    private var sessionTouched: Date

    private static let sessionLength: TimeInterval = 30 * 60 // 30 minutes

    public init() {
        self._sessionId = SessionController.generateSessionId()
        self.sessionTouched = Date()
    }

    public var sessionId: String {
        lock.lock()
        defer { lock.unlock() }
        return _sessionId
    }

    public func touchSession() {
        lock.lock()
        defer { lock.unlock() }
        if sessionExpired() {
            _sessionId = SessionController.generateSessionId()
        }
        sessionTouched = Date()
    }

    public func beginSession() {
        lock.lock()
        defer { lock.unlock() }
        _sessionId = SessionController.generateSessionId()
        sessionTouched = Date()
    }

    public func closeSession() {
        lock.lock()
        defer { lock.unlock() }
        sessionTouched = Date()
    }

    public func sessionExpired() -> Bool {
        return Date().timeIntervalSince(sessionTouched) >= SessionController.sessionLength
    }

    /// Generates a 20-character hex string representing a uniformly random 80-bit integer
    public static func generateSessionId() -> String {
        let a = UInt32.random(in: 0...UInt32.max)
        let b = UInt32.random(in: 0...UInt32.max)
        let c = UInt16.random(in: 0...UInt16.max)
        return String(format: "%08x%08x%04x", a, b, c)
    }
}
