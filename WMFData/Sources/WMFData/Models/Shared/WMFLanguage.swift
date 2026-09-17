import Foundation

public struct WMFLanguage: Equatable, Codable, Sendable, Identifiable {
    public let languageCode: String
    public let languageVariantCode: String?

    public init(languageCode: String, languageVariantCode: String?) {
        self.languageCode = languageCode
        self.languageVariantCode = languageVariantCode
    }

    /// Uniquely identifies the language including its variant, so that for example `zh-hans` and
    /// `zh-hant` are distinct. Computed, so it is not part of the `Codable` representation.
    public var id: String {
        [languageCode, languageVariantCode].compactMap { $0 }.joined(separator: "-")
    }

    public var localizedName: String {
        Locale.current.localizedString(forLanguageCode: languageCode) ?? languageCode
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
