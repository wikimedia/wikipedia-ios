
struct WMFKeychainCredentials {
    
    // Based on:
    // https://developer.apple.com/library/content/samplecode/GenericKeychain/Introduction/Intro.html
    // Note from the example:
    //    "The KeychainPasswordItem struct provides a high-level interface to the Keychain Services API
    //    calls required to interface with the iOS keychain. The passwords for keychain item are not
    //    stored as properties of the struct, instead they are only ever read from the keychain on demand."
    // Per the note userName and password are implemented as computed properties.
    
    fileprivate let userNameKey = "org.wikimedia.wikipedia.username"
    fileprivate let passwordKey = "org.wikimedia.wikipedia.password"
    fileprivate let hostKey = "org.wikimedia.wikipedia.host"
    private let appInstallIDKey = "org.wikimedia.wikipedia.appinstallid"
    private let sessionIDKey = "org.wikimedia.wikipedia.sessionid"
    
    public var userName: String? {
        get {
            return try? getValue(forKey: userNameKey)
        }
        set(newUserName) {
            trySet(newUserName, forKey: userNameKey)
        }
    }
    
    public var password: String? {
        get {
            return try? getValue(forKey: passwordKey)
        }
        set(newPassword) {
            trySet(newPassword, forKey: passwordKey)
        }
    }
    
    public var host: String? {
        get {
            return try? getValue(forKey: hostKey)
        }
        set {
            trySet(newValue, forKey: hostKey)
        }
    }
    
    public var appInstallID: String? {
        get {
            guard let appInstallID = try? getValue(forKey: appInstallIDKey) else {
                setNewUUID(forKey: appInstallIDKey)
                return try? getValue(forKey: appInstallIDKey)
            }
            return appInstallID
        }
        set {
            trySet(newValue, forKey: appInstallIDKey)
        }
    }
    
    public var sessionID: String? {
        get {
            guard let sessionID = try? getValue(forKey: sessionIDKey) else {
                setNewUUID(forKey: sessionIDKey)
                return try? getValue(forKey: sessionIDKey)
            }
            return sessionID
        }
        set {
            trySet(newValue, forKey: sessionIDKey)
        }
    }
    
    public func resetSessionID() {
        setNewUUID(forKey: sessionIDKey)
    }
    
    private func setNewUUID(forKey key: String) {
        trySet(UUID().uuidString, forKey: key)
    }
    
    private func trySet(_ newValue: String?, forKey key: String) {
        do {
            return try set(value: newValue, forKey: key)
        } catch  {
            assertionFailure("\(error)")
        }
    }
    
    fileprivate enum WMFKeychainCredentialsError: Error {
        case noValue
        case unexpectedData
        case couldNotDeleteData
        case unhandledError(status: OSStatus)
    }
    
    fileprivate func commonConfigurationDictionary(forKey key:String) -> [String : AnyObject] {
        return [
            kSecClass as String : kSecClassGenericPassword,
            kSecAttrService as String : Bundle.main.bundleIdentifier as AnyObject,
            kSecAttrGeneric as String : key as AnyObject,
            kSecAttrAccount as String : key as AnyObject
        ]
    }
    
    fileprivate func getValue(forKey key:String) throws -> String {
        var query = commonConfigurationDictionary(forKey: key)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = kCFBooleanTrue
        
        var result: AnyObject?
        let status = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        
        guard status != errSecItemNotFound else { throw WMFKeychainCredentialsError.noValue }
        guard status == noErr else { throw WMFKeychainCredentialsError.unhandledError(status: status) }
        guard
            let data = result as? Data,
            let value = String(data: data, encoding: String.Encoding.utf8)
            else {
                throw WMFKeychainCredentialsError.unexpectedData
        }
        return value
    }
    
    fileprivate func deleteValue(forKey key:String) throws {
        let query = commonConfigurationDictionary(forKey: key)
        let status = SecItemDelete(query as CFDictionary)
        guard status == noErr || status == errSecItemNotFound else { throw WMFKeychainCredentialsError.unhandledError(status: status) }
    }
    
    fileprivate func set(value:String?, forKey key:String) throws {
        // nil value causes the key/value pair to be removed from the keychain
        guard let value = value else {
            do {
                try deleteValue(forKey: key)
            } catch  {
                throw WMFKeychainCredentialsError.couldNotDeleteData
            }
            return
        }
        
        var query = commonConfigurationDictionary(forKey: key)
        let valueData = value.data(using: String.Encoding.utf8)!
        query[kSecValueData as String] = valueData as AnyObject?
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status != errSecSuccess else {
            return
        }
        
        if (status == errSecDuplicateItem) {
            do {
                return try update(value: value, forKey: key)
            } catch  {
                throw WMFKeychainCredentialsError.unhandledError(status: status)
            }
        } else {
            throw WMFKeychainCredentialsError.unhandledError(status: status)
        }
    }
    
    fileprivate func update(value:String, forKey key:String) throws {
        let query = commonConfigurationDictionary(forKey: key)
        var dataDict = [String : AnyObject]()
        let valueData = value.data(using: String.Encoding.utf8)!
        dataDict[kSecValueData as String] = valueData as AnyObject?
        let status = SecItemUpdate(query as CFDictionary, dataDict as CFDictionary)
        if (status != errSecSuccess) {
            throw WMFKeychainCredentialsError.unhandledError(status: status)
        }
    }
}
