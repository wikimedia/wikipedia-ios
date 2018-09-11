public protocol AuthenticationDelegate: class {
    func isUserLoggedInLocally() -> Bool
    func isUserLoggedInRemotely() -> Bool
    func attemptLogin(to loginURL: URL?, _ completion: @escaping () -> Void, failure: @escaping (_ error: Error) -> Void)
}
