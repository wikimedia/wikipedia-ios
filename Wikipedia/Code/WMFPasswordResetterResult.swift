
import Foundation

enum WMFPasswordResetterError: LocalizedError {
    case statusNotSuccess
    var errorDescription: String? {
        return "Password reset did not succeed"
    }
}

class WMFPasswordResetterResult: MTLModel, MTLJSONSerializing {
    var status: String?
    public static func jsonKeyPathsByPropertyKey() -> [AnyHashable : Any]!{
        return wmf_jsonKeyPathsByProperties(of: WMFPasswordResetterResult())
    }
    
    private func validateSuccessStatus() throws {
        guard let status = status, status == "success" else {
            throw WMFPasswordResetterError.statusNotSuccess
        }
    }
    
    override func validate() throws {
        try validateSuccessStatus()
    }
}
