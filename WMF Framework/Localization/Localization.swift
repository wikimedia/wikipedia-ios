import Foundation

public func WMFLocalizedString(_ key: String, language wikipediaLanguage: String? = nil, bundle: Bundle = Bundle.wmf_localization, value: String, comment: String) -> String {
    return WMFLocalizedStringWithDefaultValue(key, wikipediaLanguage, bundle, value, comment)
}
