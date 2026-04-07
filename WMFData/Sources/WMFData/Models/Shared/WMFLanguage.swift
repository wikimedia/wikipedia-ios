import Foundation

public struct WMFLanguage: Equatable, Codable, Sendable {
    public let languageCode: String
    public let languageVariantCode: String?
    
    public init(languageCode: String, languageVariantCode: String?) {
        self.languageCode = languageCode
        self.languageVariantCode = languageVariantCode
    }
    
    var isRTL: Bool {
        switch languageCode.lowercased() {
        case "arc", "arz", "ar", "azb", "bcc", "bqi", "ckb", "dv", "fa", "glk", "lrc", "he", "khw", "ks", "mzn", "nqo", "pnb", "ps", "sd", "ug", "ur", "yi":
            return true
        case "kk" where languageVariantCode?.lowercased() == "arab":
            return true
        case "ku" where languageVariantCode?.lowercased() == "arab":
            return true
        default:
            return false
        }
    }
}
