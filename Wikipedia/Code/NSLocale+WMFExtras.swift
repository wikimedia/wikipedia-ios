import Foundation

fileprivate let acceptLanguageHeaderForPreferredLanguagesGlobal: String = {
    return Locale.acceptLanguageHeaderForLanguageCodes(NSLocale.wmf_preferredLanguageCodes)
}()

fileprivate let mediaWikiCodeLookupDefaultKeyGlobal = "default"
fileprivate let mediaWikiCodeLookupGlobal: [String: [String: [String: String]]] = {
    guard
        let fileURL = Bundle.wmf.url(forResource: "MediaWikiAcceptLanguageMapping", withExtension: "json"),
        let data = try? Data(contentsOf: fileURL),
        let JSONObject = try? JSONSerialization.jsonObject(with: data, options: []),
        let mapping = JSONObject as? [String: [String: [String: String]]]
    else {
        return [:]
    }
    return mapping
}()

extension Locale {
    /// - Parameter url: The URL to check
    /// - Parameter urlLanguage: use to override the language code that we should be checking against, if say url doesn't contain language in it's host. Else internally language will default to url.wmf_languageCode.
    /// - Parameter preferredLanguages: The list of preferred languages to check. Defaults to a list of the user's preferred Wikipedia languages that support variants.
    /// - Returns: The first preferred language variant for a given URL, or nil if the URL is for a Wikipedia with a language that doesn't support variants
    public static func preferredWikipediaLanguageVariant(for url: URL, urlLanguage: String? = nil, preferredLanguages: [String] = preferredWikipediaLanguagesWithVariants) -> String? {
        
        let maybeLanguage = urlLanguage ?? url.wmf_languageCode
        
        guard let language = maybeLanguage else {
            return nil
        }
        return preferredWikipediaLanguageVariant(wmf_languageCode: language, preferredLanguages: preferredLanguages)
    }
    
    public static func preferredWikipediaLanguageVariant(wmf_languageCode language: String, preferredLanguages: [String] = preferredWikipediaLanguagesWithVariants) -> String? {
        for languageCode in preferredLanguages {
            guard languageCode.hasPrefix(language + "-") else {
                continue
            }
            return languageCode
        }
        return nil
    }
    
    /// List of Wikipedia languages with variants in the order that the user preferrs them. Currently only supports zh and sr.
    public static let preferredWikipediaLanguagesWithVariants: [String] = uniqueWikipediaLanguages(with: preferredLanguages, includingLanguagesWithoutVariants: false)
    
    /// - Parameter languageIdentifiers: List of `Locale` language identifers
    /// - Parameter includingLanguagesWithoutVariants: Pass true to include Wikipedias without variants, passing false will only return languages with variants (currently only supporting zh and sr)
    /// - Returns: An array of preferred Wikipedia languages based on the provided array of language identifiers
    /// - Note: Access level is internal for testing
    static func uniqueWikipediaLanguages(with languageIdentifiers: [String], includingLanguagesWithoutVariants: Bool = true, useLocaleIdentifiers: Bool = true) -> [String] {
        var uniqueLanguageCodes = [String]()
        for languageIdentifier in languageIdentifiers {
            let locale = Locale(identifier: languageIdentifier)
            
            guard let languageCode = locale.language.languageCode?.identifier.lowercased() else { continue }
            
            // If the app supports a language variant for the locale, return the best guess of the correct Wikipedia language variant code
            if let mediaWikiCode = Locale.mediaWikiCodeForLocale(locale) {
                if !uniqueLanguageCodes.contains(mediaWikiCode) {
                    uniqueLanguageCodes.append(mediaWikiCode)
                }
                continue
            }

            // Otherwise, add the language code of the locale.
            // This could either be the full locale identifier string from the OS, or the Wikipedia language code.
            if includingLanguagesWithoutVariants {
                let code = useLocaleIdentifiers ? languageIdentifier.lowercased() : languageCode
                if !uniqueLanguageCodes.contains(code) {
                    uniqueLanguageCodes.append(code)
                }
            }
        }
        return uniqueLanguageCodes
    }
    
    /// There are times, like in onboarding, where we need to guess a user's preferred language variant from the user's language settings in the operating system.
    /// There is often not a direct mapping. This method looks up the best match for languages with variants
    /// - Parameter locale: A locale instance
    /// - Returns: The Wikipedia language variant code that most closely matches the provided locale
    fileprivate static func mediaWikiCodeForLocale(_ locale: Locale) -> String? {
        if let languageCode = locale.language.languageCode?.identifier.lowercased() {
            if let scriptLookup = mediaWikiCodeLookupGlobal[languageCode] {
                let scriptCode = locale.language.script?.identifier.lowercased() ?? mediaWikiCodeLookupDefaultKeyGlobal
                if let regionLookup = scriptLookup[scriptCode] ?? scriptLookup[mediaWikiCodeLookupDefaultKeyGlobal] {
                    let regionCode = locale.region?.identifier.lowercased() ?? mediaWikiCodeLookupDefaultKeyGlobal
                    if let mediaWikiCode = regionLookup[regionCode] ?? regionLookup[mediaWikiCodeLookupDefaultKeyGlobal] {
                        return mediaWikiCode
                    }
                }
            }
        }
        return nil
    }
    
    /// - Parameter languageCodes: List of Wikipedia language codes
    /// - Returns: The string value for an Accept-Language header
    /// - Note: Access level is internal for testing
    static func acceptLanguageHeaderForLanguageCodes(_ languageCodes: [String]) -> String {
        let count: Double = Double(languageCodes.count)
        var q: Double = 1.0
        let qDelta = 1.0/count
        var acceptLanguageString = ""
        for languageCode in languageCodes {
            if q < 1.0 {
                acceptLanguageString += ", "
            }
            acceptLanguageString += languageCode
            if q < 1.0 {
                acceptLanguageString += String(format: ";q=%.2g", q)
            }
            q -= qDelta
        }
        return acceptLanguageString
    }
    
    public static var acceptLanguageHeaderForPreferredLanguages: String {
        acceptLanguageHeaderForPreferredLanguagesGlobal
    }
    
    public var isEnglish: Bool {
        guard let langCode = self.language.languageCode?.identifier else {
            return false
        }
        return (langCode == "en" || langCode.hasPrefix("en-")) ? true : false
    }
}

extension NSLocale {
    
    fileprivate static var localeCache: [String: Locale] = [:]
    
    @objc(wmf_localeForWikipediaLanguageCode:)
    public static func wmf_locale(for wikipediaLanguageCode: String?) -> Locale {
        guard let language = wikipediaLanguageCode else {
            return Locale.autoupdatingCurrent
        }
        
        var locale = localeCache[language]
        if let locale = locale {
            return locale
        }
        
        if Locale.availableIdentifiers.contains(language) {
            locale = Locale(identifier: language)
        } else if language == "simple" || language == "test" {
            // This handles two special subdomains/language codes.
            // The Simple English wiki uses 'simple'. The development test wiki uses 'test'.
            // Both return the English locale. Test could potentially use Locale.autoupdatingCurrent instead.
            locale = Locale(identifier: "en")
        } else {
            locale = Locale.autoupdatingCurrent
        }
        
        localeCache[language] = locale
        
        return locale ?? Locale.autoupdatingCurrent
    }
    
    // This property contains the suggested languages based on the user's OS settings.
    // It can contain both language variant codes for languages that support variants and locale identifiers.
    // Languages without variants are represented by the full locale identifier, which differentiate by region as well as language, such as en-US and en-GB.
    @objc public static let wmf_preferredLanguageCodes: [String] =
        Locale.uniqueWikipediaLanguages(with: preferredLanguages)
    
    
    // This property contains the suggested languages based on the user's OS settings during onboarding.
    // It can contain both language variant codes for languages that support variants and language codes.
    // Note it the returned array does not contain locale identifiers, which differentiate by region as well as language, such as en-US and en-GB.
    @objc public static let wmf_preferredWikipediaLanguageCodes: [String] =
        Locale.uniqueWikipediaLanguages(with: preferredLanguages, useLocaleIdentifiers: false)
    
    
    // This method is used when an incoming article has no language variant information. For instance, when syncing reading lists.
    // Given a language code returns the best guess of a language variant for languages that support variants.
    // First it checks for a preferred variant from the user's OS language settings.
    // If none is found, it returns the default language variant as specified in the "MediaWikiAcceptLanguageMapping.json" file.
    // Returns nil for languages that do not support language variants or if no default variant is found for a variant-supporting language.
    @objc public static func wmf_bestLanguageVariantCodeForLanguageCode(_ languageCode: String) -> String? {
        // If the prefix matches, it is the same languages. If it is not the same string, it is a variant.
        if let languageVariantCode = wmf_preferredWikipediaLanguageCodes.first(where: { $0.hasPrefix(languageCode) && $0 != languageCode }) {
            return languageVariantCode
        } else if let fallbackLanguageVariant = Locale.mediaWikiCodeForLocale(Locale(identifier: languageCode)) {
            return fallbackLanguageVariant
        } else {
            return nil
        }
    }
    
}
