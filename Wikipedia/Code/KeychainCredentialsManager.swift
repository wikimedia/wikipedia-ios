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
}
