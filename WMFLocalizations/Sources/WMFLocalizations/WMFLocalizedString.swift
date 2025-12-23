import Foundation

public func WMFLocalizedString(_ key: String, languageCode wikipediaLanguageCode: String? = nil, bundle: Bundle? = nil, value: String, comment: String) -> String {

    let baseBundle = bundle ?? Bundle.module
    
    let languageCode = wikipediaLanguageCode ?? Locale.current.language.languageCode?.identifier ?? "en"
    
    var translation: String?
    
    let languageBundle = baseBundle.wmf_languageBundle(forWikipediaLanguageCode: languageCode)
    translation = languageBundle?.localizedString(forKey: key, value: nil, table: nil)
    
    if translation == nil || translation == key || translation?.isEmpty == true {
        translation = baseBundle.localizedString(forKey: key, value: nil, table: nil)
    }
    
    return translation ?? ""
}

fileprivate extension Bundle {
    
    /// A mapping of language variant content codes to available native `NSLocale` bundle identifiers.
    /// The values map to existing `.lproj` folders.
    private static let variantContentCodeToLocalizationBundleMapping: [String: String] = [
        // Chinese variants
        "zh-hk": "zh-hant",
        "zh-mo": "zh-hant",
        "zh-my": "zh-hans",
        "zh-sg": "zh-hans",
        "zh-tw": "zh-hant",
        
        // Serbian variants
        // no-op - both variants are natively available iOS localizations
        
        // Kurdish variants
        "ku-arab": "ckb",
        
        // Tajik variants
        "tg-latn": "tg",
        
        // Uzbek variants
        "uz-cyrl": "uz"
    ]
    
    /// The base localization bundle.
    static var wmf_localizationBundle: Bundle {
        return Bundle.module
    }
    
    /// Cache of language bundles (protected by a lock).
    nonisolated(unsafe) private static var _wmf_languageBundles: [String: Bundle] = [:]
    private static let _wmf_languageBundlesLock = NSLock()
    
    /// Name of the localization bundle to use for a given Wikipedia language code.
    func wmf_languageBundleName(forWikipediaLanguageCode languageCode: String) -> String {
        if let mapped = Bundle.variantContentCodeToLocalizationBundleMapping[languageCode] {
            return mapped
        } else if languageCode == "zh" {
            var bundleName = "zh-hans"
            for code in Locale.preferredLanguages {
                guard code.hasPrefix("zh") else { continue }
                let components = code.split(separator: "-")
                if components.count == 2 {
                    bundleName = code.lowercased()
                    break
                }
            }
            return bundleName
        } else if languageCode == "sr" {
            return "sr-ec"
        } else if languageCode == "no" {
            return "nb"
        } else {
            return languageCode
        }
    }
    
    /// Returns a bundle for a given Wikipedia language code, caching the result.
    func wmf_languageBundle(forWikipediaLanguageCode languageCode: String) -> Bundle? {
        Bundle._wmf_languageBundlesLock.lock()
        if let cached = Bundle._wmf_languageBundles[languageCode] {
            Bundle._wmf_languageBundlesLock.unlock()
            return cached
        }
        Bundle._wmf_languageBundlesLock.unlock()
        
        let languageBundleName = wmf_languageBundleName(forWikipediaLanguageCode: languageCode)
        let paths = self.paths(forResourcesOfType: "lproj", inDirectory: nil)
        let filename = languageBundleName.lowercased() + ".lproj"
        
        guard let path = paths.first(where: { $0.lowercased().hasSuffix(filename) }),
              let bundle = Bundle(path: path) else {
            return nil
        }
        
        Bundle._wmf_languageBundlesLock.lock()
        Bundle._wmf_languageBundles[languageCode] = bundle
        Bundle._wmf_languageBundlesLock.unlock()
        
        return bundle
    }
    
    /// English fallback bundle.
    var wmf_fallbackLanguageBundle: Bundle? {
        struct Static {
            static let fallback: Bundle? = {
                if let path = Bundle.module.path(forResource: "en", ofType: "lproj") {
                    return Bundle(path: path)
                }
                return nil
            }()
        }
        return Static.fallback
    }
}
