import Foundation
import WMF.WMFLogging
import CocoaLumberjackSwift

@objc class WikipediaLookup: NSObject {
    static let allWikipedias: [Wikipedia] = {
        guard let languagesFileURL = Bundle.wmf.url(forResource: "wikipedia-languages", withExtension: "json") else {
            return []
        }
        do {
            let data = try Data(contentsOf: languagesFileURL)
            return try JSONDecoder().decode([Wikipedia].self, from: data)
        } catch let error {
            DDLogError("Error decoding language list \(error)")
            return []
        }
    }()
    
    @objc static let allLanguageLinks: [MWKLanguageLink] = {
        return allWikipedias.map { (wikipedia) -> MWKLanguageLink in
            var localizedName = wikipedia.localName
            if !wikipedia.languageCode.contains("-") {
                // iOS will return less descriptive name for compound codes - ie "Chinese" for zh-yue which
                // should be "Cantonese". It looks like iOS ignores anything after the "-".
                if let iOSLocalizedName = Locale.current.localizedString(forLanguageCode: wikipedia.languageCode) {
                    localizedName = iOSLocalizedName
                }
            }
            return MWKLanguageLink(languageCode: wikipedia.languageCode, pageTitleText: "", name: wikipedia.languageName, localizedName: localizedName, languageVariantCode: nil)
        }
    }()

    // Flag to be removed once language variants feature can be permanently turned on
    private static let languageVariantsEnabled = false
    @objc static let allLanguageVariantsByWikipediaLanguageCode: [String:[MWKLanguageLink]] = {
        guard languageVariantsEnabled else { return [:] }
        guard let languagesFileURL = Bundle.wmf.url(forResource: "wikipedia-language-variants", withExtension: "json") else {
            return [:]
        }
        do {
            let data = try Data(contentsOf: languagesFileURL)
            let entries = try JSONDecoder().decode([String : [WikipediaLanguageVariant]].self, from: data)
            return entries.mapValues { wikipediaLanguageVariants -> [MWKLanguageLink] in
                wikipediaLanguageVariants.map { wikipediaLanguageVariant in
                    // All language variant codes have compound codes. iOS returns a less descriptive localized name
                    // for those, so not attempting to get localized name from iOS.
                    MWKLanguageLink(languageCode: wikipediaLanguageVariant.languageCode, pageTitleText: "", name: wikipediaLanguageVariant.languageName, localizedName: wikipediaLanguageVariant.localName, languageVariantCode: wikipediaLanguageVariant.languageVariantCode)
                }
            }
        } catch let error {
            DDLogError("Error decoding language variant list \(error)")
            return [:]
        }
    }()
}
