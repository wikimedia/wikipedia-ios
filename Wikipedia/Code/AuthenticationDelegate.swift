public protocol AuthenticationDelegate: class {
    func isUserLoggedInLocally() -> Bool
    func isUserLoggedInRemotely() -> Bool
    func attemptLogin(completion: @escaping WMFAuthenticationManager.AuthenticationResultHandler)
}
