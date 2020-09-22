import Foundation

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

    @objc public func wmf_localizedLanguageNameForCode(_ code: String) -> String? {
        return (self as NSLocale).displayName(forKey: NSLocale.Key.languageCode, value: code)
    }
}
