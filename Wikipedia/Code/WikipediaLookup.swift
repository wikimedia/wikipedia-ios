import Foundation
import WMF.WMFLogging

@objc class WikipediaLookup: NSObject {
    static let byCode: [String: Wikipedia] = {
        guard let languagesFileURL = Bundle.wmf.url(forResource: "wikipedia-languages", withExtension: "json") else {
            return [:]
        }
        do {
            let data = try Data(contentsOf: languagesFileURL)
            return try JSONDecoder().decode([String: Wikipedia].self, from: data)
        } catch let error {
            DDLogError("Error decoding language list \(error)")
            return [:]
        }
    }()
    
    @objc static let allLanguageLinks: [MWKLanguageLink] = {
        return byCode.compactMap { (kv) -> MWKLanguageLink in
            let wikipedia = kv.value
            var localizedName = wikipedia.languageName
            if !wikipedia.languageCode.contains("-") {
                // iOS will return less descriptive name for compound codes - ie "Chinese" for zh-yue which
                // should be "Cantonese". It looks like iOS ignores anything after the "-".
                if let iOSLocalizedName = (Locale.current as NSLocale).wmf_localizedLanguageNameForCode(wikipedia.languageCode) {
                    localizedName = iOSLocalizedName
                }
            }
            return MWKLanguageLink(languageCode: wikipedia.languageCode, pageTitleText: "", name: wikipedia.languageName, localizedName: localizedName)
        }
    }()
}

