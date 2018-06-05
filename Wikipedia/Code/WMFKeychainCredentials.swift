
struct WMFKeychainCredentials {
    fileprivate let semaphore = DispatchSemaphore(value: 1)

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
            guard let appInstallID = tryGetString(forKey: appInstallIDKey), appInstallID != "" else {
                if let previousID = UserDefaults.wmf_userDefaults().string(forKey: "WMFAppInstallID"), previousID != "" {
                    trySet(previousID, forKey: appInstallIDKey)
                    return previousID
                }
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
            guard let sessionID = tryGetString(forKey: sessionIDKey), sessionID != "" else {
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
            guard let value = tryGetValue(forKey: lastLoggedUserHistorySnapshotKey) else {
                return nil
            }
            return value as? Dictionary<String, Any>
        }
        set {
            trySet(newValue, forKey: lastLoggedUserHistorySnapshotKey)
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
    
    // MARK: Getting values from keychain
    
    private func tryGetString(forKey key: String) -> String? {
        return try? string(forKey: key)
    }
    
    private func tryGetValue(forKey key: String) -> Any? {
        return try? value(forKey: key)
    }
    
    private func string(forKey key: String) throws -> String {
        let dataForKey = try data(forKey: key)
        guard let string = String(data: dataForKey, encoding: String.Encoding.utf8) else {
            throw WMFKeychainCredentialsError.unexpectedData
        }
        return string
    }
    
    fileprivate func value(forKey key: String) throws -> Any {
        let dataForKey = try data(forKey: key)
        guard let value = NSKeyedUnarchiver.unarchiveObject(with: dataForKey) else {
            throw WMFKeychainCredentialsError.unexpectedData
        }
        return value
    }
    
    fileprivate func data(forKey key: String) throws -> Data {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        let queryDictionary = matchQuery(forKey: key) as CFDictionary
        
        var result: AnyObject?
        let status = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(queryDictionary, UnsafeMutablePointer($0))
        }
        
        guard status != errSecItemNotFound else { throw WMFKeychainCredentialsError.noValue }
        guard status == noErr else { throw WMFKeychainCredentialsError.unhandledError(status: status) }
        guard
            let data = result as? Data
            else {
                throw WMFKeychainCredentialsError.unexpectedData
        }
        return data
    }
    
    // MARK: Saving values to keychain
    
    private func trySet(_ newValue: Any?, forKey key: String) {
        do {
            return try set(value: newValue, forKey: key)
        } catch  {
            DDLogError("Error setting keychain value for \(key): \(error)") // don't log the value
            assertionFailure("\(error)")
        }
    }
    
    private func setNewUUID(forKey key: String) {
        trySet(UUID().uuidString, forKey: key)
    }
    
    fileprivate func set(value: Any?, forKey key: String) throws {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        // nil value causes the key/value pair to be removed from the keychain
        guard let value = value else {
            let query = commonConfigurationDictionary(forKey: key)
            let status = SecItemDelete(query as CFDictionary)
            guard status == noErr || status == errSecItemNotFound else {
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
    
    // MARK: Saving values in keychain
    
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
    
    // MARK: Helper functions to interact with keychain values
    
    private func data(for value: Any) -> Data? {
        if let value = value as? String {
            return value.data(using: String.Encoding.utf8)
        } else {
            return NSKeyedArchiver.archivedData(withRootObject: value)
        }
    }
    
    private func matchQuery(forKey key: String) -> Dictionary<String, AnyObject> {
        var query = commonConfigurationDictionary(forKey: key)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = kCFBooleanTrue
        return query
    }
}
