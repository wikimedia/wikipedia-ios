import Foundation

public struct WMFAcceptLanguageUtils {

    /// Legacy MediaWiki codes for the regional Chinese variants, as in the app's wikipedia-language-variants.json
    private static let legacyChineseRegionalVariantCodes: [String: String] = [
        "zh-Hans-CN": "zh-cn",
        "zh-Hans-MY": "zh-my",
        "zh-Hans-SG": "zh-sg",
        "zh-Hant-HK": "zh-hk",
        "zh-Hant-MO": "zh-mo",
        "zh-Hant-TW": "zh-tw"
    ]

    /// mobile-html, feed/featured and the page summary drop the region from BCP 47 codes (zh-Hant-TW is served as zh-hant), so regional
    /// Chinese variants send the legacy code first, e.g. "zh-tw,zh-Hant-TW;q=0.9", like the Android app (T359822). Others send the BCP 47 code only.
    public static func acceptLanguageHeaderValue(forLanguageVariantCode languageVariantCode: String) -> String {
        guard let legacyLanguageVariantCode = legacyChineseRegionalVariantCodes[languageVariantCode] else {
            return languageVariantCode
        }
        return "\(legacyLanguageVariantCode),\(languageVariantCode);q=0.9"
    }
}
