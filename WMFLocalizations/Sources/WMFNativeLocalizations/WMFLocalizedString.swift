import Foundation
import os

public func WMFLocalizedString(_ key: String, languageCode wikipediaLanguageCode: String? = nil, bundle: Bundle? = nil, value: String, comment: String) -> String {

    let baseBundle = bundle ?? Bundle.module

    var translation: String?
    
    if let languageCode = wikipediaLanguageCode {
        let languageBundle = baseBundle.wmf_languageBundle(forWikipediaLanguageCode: languageCode)
        translation = languageBundle?.localizedString(forKey: key, value: nil, table: nil)
    }

    if translation == nil || translation == key || translation?.isEmpty == true {
        translation = baseBundle.localizedString(forKey: key, value: nil, table: nil)
    }
    
    if translation == nil || translation == key || translation?.isEmpty == true {
        translation = baseBundle.wmf_fallbackLanguageBundle?.localizedString(forKey: key, value: value, table: nil)
    }
    
    return translation ?? ""
}

public extension Bundle {
    
    fileprivate var wmf_fallbackLanguageBundle: Bundle? {
        return self.path(forResource: "en", ofType: "lproj")
            .flatMap { Bundle(path: $0) }
    }
    
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
    
    /// Cache of language bundles, protected by an OSAllocatedUnfairLock for Swift 6 concurrency safety.
    private static let _wmf_languageBundlesCache = OSAllocatedUnfairLock<[String: Bundle]>(initialState: [:])

    /// Name of the localization bundle to use for a given Wikipedia language code.
    private func wmf_languageBundleName(forWikipediaLanguageCode languageCode: String) -> String {
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
    fileprivate func wmf_languageBundle(forWikipediaLanguageCode languageCode: String) -> Bundle? {
        // Fast path: check cache before doing any work
        if let cached = Bundle._wmf_languageBundlesCache.withLock({ $0[languageCode] }) {
            return cached
        }

        // Resolve the bundle outside the lock to avoid holding it during file I/O.
        let languageBundleName = wmf_languageBundleName(forWikipediaLanguageCode: languageCode)
        let paths = self.paths(forResourcesOfType: "lproj", inDirectory: nil)
        let filename = languageBundleName.lowercased() + ".lproj"

        guard let path = paths.first(where: { $0.lowercased().hasSuffix(filename) }),
              let resolved = Bundle(path: path) else {
            return nil
        }

        // Insert into cache if absent, then return whatever is stored (handles concurrent first-load).
        return Bundle._wmf_languageBundlesCache.withLock { cache in
            if let existing = cache[languageCode] {
                return existing
            }
            cache[languageCode] = resolved
            return resolved
        }
    }
}
