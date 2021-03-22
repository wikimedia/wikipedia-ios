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
                
                if let iOSLocalizedName = Locale.current.localizedString(forLanguageCode: wikipedia.languageCode) {
                    localizedName = iOSLocalizedName
                }
            } else if !Locale.current.isEnglish {
                if let iOSLocalizedName = Locale.current.localizedString(forIdentifier: wikipedia.languageCode) {
                    localizedName = iOSLocalizedName
                }
            }
            return MWKLanguageLink(languageCode: wikipedia.languageCode, pageTitleText: "", name: wikipedia.languageName, localizedName: localizedName, languageVariantCode: nil, altISOCode: wikipedia.altISOCode)
        }
    }()

    // Flag to be removed once language variants feature can be permanently turned on
    @objc public static let languageVariantsEnabled = true
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
 
                    var localizedName = wikipediaLanguageVariant.localName
                    if !Locale.current.isEnglish,
                        let iOSLocalizedName = Locale.current.localizedString(forIdentifier: wikipediaLanguageVariant.languageVariantCode) {
                        localizedName = iOSLocalizedName
                    }
                    
                    return MWKLanguageLink(languageCode: wikipediaLanguageVariant.languageCode, pageTitleText: "", name: wikipediaLanguageVariant.languageName, localizedName: localizedName, languageVariantCode: wikipediaLanguageVariant.languageVariantCode, altISOCode: wikipediaLanguageVariant.languageVariantCode)
                }
            }
        } catch let error {
            DDLogError("Error decoding language variant list \(error)")
            return [:]
        }
    }()
}
