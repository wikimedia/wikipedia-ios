import Foundation

public func WMFLocalizedString(_ key: String, siteURL: URL? = nil, bundle: Bundle = Bundle.wmf_localization, value: String, comment: String) -> String {
    return WMFLocalizedStringWithDefaultValue(key, siteURL, bundle, value, comment)
}
