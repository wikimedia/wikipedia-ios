
import Foundation

public enum RemoteNotificationsProject {
    public typealias LanguageCode = String
    public typealias LocalizedLanguageName = String
    public typealias LanguageVariantCode = String
    case wikipedia(LanguageCode, LocalizedLanguageName, LanguageVariantCode?)
    case wikibooks(LanguageCode, LocalizedLanguageName)
    case wiktionary(LanguageCode, LocalizedLanguageName)
    case wikiquote(LanguageCode, LocalizedLanguageName)
    case wikimedia(LanguageCode, LocalizedLanguageName)
    case wikisource(LanguageCode, LocalizedLanguageName)
    case wikinews(LanguageCode, LocalizedLanguageName)
    case wikiversity(LanguageCode, LocalizedLanguageName)
    case wikivoyage(LanguageCode, LocalizedLanguageName)
    case commons
    case wikidata
    
    private static var commonsIdentifier: String {
        return "commonswiki"
    }

    private static var wikidataIdentifier: String {
        return "wikidatawiki"
    }
    
    private static var wikipediaLanguageSuffix: String {
        return "wiki"
    }
    
    private static var wikibooksLanguageSuffix: String {
        return "wikibooks"
    }
    
    private static var wiktionaryLanguageSuffix: String {
        return "wiktionary"
    }
    
    private static var wikiquoteLanguageSuffix: String {
        return "wikiquote"
    }
    
    private static var wikimediaLanguageSuffix: String {
        return "wikimedia"
    }
    
    private static var wikisourceLanguageSuffix: String {
        return "wiksource"
    }
    
    private static var wikinewsLanguageSuffix: String {
        return "wikinews"
    }
    
    private static var wikiversityLanguageSuffix: String {
        return "wikiversity"
    }
    
    private static var wikivoyageLanguageSuffix: String {
        return "wikivoyage"
    }

    var notificationsApiWikiIdentifier: String {
        switch self {
        case .wikipedia(let languageCode, _, _):
            return languageCode + Self.wikipediaLanguageSuffix
        case .commons:
            return Self.commonsIdentifier
        case .wikidata:
            return Self.wikidataIdentifier
        case .wikibooks(let languageCode, _):
            return languageCode + Self.wikibooksLanguageSuffix
        case .wiktionary(let languageCode, _):
            return languageCode + Self.wiktionaryLanguageSuffix
        case .wikiquote(let languageCode, _):
            return languageCode + Self.wikiquoteLanguageSuffix
        case .wikimedia(let languageCode, _):
            return languageCode + Self.wikimediaLanguageSuffix
        case .wikisource(let languageCode, _):
            return languageCode + Self.wikisourceLanguageSuffix
        case .wikinews(let languageCode, _):
            return languageCode + Self.wikinewsLanguageSuffix
        case .wikiversity(let languageCode, _):
            return languageCode + Self.wikiversityLanguageSuffix
        case .wikivoyage(let languageCode, _):
            return languageCode + Self.wikivoyageLanguageSuffix
        }
    }
    
    public var projectName: String {
        
        //TODO: This would be better as a generated mapping file that pulled from the project translations here - https://translatewiki.net/w/i.php?title=Special:Translate&group=ext-wikimediaprojectnames&filter=&optional=0&action=page&language=en
        
        switch self {
        case .wikipedia(_, _, _):
            return CommonStrings.plainWikipediaName
        case .wikibooks(_, _):
            return "Wikibooks"
        case .wiktionary(_, _):
            return "Wiktionary"
        case .wikiquote(_, _):
            return "Wikiquote"
        case .wikimedia(_, _):
            return "Wikimedia"
        case .wikisource(_, _):
            return "Wikisource"
        case .wikinews(_, _):
            return "Wikinews"
        case .wikiversity(_, _):
            return "Wikiversity"
        case .wikivoyage(_, _):
            return "Wikivoyage"
        case .commons:
            return "Wikimedia Commons"
        case .wikidata:
            return "Wikidata"
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
    
    func mediaWikiAPIURL(configuration: Configuration, queryParameters: RemoteNotificationsAPIController.Query.Parameters?) -> URL? {
        
        let createStandardURLBlock: (String, String) -> URL? = { (languageCode, projectDomain) in
            let host = "\(languageCode).\(projectDomain).org"
            var components = URLComponents()
            components.host = host
            return components.url
        }
        
        switch self {
        case .commons:
            return configuration.commonsAPIURLComponents(with: queryParameters).url
        case .wikidata:
            return configuration.wikidataAPIURLComponents(with: queryParameters).url
        case .wikipedia(let languageCode, _, _):
            return configuration.mediaWikiAPIURLForLanguageCode(languageCode, with: queryParameters).url
        case .wikibooks(let languageCode, _):
            return createStandardURLBlock(languageCode, Self.wikibooksLanguageSuffix)
        case .wiktionary(let languageCode, _):
            return createStandardURLBlock(languageCode, Self.wiktionaryLanguageSuffix)
        case .wikiquote(let languageCode, _):
            return createStandardURLBlock(languageCode, Self.wikiquoteLanguageSuffix)
        case .wikimedia(let languageCode, _):
            return createStandardURLBlock(languageCode, Self.wikimediaLanguageSuffix)
        case .wikisource(let languageCode, _):
            return createStandardURLBlock(languageCode, Self.wikisourceLanguageSuffix)
        case .wikinews(let languageCode, _):
            return createStandardURLBlock(languageCode, Self.wikinewsLanguageSuffix)
        case .wikiversity(let languageCode, _):
            return createStandardURLBlock(languageCode, Self.wikiversityLanguageSuffix)
        case .wikivoyage(let languageCode, _):
            return createStandardURLBlock(languageCode, Self.wikivoyageLanguageSuffix)
        }
    }
    
    private static func projectForLanguageSuffix(suffix: String, language: MWKLanguageLink?) -> RemoteNotificationsProject? {
        
        guard let language = language else {
            return nil
        }
        
        switch suffix {
        case Self.wikipediaLanguageSuffix:
            return .wikipedia(language.languageCode, language.localizedName, language.languageVariantCode)
        case Self.wikibooksLanguageSuffix:
            return .wikibooks(language.languageCode, language.localizedName)
        case Self.wiktionaryLanguageSuffix:
            return .wiktionary(language.languageCode, language.localizedName)
        case Self.wikiquoteLanguageSuffix:
            return .wikiquote(language.languageCode, language.localizedName)
        case Self.wikimediaLanguageSuffix:
            return .wikimedia(language.languageCode, language.localizedName)
        case Self.wikisourceLanguageSuffix:
            return .wikisource(language.languageCode, language.localizedName)
        case Self.wikinewsLanguageSuffix:
            return .wikinews(language.languageCode, language.localizedName)
        case Self.wikiversityLanguageSuffix:
            return .wikiversity(language.languageCode, language.localizedName)
        case Self.wikivoyageLanguageSuffix:
            return .wikivoyage(language.languageCode, language.localizedName)
        default:
            return nil
        }
    }

    /// Initializes RemoteNotificationProject with wiki identifier recognize by the MediaWiki Notifications API
    /// - Parameters:
    ///   - apiIdentifier: The API identifier used by the MediaWiki Notifications API. (e.g. "enwiki", "commonswiki", "wikidatawiki", etc.)
    ///   - languageLinkController: Included to validate project against a list of languages that the app recognizes. This also associates extra metadata to language enum associated value, like localizedName and languageVariantCode.
    public init?(apiIdentifier: String, languageLinkController: MWKLanguageLinkController) {
        
        switch apiIdentifier {
        case Self.commonsIdentifier:
            self = .commons
        case Self.wikidataIdentifier:
            self = .wikidata
        default:
            
            let suffixes = [Self.wikibooksLanguageSuffix, Self.wiktionaryLanguageSuffix, Self.wikiquoteLanguageSuffix, Self.wikimediaLanguageSuffix, Self.wikisourceLanguageSuffix, Self.wikinewsLanguageSuffix, Self.wikiversityLanguageSuffix, Self.wikivoyageLanguageSuffix]
            
            var project: RemoteNotificationsProject?
            for suffix in suffixes {
                let strippedIdentifier = apiIdentifier.hasSuffix(suffix) ? String(apiIdentifier.dropLast(suffix.count)) : apiIdentifier
                
                //confirm it is a recognized language
                let recognizedLanguage = languageLinkController.allLanguages.first { languageLink in
                    languageLink.languageCode == strippedIdentifier
                }
                
                project = Self.projectForLanguageSuffix(suffix: suffix, language: recognizedLanguage)
                
                if project != nil {
                    break
                }
            }
            
            guard let project = project else {
                return nil
            }
            
            self = project
        }
    }
}
