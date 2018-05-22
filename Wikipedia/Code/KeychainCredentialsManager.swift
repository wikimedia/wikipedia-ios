public class KeychainCredentialsManager: NSObject {
    private var keychainCredentials = WMFKeychainCredentials()
    @objc public static let shared = KeychainCredentialsManager()
    
    @objc public var appInstallID: String? {
        return keychainCredentials.appInstallID
    }
    
    @objc func resetAppInstallID() {
        keychainCredentials.appInstallID = nil
    }
    
    @objc public var sessionID: String? {
        return keychainCredentials.sessionID
    }
    
    @objc public func resetSessionID() {
        keychainCredentials.resetSessionID()
    }
    
    public var host: String? {
        get {
            return keychainCredentials.host
        } set {
            keychainCredentials.host = newValue
        }
    }
    
    public var username: String? {
        get {
            return keychainCredentials.userName
        } set {
            keychainCredentials.userName = newValue
        }
    }
    
    public var password: String? {
        get {
            return keychainCredentials.password
        } set {
            keychainCredentials.password = newValue
        }
    }
    
    public var lastLoggedUserHistorySnapshot: Dictionary<String, Any>? {
        get {
            return keychainCredentials.lastLoggedUserHistorySnapshot
        }
        set {
            keychainCredentials.lastLoggedUserHistorySnapshot = newValue
        }
    }
}
