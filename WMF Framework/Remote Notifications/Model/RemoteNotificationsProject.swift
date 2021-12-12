
import Foundation

public enum RemoteNotificationsProject {
    public typealias LanguageCode = String
    public typealias LocalizedLanguageName = String
    public typealias LanguageVariantCode = String
    public typealias APIIdentifier = String
    case wikipedia(LanguageCode, LocalizedLanguageName, LanguageVariantCode?)
    case commons
    case wikidata
    case other(APIIdentifier)
    
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
        case .wikipedia(let languageCode, _, _):
            return languageCode + Self.languageIdentifierSuffix
        case .commons:
            return Self.commonsIdentifier
        case .wikidata:
            return Self.wikidataIdentifier
        case .other(let apiIdentifier):
            return apiIdentifier
        }
    }
    
    public var languageVariantCode: String? {
        switch self {
        case .wikipedia(_, _, let languageVariantCode):
            return languageVariantCode
        default:
            return nil
        }
    }

    /// Initializes RemoteNotificationProject with wiki identifier recognize by the MediaWiki Notifications API
    /// - Parameters:
    ///   - apiIdentifier: The API identifier used by the MediaWiki Notifications API. (e.g. "enwiki", "commonswiki", "wikidatawiki", etc.)
    ///   - languageLinkController: Included to validate project against a list of languages that the app recognizes. This also associates extra metadata to language enum associated value, like localizedName and languageVariantCode.
    public init(apiIdentifier: String, languageLinkController: MWKLanguageLinkController) {
        
        switch apiIdentifier {
        case "commonswiki":
            self = .commons
        case "wikidatawiki":
            self = .wikidata
        default:
            
            let suffix = Self.languageIdentifierSuffix
            let strippedIdentifier = apiIdentifier.hasSuffix(suffix) ? String(apiIdentifier.dropLast(suffix.count)) : apiIdentifier
            
            //confirm it is a recognized language
            let recognizedLanguage = languageLinkController.allLanguages.first { languageLink in
                languageLink.languageCode == strippedIdentifier
            }
            
            if let recognizedLanguage = recognizedLanguage {
                self = .wikipedia(strippedIdentifier, recognizedLanguage.localizedName, recognizedLanguage.languageVariantCode)
            } else {
                self = .other(apiIdentifier)
            }
        }
    }
}
