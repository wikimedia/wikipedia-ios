import CocoaLumberjackSwift

public class KeychainCredentialsManager: NSObject {
    private var keychainCredentials = WMFKeychainCredentials()
    @objc public static let shared = KeychainCredentialsManager()
    
    public var username: String? {
        get {
            DDLogError("Notifications_Auth_Debug - username get - KeychainCredentialsManager")
            return keychainCredentials.userName
        } set {
            DDLogError("Notifications_Auth_Debug - username set - KeychainCredentialsManager")
            keychainCredentials.userName = newValue
        }
    }
    
    public var password: String? {
        get {
            DDLogError("Notifications_Auth_Debug - password get - KeychainCredentialsManager")
            return keychainCredentials.password
        } set {
            DDLogError("Notifications_Auth_Debug - password set - KeychainCredentialsManager")
            keychainCredentials.password = newValue
        }
    }
}
