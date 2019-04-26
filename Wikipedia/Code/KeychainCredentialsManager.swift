public class KeychainCredentialsManager: NSObject {
    private var keychainCredentials = WMFKeychainCredentials()
    @objc public static let shared = KeychainCredentialsManager()
    
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
}
