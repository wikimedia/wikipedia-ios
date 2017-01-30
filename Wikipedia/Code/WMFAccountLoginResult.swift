
import Foundation

enum WMFAccountLoginError: LocalizedError {
    case statusNotPass(String?)
    var errorDescription: String? {
        switch self {
        case .statusNotPass(let message?):
            return "Unable to login: \(message)"
        default:
            return "Unable to login: Status not PASS"
        }
    }
}

class WMFAccountLoginResult: MTLModel, MTLJSONSerializing {
    var status: String?
    var username: String?
    var message: String?
    public static func jsonKeyPathsByPropertyKey() -> [AnyHashable : Any]!{
        return wmf_jsonKeyPathsByProperties(of: WMFAccountLoginResult())
    }
    
    private func validatePassStatus(_ status: String?, message: String?) throws {
        guard let status = status, status == "PASS" else {
            throw WMFAccountLoginError.statusNotPass(message)
        }
    }
    
    override func validate() throws {
        try validatePassStatus(status, message: message)
    }
}
