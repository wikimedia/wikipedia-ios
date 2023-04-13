import Foundation

/// Write doc for this TODO
final class UserSession {
    
    public static let shared: UserSession = {
        return UserSession()
    }()

    private let queue = DispatchQueue(label: "UserSessionClient-" + UUID().uuidString)

    /**
     * Return a session identifier
     * - Returns: session ID
     *
     * The identifier is a string of 20 zero-padded hexadecimal digits
     * representing a uniformly random 80-bit integer.
     */
    internal var sessionID: String {
        queue.sync {
            var _sessionID = UserDefaults.standard.wmf_sessionID
            guard let sID = _sessionID else {
                let newID = generateID()
                _sessionID = newID
                return newID
            }
            return sID
        }
    }
    /**
     * Generates a new identifier using the same algorithm as EPC libraries for
     * web and Android
     */
    private func generateID() -> String {
        var id: String = ""
        for _ in 1...5 {
            id += String(format: "%04x", arc4random_uniform(65535))
        }
        return id
    }

    /**
     * Called when user toggles logging permissions in Settings
     *
     * This assumes storageManager's deviceID will be reset separately by a
     * different owner (EventLoggingService's `reset()` method)
     */
    public func reset() {
        resetSession()
    }

    public var sessionStartDate: Date? {
        queue.sync {
            guard let sessionStart = _sessionStartDate else {
                let newStart = Date()
                _sessionStartDate = newStart
                return newStart
            }
            return sessionStart
        }
    }

    private var _sessionStartDate: Date?

    private var _sessionEndDate: Date?

    /**
     * Unset the session
     */
    public func resetSession() {
        queue.async {
            UserDefaults.standard.wmf_sessionID = nil
        }
        
    }

    /**
     * Check if session expired, based on last active timestamp
     *
     * A new session ID is required if it has been more than 30 minutes since the
     * user was last active (e.g. when app entered background).
     */
    public func sessionTimedOut() -> Bool {
        /*
         * A TimeInterval value is always specified in seconds.
         */
        if let lastTimestamp = UserDefaults.standard.wmf_sessionLastTimestamp {
            hasSessionTimedOut = lastTimestamp.timeIntervalSinceNow < -1800
            return hasSessionTimedOut
        }
        return true
    }

    public var hasSessionTimedOut: Bool = false

}
