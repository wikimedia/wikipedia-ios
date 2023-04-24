import Foundation

/// *User Session*  - handles user session ID creation
/// Session ID format and duration follow the standars agreed upon the Analytics and Apps teams
/// Note: Not to be confused with *Session * class that handles URL sessions
public final class UserSession: NSObject {
    
    @objc public static let shared: UserSession = {
        return UserSession()
    }()
    
    // MARK: Internal

    /**
     * Return a session identifier
     * - Returns: session ID
     *
     * The identifier is a string of 20 zero-padded hexadecimal digits
     * representing a uniformly random 80-bit integer.
     */
    var sessionID: String {
        var _sessionID = UserDefaults.standard.wmf_sessionID
        guard let sID = _sessionID else {
            let newID = generateID()
            _sessionID = newID
            UserDefaults.standard.wmf_sessionID = _sessionID
            UserDefaults.standard.wmf_sessionStartTimestamp = Date()
            return newID
        }
        return sID
    }
    
    var sessionStartDate: Date? {
        return UserDefaults.standard.wmf_sessionStartTimestamp
    }
    
    func generateSessionID() {
        _ = self.sessionID
    }

    /**
     * Reset the session ID
     */
    func resetAll() {
        UserDefaults.standard.wmf_sessionID = nil
        UserDefaults.standard.wmf_sessionStartTimestamp = nil
        UserDefaults.standard.wmf_sessionBackgroundTimestamp = nil
    }

    /**
     * If it has been more than 30 minutes since the app entered background state,
     * a new session is started.
     */
    func needsReset() -> Bool {
        return self.hasSessionTimedOut()
    }
    
    func resetBackgroundTimestamp() {
        UserDefaults.standard.wmf_sessionBackgroundTimestamp = nil
    }

    /**
     * This method should be called upon app background
     *
     * We now persist session ID on app close to match session handling with Android
     * session ends when 30 minutes of inactivity have passed.
     */
    func appDidBackground() {
        UserDefaults.standard.wmf_sessionBackgroundTimestamp = Date()
    }
    
    
    // MARK: Private
    
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
     * Check if session expired, based on last active timestamp
     *
     * A new session ID is required if it has been more than 30 minutes since the
     * user was last active (e.g. when app entered background).
     */
    private func hasSessionTimedOut() -> Bool {
        guard let lastTimestamp = UserDefaults.standard.wmf_sessionBackgroundTimestamp else {
            return false
        }
        
        return lastTimestamp.timeIntervalSinceNow < -1800
    }
}
