
import Foundation

enum WMFTokensError: LocalizedError {
    case zeroLengthToken
    var errorDescription: String? {
        return "No valid string value fetched"
    }
}

class WMFTokens: MTLModel, MTLJSONSerializing {
    var csrftoken: String?
    var logintoken: String?
    var createaccounttoken: String?
    public static func jsonKeyPathsByPropertyKey() -> [AnyHashable : Any]!{
        return wmf_jsonKeyPathsByProperties(of: WMFTokens())
    }
    
    private func validateNotZeroLengthString(_ string: String?) throws {
        if let string = string {
            guard string.characters.count > 0 else {
                throw WMFTokensError.zeroLengthToken
            }
        }
    }
    
    override func validate() throws {
        try validateNotZeroLengthString(csrftoken)
        try validateNotZeroLengthString(logintoken)
        try validateNotZeroLengthString(createaccounttoken)
    }
}
