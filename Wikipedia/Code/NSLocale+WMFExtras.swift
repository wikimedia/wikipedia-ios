import Foundation

extension NSLocale {
    public class func wmf_isCurrentLocaleEnglish() -> Bool {
        guard let langCode = NSLocale.currentLocale().objectForKey(NSLocaleLanguageCode) as? String else {
            return false
        }
        return (langCode == "en" || langCode.hasPrefix("en-")) ? true : false;
    }
   
    public class func wmf_isCurrentLocaleChineseVariant() -> Bool {
        guard let langCode = NSLocale.currentLocale().objectForKey(NSLocaleLanguageCode) as? String else {
            return false
        }
        return (langCode == "zh" || langCode.hasPrefix("zh-")) ? true : false;
    }

    public func wmf_localizedLanguageNameForCode(code: String) -> String? {
        return self.displayNameForKey(NSLocaleLanguageCode, value: code)
    }
    
    public class func wmf_uniqueLanguageCodesForLanguages(languages: [String]) -> [String] {
        var uniqueLanguageCodes = [String]()
        for preferredLanguage in languages {
            var components = preferredLanguage.lowercaseString.componentsSeparatedByString("-")
            if components.count > 2 {
                let zhVariants = ["hans", "hant", "cn", "tw", "sg", "hk", "mo"]
                if (components[0] == "zh" && zhVariants.contains(components[2])) {
                    components = ["zh", components[2]]
                } else {
                    components.removeLast(components.count - 2)
                }
            }
            let languageCode = components.joinWithSeparator("-")
            if uniqueLanguageCodes.contains(languageCode) {
                continue
            }
            uniqueLanguageCodes.append(languageCode)
        }
        return uniqueLanguageCodes
    }
    
    public class var wmf_preferredLanguageCodes: [String] {
        get {
            return wmf_uniqueLanguageCodesForLanguages(preferredLanguages())
        }
    }
    
    public class func wmf_acceptLanguageHeaderForLanguageCodes(languageCodes: [String]) -> String {
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
    
    public class var wmf_acceptLanguageHeaderForPreferredLanguages: String {
        get {
            struct Once {
                static var token: dispatch_once_t = 0
                static var header: String = ""
            }
            dispatch_once(&Once.token) {
                Once.header = wmf_acceptLanguageHeaderForLanguageCodes(wmf_preferredLanguageCodes)
            }
            return Once.header
        }
    }
}
