import CocoaLumberjackSwift

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
    
    public var userName: String? {
        get {
            do {
                DDLogError("Notifications_Auth_Debug - begin try get userName on WMFKeychainCredentials")
                return try getValue(forKey: userNameKey)
            } catch let error {
                DDLogError("Notifications_Auth_Debug - failure try get userName on WMFKeychainCredentials: \(error)")
                return nil
            }
        }
        set(newUserName) {
            do {
                DDLogError("Notifications_Auth_Debug - begin try set userName on WMFKeychainCredentials, usernameKey: \(userNameKey)")
                return try set(value: newUserName, forKey: userNameKey)
            } catch let error {
                DDLogError("Notifications_Auth_Debug - error setting userName on WMFKeychainCredentials: \(error)")
                assertionFailure("\(error)")
            }
        }
    }

    public var password: String? {
        get {
            do {
                DDLogError("Notifications_Auth_Debug - begin try get password on WMFKeychainCredentials")
                return try getValue(forKey: passwordKey)
            } catch let error {
                DDLogError("Notifications_Auth_Debug - failure try get password on WMFKeychainCredentials: \(error)")
                return nil
            }
        }
        set(newPassword) {
            do {
                DDLogError("Notifications_Auth_Debug - begin try set password on WMFKeychainCredentials, passwordKey: \(passwordKey)")
                return try set(value: newPassword, forKey: passwordKey)
            } catch {
                DDLogError("Notifications_Auth_Debug - error setting password on WMFKeychainCredentials: \(error)")
                assertionFailure("\(error)")
            }
        }
    }
    
    public var host: String? {
        get {
            do {
                return try getValue(forKey: hostKey)
            } catch {
                return nil
            }
        }
        set {
            do {
                return try set(value: newValue, forKey: hostKey)
            } catch {
                assertionFailure("\(error)")
            }
        }
    }

    fileprivate enum WMFKeychainCredentialsError: Error {
        case noValue
        case unexpectedData
        case couldNotDeleteData
        case unhandledError(status: OSStatus)
        
        var localizedDescription: String {
            switch self {
            case .noValue:
                return "WMFKeychainCredentialsError.noValue"
            case .unexpectedData:
                return "WMFKeychainCredentialsError.unexpectedData"
            case .couldNotDeleteData:
                return "WMFKeychainCredentialsError.couldNotDeleteData"
            case .unhandledError(let status):
                return "WMFKeychainCredentialsError.unhandledError: \(status)"
            }
        }
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
        DDLogError("Notifications_Auth_Debug - getValue enter on WMFKeychainCredentials")
        var query = commonConfigurationDictionary(forKey: key)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        var result: AnyObject?
        let status = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        
        guard status != errSecItemNotFound else { throw WMFKeychainCredentialsError.noValue }
        guard status == noErr else { throw WMFKeychainCredentialsError.unhandledError(status: status) }
        guard
            let dictionary = result as? [String: Any],
            let data = dictionary[kSecValueData as String] as? Data,
            let value = String(data: data, encoding: String.Encoding.utf8)
        else {
            throw WMFKeychainCredentialsError.unexpectedData
        }
        
        // update accessibility of value from kSecAttrAccessibleWhenUnlocked to kSecAttrAccessibleAfterFirstUnlock
        if let attrAccessible = dictionary[kSecAttrAccessible as String] as? String, attrAccessible == (kSecAttrAccessibleWhenUnlocked as String) {
            DDLogError("Notifications_Auth_Debug - getValue, entered attrAccessible conditional WMFKeychainCredentials")
            do {
                try update(value: value, forKey: key)
            } catch let error {
                DDLogError("Notifications_Auth_Debug - getValue, entered attrAccessible conditional WMFKeychainCredentials, failure updating value: \(error)")
            }
        }
        
        DDLogError("Notifications_Auth_Debug - returning value. isEmpty: \(value.isEmpty). in WMFKeychainCredentials")
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
                DDLogError("Notifications_Auth_Debug - set(value), nil, attempting to delete value in WMFKeychainCredentials")
                try deleteValue(forKey: key)
            } catch {
                DDLogError("Notifications_Auth_Debug - set(value), failure deleting value in WMFKeychainCredentials")
                throw WMFKeychainCredentialsError.couldNotDeleteData
            }
            return
        }
        
        var query = commonConfigurationDictionary(forKey: key)
        let valueData = value.data(using: String.Encoding.utf8)
        query[kSecValueData as String] = valueData as AnyObject?
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status != errSecSuccess else {
            DDLogError("Notifications_Auth_Debug - set(value), status == errSecSuccess, returning. in WMFKeychainCredentials")
            return
        }
        
        if status == errSecDuplicateItem {
            do {
                DDLogError("Notifications_Auth_Debug - set(value), status == errSecDuplicateItem, calling try update. in WMFKeychainCredentials")
                return try update(value: value, forKey: key)
            } catch {
                DDLogError("Notifications_Auth_Debug - set(value), status == errSecDuplicateItem, failure after try update. in WMFKeychainCredentials")
                throw WMFKeychainCredentialsError.unhandledError(status: status)
            }
        } else {
            DDLogError("Notifications_Auth_Debug - set(value), status != errSecSuccess, throwing unhandledError: \(status). in WMFKeychainCredentials")
            throw WMFKeychainCredentialsError.unhandledError(status: status)
        }
    }
    
    fileprivate func update(value:String, forKey key:String) throws {
        DDLogError("Notifications_Auth_Debug - update(value) entered, in WMFKeychainCredentials")
        let query = commonConfigurationDictionary(forKey: key)
        var dataDict = [String : AnyObject]()
        let valueData = value.data(using: String.Encoding.utf8)
        dataDict[kSecValueData as String] = valueData as AnyObject?
        dataDict[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        let status = SecItemUpdate(query as CFDictionary, dataDict as CFDictionary)
        if status != errSecSuccess {
            DDLogError("Notifications_Auth_Debug - update(value), throwing error, status != errSecSuccess: \(status), in WMFKeychainCredentials")
            throw WMFKeychainCredentialsError.unhandledError(status: status)
        }
    }
}
