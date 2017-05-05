import Foundation

public func WMFLocalizedString(_ key: String, siteURL: URL? = nil, bundle: Bundle = Bundle.wmf_localization, value: String, comment: String) -> String {
    guard let siteURL = siteURL else {
        return NSLocalizedString(key, tableName: nil, bundle: bundle, value: value, comment: comment)
    }
    return WMFLocalizedStringWithDefaultValue(key, siteURL, bundle, value, comment)
}
