import Foundation

public extension NSError {
    /// Don't use this method from Swift, use RequestError directly
    @objc static var wmf_invalidParametersError: NSError {
        return RequestError.invalidParameters as NSError
    }
}
