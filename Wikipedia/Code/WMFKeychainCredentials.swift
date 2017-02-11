
struct WMFKeychainCredentials {
    
    // Based on:
    // https://developer.apple.com/library/content/samplecode/GenericKeychain/Introduction/Intro.html
    
    public func userName() -> String? {
        do {
            return try getValue(forEntry: "org.wikimedia.wikipedia.username")
        } catch  {
            return nil
        }
    }

    public func set(userName: String?) {
        do {
            return try set(value: userName, forEntry: "org.wikimedia.wikipedia.username")
        } catch  {}
    }
    
    public func password() -> String? {
        do {
            return try getValue(forEntry: "org.wikimedia.wikipedia.password")
        } catch  {
            return nil
        }
    }

    public func set(password: String?) {
        do {
            return try set(value: password, forEntry: "org.wikimedia.wikipedia.password")
        } catch  {}
    }

    private enum WMFKeychainCredentialsError: Error {
        case noValue
        case unexpectedData
        case couldNotDeleteData
        case unhandledError(status: OSStatus)
    }

    private func commonConfigurationDictionary(forEntry entry:String) -> [String : AnyObject] {
        var query = [String : AnyObject]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = Bundle.main.bundleIdentifier as AnyObject?
        query[kSecAttrGeneric as String] = entry as AnyObject?
        query[kSecAttrAccount as String] = entry as AnyObject?
        return query
    }

    private func getValue(forEntry entry:String) throws -> String {
        var query = commonConfigurationDictionary(forEntry: entry)
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
    
    private func deleteValue(forEntry entry:String) throws {
        let query = commonConfigurationDictionary(forEntry: entry)
        let status = SecItemDelete(query as CFDictionary)
        guard status == noErr || status == errSecItemNotFound else { throw WMFKeychainCredentialsError.unhandledError(status: status) }
    }
    
    private func set(value:String?, forEntry entry:String) throws {
        // nil value causes the entry to be removed from the keychain
        guard let value = value else {
            do {
                try deleteValue(forEntry: entry)
            } catch  {
                throw WMFKeychainCredentialsError.couldNotDeleteData
            }
            return
        }
        
        var query = commonConfigurationDictionary(forEntry: entry)
        let valueData = value.data(using: String.Encoding.utf8)!
        query[kSecValueData as String] = valueData as AnyObject?
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status != errSecSuccess else {
            return
        }
        
        if (status == errSecDuplicateItem) {
            do {
                return try update(value: value, forEntry: entry)
            } catch  {
                throw WMFKeychainCredentialsError.unhandledError(status: status)
            }
        } else {
            throw WMFKeychainCredentialsError.unhandledError(status: status)
        }
    }
    
    private func update(value:String, forEntry entry:String) throws {
        let query = commonConfigurationDictionary(forEntry: entry)
        var dataDict = [String : AnyObject]()
        let valueData = value.data(using: String.Encoding.utf8)!
        dataDict[kSecValueData as String] = valueData as AnyObject?
        let status = SecItemUpdate(query as CFDictionary, dataDict as CFDictionary)
        if (status != errSecSuccess) {
            throw WMFKeychainCredentialsError.unhandledError(status: status)
        }
    }
}
