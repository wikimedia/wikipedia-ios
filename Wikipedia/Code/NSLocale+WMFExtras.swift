import Foundation

let wmf_acceptLanguageHeaderForPreferredLanguagesGloabl: String = {
    return NSLocale.wmf_acceptLanguageHeaderForLanguageCodes(NSLocale.wmf_preferredLanguageCodes)
}()

let wmf_mediaWikiCodeLookupDefaultKeyGlobal = "default"
let wmf_mediaWikiCodeLookupGlobal: [String: [String: [String: String]]] = {
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
    static func uniqueWikipediaLanguages(with languageIdentifiers: [String], includingLanguagesWithoutVariants: Bool = true) -> [String] {
        var uniqueLanguageCodes = [String]()
        for languageIdentifier in languageIdentifiers {
            let locale = Locale(identifier: languageIdentifier)
            if let languageCode = locale.languageCode?.lowercased() {
                if let scriptLookup = wmf_mediaWikiCodeLookupGlobal[languageCode] {
                    let scriptCode = locale.scriptCode?.lowercased() ?? wmf_mediaWikiCodeLookupDefaultKeyGlobal
                    if let regionLookup = scriptLookup[scriptCode] ?? scriptLookup[wmf_mediaWikiCodeLookupDefaultKeyGlobal] {
                        let regionCode = locale.regionCode?.lowercased() ?? wmf_mediaWikiCodeLookupDefaultKeyGlobal
                        if let mediaWikiCode = regionLookup[regionCode] ?? regionLookup[wmf_mediaWikiCodeLookupDefaultKeyGlobal] {
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
    
    @objc public static func wmf_isCurrentLocaleEnglish() -> Bool {
        guard let langCode = (NSLocale.current as NSLocale).object(forKey: NSLocale.Key.languageCode) as? String else {
            return false
        }
        return (langCode == "en" || langCode.hasPrefix("en-")) ? true : false;
    }

    @objc public func wmf_localizedLanguageNameForCode(_ code: String) -> String? {
        return (self as NSLocale).displayName(forKey: NSLocale.Key.languageCode, value: code)
    }

    
    @objc public static func wmf_uniqueLanguageCodesForLanguages(_ languages: [String]) -> [String] {
        return Locale.uniqueWikipediaLanguages(with: languages)
    }
    
    @objc public static let wmf_preferredLanguageCodes: [String] = wmf_uniqueLanguageCodesForLanguages(preferredLanguages)
    
    @objc public static func wmf_acceptLanguageHeaderForLanguageCodes(_ languageCodes: [String]) -> String {
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
    
    @objc public static var wmf_acceptLanguageHeaderForPreferredLanguages: String {
        get {
            return wmf_acceptLanguageHeaderForPreferredLanguagesGloabl
        }
    }
}
