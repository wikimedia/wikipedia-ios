import Foundation

public func WMFLocalizedString(_ key: String, languageCode wikipediaLanguageCode: String? = nil, bundle: Bundle = Bundle.wmf_localization, value: String, comment: String) -> String {
    return WMFLocalizedStringWithDefaultValue(key, wikipediaLanguageCode, bundle, value, comment)
}
