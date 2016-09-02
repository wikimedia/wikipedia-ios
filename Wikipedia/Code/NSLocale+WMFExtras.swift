import Foundation

extension NSLocale {
    public class func wmf_isCurrentLocaleEnglish() -> Bool {
        guard let langCode = NSLocale.currentLocale().objectForKey(NSLocaleLanguageCode) as? String else {
            return false
        }
        return (langCode == "en" || langCode.hasPrefix("en-")) ? true : false;
    }
    public func wmf_localizedLanguageNameForCode(code: String) -> String? {
        return self.displayNameForKey(NSLocaleLanguageCode, value: code)
    }
}
