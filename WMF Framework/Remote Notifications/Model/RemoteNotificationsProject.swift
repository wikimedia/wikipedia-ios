
import Foundation

public enum RemoteNotificationsProject {
    public typealias LanguageCode = String
    public typealias LocalizedLanguageName = String
    public typealias LanguageVariantCode = String
    case language(LanguageCode, LocalizedLanguageName?, LanguageVariantCode?)
    case commons
    case wikidata
    
    private static var commonsIdentifier: String {
        return "commonswiki"
    }

    private static var wikidataIdentifier: String {
        return "wikidatawiki"
    }

    private static var languageIdentifierSuffix: String {
        return "wiki"
    }

    var notificationsApiWikiIdentifier: String {
        switch self {
        case .language(let languageCode, _, _):
            return languageCode + Self.languageIdentifierSuffix
        case .commons:
            return Self.commonsIdentifier
        case .wikidata:
            return Self.wikidataIdentifier
        }
    }
    
    public var languageVariantCode: String? {
        switch self {
        case .language(_, _, let languageVariantCode):
            return languageVariantCode
        default:
            return nil
        }
    }
    
    public init?(apiIdentifier: String?, languageLinkController: MWKLanguageLinkController) {
        
        guard let apiIdentifier = apiIdentifier else {
            return nil
        }
        
        switch apiIdentifier {
        case "commonswiki":
            self = .commons
        case "wikidatawiki":
            self = .wikidata
        default:
            //confirm it is a recognized language
            let suffix = Self.languageIdentifierSuffix
            let strippedIdentifier = apiIdentifier.hasSuffix(suffix) ? String(apiIdentifier.dropLast(suffix.count)) : apiIdentifier
            let recognizedLanguage = languageLinkController.allLanguages.first { languageLink in
                languageLink.languageCode == strippedIdentifier
            }
            
            if let recognizedLanguage = recognizedLanguage {
                self = .language(strippedIdentifier, recognizedLanguage.localizedName, recognizedLanguage.languageVariantCode)
            } else {
                return nil
            }
        }
    }
}
