import Foundation
import WMFLocalizations

public func WMFLocalizedString(_ key: String, languageCode wikipediaLanguageCode: String? = nil, bundle: Bundle = Bundle.wmf_localization, value: String, comment: String) -> String {
    return WMFLocalizedStringWithDefaultValue(key, wikipediaLanguageCode, bundle, value, comment)
}

@objc public final class WMFLocalizationWrapper: NSObject {
    
    @objc public static func wmf_NewLocalizedStringWithDefaultValue(
        _ key: String,
        wikipediaLanguageCode: String? = nil,
        bundle: Bundle? = nil,
        value: String,
        comment: String
    ) -> String {
        WMFNewLocalizedString(key, languageCode: wikipediaLanguageCode, bundle: bundle, value: value, comment: comment)
    }
}
