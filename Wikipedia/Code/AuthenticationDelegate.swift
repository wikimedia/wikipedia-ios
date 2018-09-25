public protocol AuthenticationDelegate: class {
    func isUserLoggedInLocally() -> Bool
    func isUserLoggedInRemotely() -> Bool
    func attemptLogin(_ loginURL: URL?, completion: @escaping WMFAuthenticationManager.LoginResultHandler)
}
