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
    /// - Parameter urlLanguage: use to override the language code that we should be checking against, if say url doesn't contain language in it's host. Else internally language will default to url.wmf_language.
    /// - Parameter preferredLanguages: The list of preferred languages to check. Defaults to a list of the user's preferred Wikipedia languages that support variants.
    /// - Returns: The first preferred language variant for a given URL, or nil if the URL is for a Wikipedia with a language that doesn't support variants
    public static func preferredWikipediaLanguageVariant(for url: URL, urlLanguage: String? = nil, preferredLanguages: [String] = preferredWikipediaLanguagesWithVariants) -> String? {
        
        let maybeLanguage = urlLanguage ?? url.wmf_language
        
        guard let language = maybeLanguage else {
            return nil
        }
        return preferredWikipediaLanguageVariant(wmf_language: language, preferredLanguages: preferredLanguages)
    }
    
    public static func preferredWikipediaLanguageVariant(wmf_language language: String, preferredLanguages: [String] = preferredWikipediaLanguagesWithVariants) -> String? {
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
    static func uniqueWikipediaLanguages(with languageIdentifiers: [String], includingLanguagesWithoutVariants: Bool = true) -> [String] {
        var uniqueLanguageCodes = [String]()
        for languageIdentifier in languageIdentifiers {
            let locale = Locale(identifier: languageIdentifier)
            if let languageCode = locale.languageCode?.lowercased() {
                if let scriptLookup = mediaWikiCodeLookupGlobal[languageCode] {
                    let scriptCode = locale.scriptCode?.lowercased() ?? mediaWikiCodeLookupDefaultKeyGlobal
                    if let regionLookup = scriptLookup[scriptCode] ?? scriptLookup[mediaWikiCodeLookupDefaultKeyGlobal] {
                        let regionCode = locale.regionCode?.lowercased() ?? mediaWikiCodeLookupDefaultKeyGlobal
                        if let mediaWikiCode = regionLookup[regionCode] ?? regionLookup[mediaWikiCodeLookupDefaultKeyGlobal] {
                            if !uniqueLanguageCodes.contains(mediaWikiCode) {
                                uniqueLanguageCodes.append(mediaWikiCode)
                            }
                            continue
                        }
                    }
                }
                if includingLanguagesWithoutVariants {
                    let lowercased = languageIdentifier.lowercased()
                    if !uniqueLanguageCodes.contains(lowercased) {
                        uniqueLanguageCodes.append(lowercased)
                    }
                }
            }
        }
        return uniqueLanguageCodes
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
        guard let langCode = self.languageCode else {
            return false
        }
        return (langCode == "en" || langCode.hasPrefix("en-")) ? true : false;
    }
}

extension NSLocale {
    
    fileprivate static var localeCache: [String: Locale] = [:]
    
    @objc(wmf_localeForWikipediaLanguage:)
    public static func wmf_locale(for wikipediaLanguage: String?) -> Locale {
        guard let language = wikipediaLanguage else {
            return Locale.autoupdatingCurrent
        }
        
        let languageInfo = MWLanguageInfo(forCode: language)
        let code = languageInfo.code
        
        var locale = localeCache[code]
        if let locale = locale {
            return locale
        }
        
        if Locale.availableIdentifiers.contains(code) {
            locale = Locale(identifier: code)
        } else {
            locale = Locale.autoupdatingCurrent
        }
        
        localeCache[code] = locale
        
        return locale ?? Locale.autoupdatingCurrent
    }
    
    @objc public static let wmf_preferredLanguageCodes: [String] =
        Locale.uniqueWikipediaLanguages(with: preferredLanguages)
    
    @objc public static var wmf_preferredLocaleLanguageCodes: [String] {
        // use language code when determining if a langauge is preferred (e.g. "en_US" is preferred if "en" was selected)
        preferredLanguages.compactMap { NSLocale(localeIdentifier: $0).languageCode }
    }
    
}
