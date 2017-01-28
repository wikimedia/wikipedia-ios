
import Foundation

enum WMFCaptchaResetterError: LocalizedError {
    case zeroLengthIndex
    var errorDescription: String? {
        return "Captcha reset index not obtained"
    }
}

class WMFCaptchaResetterResult: MTLModel, MTLJSONSerializing {
    var index: String?
    public static func jsonKeyPathsByPropertyKey() -> [AnyHashable : Any]!{
        return wmf_jsonKeyPathsByProperties(of: WMFCaptchaResetterResult())
    }
    
    private func validateNotZeroLengthString(_ string: String?) throws {
        if let string = string {
            guard string.characters.count > 0 else {
                throw WMFCaptchaResetterError.zeroLengthIndex
            }
        }
    }
    
    override func validate() throws {
        try validateNotZeroLengthString(index)
    }
}
