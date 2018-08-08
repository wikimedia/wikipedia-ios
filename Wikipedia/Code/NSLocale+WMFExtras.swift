import Foundation

let wmf_acceptLanguageHeaderForPreferredLanguagesGloabl: String = {
    return NSLocale.wmf_acceptLanguageHeaderForLanguageCodes(NSLocale.wmf_preferredLanguageCodes)
}()

struct MediaWikiAcceptLanguageMapping: Codable {
    
}

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
        var uniqueLanguageCodes = [String]()
        for preferredLanguage in languages {
            let locale = Locale(identifier: preferredLanguage)
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
                
                if !uniqueLanguageCodes.contains(languageCode) {
                    uniqueLanguageCodes.append(languageCode)
                }
            }
        }
        return uniqueLanguageCodes
    }
    
    @objc public static var wmf_preferredLanguageCodes: [String] {
        get {
            return wmf_uniqueLanguageCodesForLanguages(preferredLanguages)
        }
    }
    
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
