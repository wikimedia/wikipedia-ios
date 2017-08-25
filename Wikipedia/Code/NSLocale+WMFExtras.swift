import Foundation

let wmf_acceptLanguageHeaderForPreferredLanguagesGloabl: String = {
    return NSLocale.wmf_acceptLanguageHeaderForLanguageCodes(NSLocale.wmf_preferredLanguageCodes)
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
            var components = preferredLanguage.lowercased().components(separatedBy: "-")
            if components.count > 2 {
                let zhVariants = ["hans", "hant", "cn", "tw", "sg", "hk", "mo"]
                if (components[0] == "zh" && zhVariants.contains(components[2])) {
                    components = ["zh", components[2]]
                } else {
                    components.removeLast(components.count - 2)
                }
            }
            let languageCode = components.joined(separator: "-")
            if uniqueLanguageCodes.contains(languageCode) {
                continue
            }
            uniqueLanguageCodes.append(languageCode)
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
