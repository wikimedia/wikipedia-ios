import Foundation

class RemoteNotificationsReauthenticateOperation: AsyncOperation, @unchecked Sendable {
    
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

        self.authManager.loginWithSavedCredentials { [weak self] result in
            
            guard let self = self else {
                return
            }
            
            switch result {
            case .success:
                self.didReauthenticate = true
                self.finish()
            case .failure(let error):
                self.finish(with: error)
            }
        }
    }
}
