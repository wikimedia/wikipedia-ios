
import Foundation

@objc(WMFPushNotificationsController)
public class PushNotificationsController: NSObject {
    @objc public var deviceToken: Data? {
        didSet {
            guard _deviceToken == nil,
                  deviceToken != nil else {
                assertionFailure("Expecting to only set device token once per lifecycle of app.")
                return
            }
            
            _deviceToken = deviceToken
        }
    }
    private var _deviceToken: Data?
    
    private var deviceTokenString: String? {
        guard let deviceToken = deviceToken else {
            assertionFailure("Must have device token to register for echo notifications")
            return nil
        }
        
        //convert to string
        let tokenComponents = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let deviceTokenString = tokenComponents.joined()
        return deviceTokenString
    }
    
    private let authenticationManager: WMFAuthenticationManager
    private let echoFetcher = EchoNotificationsFetcher()
    
    @objc public init(authenticationManager: WMFAuthenticationManager) {
        self.authenticationManager = authenticationManager
    }
    
    @objc public func checkNotificationsFullyEnabled(completion: @escaping (Bool) -> Void) {
        
        guard deviceToken != nil else {
            completion(false)
            return
        }
        
        guard authenticationManager.isLoggedIn else {
            completion(false)
            return
        }
        
        guard UserDefaults.standard.wmf_echoPushNotificationsRegistered() else {
            completion(false)
            return
        }
        
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getNotificationSettings { settings in
            switch settings.authorizationStatus {
                case .authorized:
                    DispatchQueue.main.async {
                        completion(true)
                    }
                default:
                    DispatchQueue.main.async {
                        completion(false)
                    }
            }
        }
    }
    
    @objc public func fullyEnableNotifications(completion: @escaping (Bool, Error?) -> Void) {
        
        guard deviceToken != nil else {
            assertionFailure("Missing device token, be sure AppDelegate is set up properly and we are assigning callback token to this class.")
            completion(false, nil)
            return
        }
        
        guard authenticationManager.isLoggedIn else {
            assertionFailure("For now this controller does not trigger login panels and such. For testing please login first before calling this method")
            completion(false, nil)
            return
        }
        
        requestUNNotificationAuthorization { [weak self] isAuthorized, error in
            
            guard let self = self else { return }
            
            if error != nil || !isAuthorized {
                DispatchQueue.main.async {
                    completion(false, error)
                }
                return
            }
            
            self.registerForEchoNotificationsIfNecessary(completion: completion)
        }
    }
    
    @objc public func fullyDisableNotifications(completion: @escaping (Bool, Error?) -> Void) {
        UserDefaults.standard.wmf_setEchoPushNotificationsRegistered(false)
        
        guard let deviceTokenString = deviceTokenString else {
            assertionFailure("Must have device token to register for echo notifications")
            completion(false, nil)
            return
        }
        
        self.echoFetcher.deregisterForEchoNotificationsWithDeviceTokenString(deviceTokenString: deviceTokenString, completion: completion)
    }
    
    private func requestUNNotificationAuthorizationIfNecessary(completion: @escaping (Bool, Error?) -> Void) {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getNotificationSettings { [weak self] settings in
            
            guard let self = self else { return }
            
            switch settings.authorizationStatus {
            case .authorized:
                completion(true, nil)
            case .denied:
                completion(false, nil)
            case .notDetermined:
                self.requestUNNotificationAuthorization(completion: completion)
            default:
                //TODO: something for unknown default, .ephemeral, .provisional
                return
            }
        }
    }
    
    private func registerForEchoNotificationsIfNecessary(completion: @escaping (Bool, Error?) -> Void) {
        
        guard UserDefaults.standard.wmf_echoPushNotificationsRegistered() == false else {
            completion(true, nil)
            return
        }
        
        guard let deviceTokenString = deviceTokenString else {
            assertionFailure("Must have device token to register for echo notifications")
            completion(false, nil)
            return
        }
        
        echoFetcher.registerForEchoNotificationsWithDeviceTokenString(deviceTokenString: deviceTokenString) { success, error in
            if !success || error != nil {
                UserDefaults.standard.wmf_setEchoPushNotificationsRegistered(false)
                DispatchQueue.main.async {
                    completion(false, error)
                }
                
                return
            }
            
            UserDefaults.standard.wmf_setEchoPushNotificationsRegistered(true)
            DispatchQueue.main.async {
                completion(true, error)
            }
        }
    }
    
    private func requestLoginAuthorizationIfNecessary(completion: @escaping (Bool, Error?) -> Void) {
        
        guard !authenticationManager.isLoggedIn else {
            completion(true, nil)
            return
        }
        
        completion(false, nil)
    }
    
    private func requestUNNotificationAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, error in
            
            completion(granted, error)
        }
    }
}
