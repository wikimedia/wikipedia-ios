public protocol AuthenticationDelegate: class {
    func isUserLoggedInLocally() -> Bool
    func isUserLoggedInRemotely() -> Bool
    func attemptLogin(_ completion: @escaping () -> Void, failure: @escaping (_ error: Error) -> Void)
}
