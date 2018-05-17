
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
    private let lastLoggedUserHistorySnapshotKey = "org.wikimedia.wikipedia.lastloggeduserhistorysnapshot"
    
    public var userName: String? {
        get {
            return tryGetString(forKey: userNameKey)
        }
        set(newUserName) {
            trySet(newUserName, forKey: userNameKey)
        }
    }
    
    public var password: String? {
        get {
            return tryGetString(forKey: passwordKey)
        }
        set(newPassword) {
            trySet(newPassword, forKey: passwordKey)
        }
    }
    
    public var host: String? {
        get {
            return tryGetString(forKey: hostKey)
        }
        set {
            trySet(newValue, forKey: hostKey)
        }
    }
    
    public var appInstallID: String? {
        get {
            guard let appInstallID = tryGetString(forKey: appInstallIDKey) else {
                setNewUUID(forKey: appInstallIDKey)
                return tryGetString(forKey: appInstallIDKey)
            }
            return appInstallID
        }
        set {
            trySet(newValue, forKey: appInstallIDKey)
        }
    }
    
    public var sessionID: String? {
        get {
            guard let sessionID = tryGetString(forKey: sessionIDKey) else {
                setNewUUID(forKey: sessionIDKey)
                return tryGetString(forKey: sessionIDKey)
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
    
    public var lastLoggedUserHistorySnapshot: Dictionary<String, Any>? {
        get {
            guard let value = try? value(forKey: lastLoggedUserHistorySnapshotKey) else {
                return nil
            }
            return value as? Dictionary<String, Any>
        }
        set {
            trySet(newValue, forKey: lastLoggedUserHistorySnapshotKey)
        }
    }
    
    private func tryGetString(forKey key: String) -> String? {
        do {
            return try string(forKey: key)
        } catch let error {
            assertionFailure("\(error)")
        }
        return nil
    }
    
    private func string(forKey key: String) throws -> String? {
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
    
    private func setNewUUID(forKey key: String) {
        trySet(UUID().uuidString, forKey: key)
    }
    
    private func trySet(_ newValue: Any?, forKey key: String) {
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
    
    fileprivate func value(forKey key: String) throws -> Any {
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
            let value = NSKeyedUnarchiver.unarchiveObject(with: data)
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
    
    fileprivate func set(value: Any?, forKey key: String) throws {
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
        let valueData = data(for: value)
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
    
    fileprivate func update(value: Any, forKey key: String) throws {
        let query = commonConfigurationDictionary(forKey: key)
        var dataDict = [String : AnyObject]()
        let valueData = data(for: value)
        dataDict[kSecValueData as String] = valueData as AnyObject?
        let status = SecItemUpdate(query as CFDictionary, dataDict as CFDictionary)
        if (status != errSecSuccess) {
            throw WMFKeychainCredentialsError.unhandledError(status: status)
        }
    }
    
    private func data(for value: Any) -> Data? {
        if let value = value as? String {
            return value.data(using: String.Encoding.utf8)
        } else {
            return NSKeyedArchiver.archivedData(withRootObject: value)
        }
    }
}
