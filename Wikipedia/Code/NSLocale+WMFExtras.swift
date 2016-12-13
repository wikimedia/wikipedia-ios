import Foundation

let wmf_acceptLanguageHeaderForPreferredLanguagesGloabl: String = {
    return Locale.wmf_acceptLanguageHeaderForLanguageCodes(Locale.wmf_preferredLanguageCodes)
}()

extension Locale {
    public static func wmf_isCurrentLocaleEnglish() -> Bool {
        guard let langCode = (Locale.current as NSLocale).object(forKey: NSLocale.Key.languageCode) as? String else {
            return false
        }
        return (langCode == "en" || langCode.hasPrefix("en-")) ? true : false;
    }

    public func wmf_localizedLanguageNameForCode(_ code: String) -> String? {
        return (self as NSLocale).displayName(forKey: NSLocale.Key.languageCode, value: code)
    }
    
    public static func wmf_uniqueLanguageCodesForLanguages(_ languages: [String]) -> [String] {
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
    
    public static var wmf_preferredLanguageCodes: [String] {
        get {
            return wmf_uniqueLanguageCodesForLanguages(preferredLanguages)
        }
    }
    
    public static func wmf_acceptLanguageHeaderForLanguageCodes(_ languageCodes: [String]) -> String {
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
    
    public static var wmf_acceptLanguageHeaderForPreferredLanguages: String {
        get {
            return wmf_acceptLanguageHeaderForPreferredLanguagesGloabl
        }
    }
}
