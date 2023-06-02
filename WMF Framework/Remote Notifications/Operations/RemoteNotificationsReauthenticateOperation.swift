import Foundation
import CocoaLumberjackSwift

class RemoteNotificationsReauthenticateOperation: AsyncOperation {
    
    var appLanguageOperationError: Error?
    private(set) var didReauthenticate: Bool = false
    private let authManager: WMFAuthenticationManager
    
    init(authManager: WMFAuthenticationManager) {
        self.authManager = authManager
    }
    
    override func execute() {
        
        guard let error = appLanguageOperationError as? RemoteNotificationsAPIController.ResultError,
              error.code == "login-required" else {
            finish()
            return
        }

        DDLogError("Notifications_Auth_Debug - reauthenticating in RemoteNotificationsReauthenticateOperation")
        self.authManager.loginWithSavedCredentials { [weak self] result in
            
            guard let self = self else {
                DDLogError("Notifications_Auth_Debug - reauthenticating in RemoteNotificationsReauthenticateOperation. early exit self.")
                return
            }
            
            switch result {
            case .success:
                DDLogError("Notifications_Auth_Debug - reauthenticating in RemoteNotificationsReauthenticateOperation. success")
                self.didReauthenticate = true
                self.finish()
            case .alreadyLoggedIn:
                DDLogError("Notifications_Auth_Debug - reauthenticating in RemoteNotificationsReauthenticateOperation. alreadyLoggedIn")
                self.finish()
            case .failure(let error):
                DDLogError("Notifications_Auth_Debug - reauthenticating in RemoteNotificationsReauthenticateOperation. error: \(error)")
                self.finish(with: error)
            }
        }
    }
}
