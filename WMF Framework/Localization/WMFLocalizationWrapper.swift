import Foundation
import WMFLocalizations

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
