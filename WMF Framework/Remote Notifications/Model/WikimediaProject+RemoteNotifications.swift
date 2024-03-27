import Foundation

extension WikimediaProject {
    
    private static var commonsIdentifier: String {
        return "commonswiki"
    }

    private static var wikidataIdentifier: String {
        return "wikidatawiki"
    }
    
    private static var mediawikiIdentifier: String {
        return "mediawikiwiki"
    }
    
    private static var wikispeciesIdentifier: String {
        return "specieswiki"
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
        return "wikisource"
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

    public var notificationsApiWikiIdentifier: String {
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
        case .wikisource(let languageCode, _):
            return languageCode + Self.wikisourceLanguageSuffix
        case .wikinews(let languageCode, _):
            return languageCode + Self.wikinewsLanguageSuffix
        case .wikiversity(let languageCode, _):
            return languageCode + Self.wikiversityLanguageSuffix
        case .wikivoyage(let languageCode, _):
            return languageCode + Self.wikivoyageLanguageSuffix
        case .mediawiki:
            return Self.mediawikiIdentifier
        case .wikispecies:
            return Self.wikispeciesIdentifier
        }
    }
    
    private var projectName: String {
        
        // TODO: This would be better as a generated mapping file from translatewiki's project translations (for example: https://translatewiki.net/wiki/Special:ExportTranslations?group=ext-wikimediaprojectnames&language=he&format=export-to-file)
        // See https://phabricator.wikimedia.org/T297620
        
        switch self {
        case .wikipedia:
            return CommonStrings.plainWikipediaName
        case .wikibooks:
            return WMFLocalizedString("project-name-wikibooks", value:"Wikibooks", comment: "Project name for Wikibooks.")
        case .wiktionary:
            return WMFLocalizedString("project-name-wiktionary", value:"Wiktionary", comment: "Project name for Wiktionary.")
        case .wikiquote:
            return WMFLocalizedString("project-name-wikiquote", value:"Wikiquote", comment: "Project name for Wikiquote.")
        case .wikisource:
            return WMFLocalizedString("project-name-wikisource", value:"Wikisource", comment: "Project name for Wikisource.")
        case .wikinews:
            return WMFLocalizedString("project-name-wikinews", value:"Wikinews", comment: "Project name for Wikinews.")
        case .wikiversity:
            return WMFLocalizedString("project-name-wikiversity", value:"Wikiversity", comment: "Project name for Wikiversity.")
        case .wikivoyage:
            return WMFLocalizedString("project-name-wikivoyage", value:"Wikivoyage", comment: "Project name for Wikivoyage.")
        case .commons:
            return WMFLocalizedString("project-name-wikimedia-commons", value:"Wikimedia Commons", comment: "Project name for Wikimedia Commons.")
        case .wikidata:
            return WMFLocalizedString("project-name-wikidata", value:"Wikidata", comment: "Project name for Wikidata.")
        case .mediawiki:
            return WMFLocalizedString("project-name-mediawiki", value:"MediaWiki", comment: "Project name for MediaWiki.")
        case .wikispecies:
            return WMFLocalizedString("project-name-wikispecies", value:"Wikispecies", comment: "Project name for Wikispecies.")
        }
    }
    
    /// Returns formatted descriptive project name
    /// - Parameters:
    ///   - shouldReturnCodedFormat: Boolean for if you want description in coded format for langauge projects ("EN-Wikipedia" vs  "English Wikipedia"). This is ignored for commons and wikidata projects.
    /// - Returns: Formatted descriptive project name
    public func projectName(shouldReturnCodedFormat: Bool) -> String {
        
        let createLanguageProjectNameBlock: (String, String, String, Bool) -> String = { (languageCode, localizedLanguageName, projectName, shouldReturnCodedFormat) in
            
            let format = WMFLocalizedString("notifications-center-language-project-name-format", value: "%1$@ %2$@", comment: "Format used for the ordering of language project name descriptions. This description is inserted into the header text of notifications in Notifications Center. For example, \"English Wikipedia\". Use this format to reorder these words if necessary or insert additional connecting words. Parameters: %1$@ = localized language name (\"English\"), %2$@ = localized name for Wikipedia (\"Wikipedia\")")

            if !shouldReturnCodedFormat {
                return String.localizedStringWithFormat(format, localizedLanguageName, projectName)
            } else {
                let codedProjectName = "\(languageCode.localizedUppercase)-\(projectName)"
                return codedProjectName
            }
            
        }
        
        switch self {
        case .wikipedia(let languageCode, let localizedLanguageName, _):
            return createLanguageProjectNameBlock(languageCode, localizedLanguageName, projectName, shouldReturnCodedFormat)
        case .commons:
            return projectName
        case .wikidata:
            return projectName
        case .wikibooks(let languageCode, let localizedLanguageName):
            return createLanguageProjectNameBlock(languageCode, localizedLanguageName, projectName, shouldReturnCodedFormat)
        case .wiktionary(let languageCode, let localizedLanguageName):
            return createLanguageProjectNameBlock(languageCode, localizedLanguageName, projectName, shouldReturnCodedFormat)
        case .wikiquote(let languageCode, let localizedLanguageName):
            return createLanguageProjectNameBlock(languageCode, localizedLanguageName, projectName, shouldReturnCodedFormat)
        case .wikisource(let languageCode, let localizedLanguageName):
            return createLanguageProjectNameBlock(languageCode, localizedLanguageName, projectName, shouldReturnCodedFormat)
        case .wikinews(let languageCode, let localizedLanguageName):
            return createLanguageProjectNameBlock(languageCode, localizedLanguageName, projectName, shouldReturnCodedFormat)
        case .wikiversity(let languageCode, let localizedLanguageName):
            return createLanguageProjectNameBlock(languageCode, localizedLanguageName, projectName, shouldReturnCodedFormat)
        case .wikivoyage(let languageCode, let localizedLanguageName):
            return createLanguageProjectNameBlock(languageCode, localizedLanguageName, projectName, shouldReturnCodedFormat)
        case .mediawiki:
            return projectName
        case .wikispecies:
            return projectName
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
    
    public func mediaWikiAPIURL(configuration: Configuration) -> URL? {
        return mediaWikiAPIURL(configuration: configuration, queryParameters: nil)
    }

    func mediaWikiAPIURL(configuration: Configuration, queryParameters: RemoteNotificationsAPIController.Query.Parameters?) -> URL? {

        switch self {
        case .commons:
            return configuration.commonsAPIURLComponents(with: queryParameters).url
        case .wikidata:
            return configuration.wikidataAPIURLComponents(with: queryParameters).url
        case .wikipedia(let languageCode, _, _):
            return configuration.mediaWikiAPIURLForLanguageCode(languageCode, queryParameters: queryParameters).url
        case .wikibooks(let languageCode, _):
            return configuration.mediaWikiAPIURLForLanguageCode(languageCode, siteDomain: Configuration.Domain.wikibooks, queryParameters: queryParameters).url
        case .wiktionary(let languageCode, _):
            return configuration.mediaWikiAPIURLForLanguageCode(languageCode, siteDomain: Configuration.Domain.wiktionary, queryParameters: queryParameters).url
        case .wikiquote(let languageCode, _):
            return configuration.mediaWikiAPIURLForLanguageCode(languageCode, siteDomain: Configuration.Domain.wikiquote, queryParameters: queryParameters).url
        case .wikisource(let languageCode, _):
            return configuration.mediaWikiAPIURLForLanguageCode(languageCode, siteDomain: Configuration.Domain.wikisource, queryParameters: queryParameters).url
        case .wikinews(let languageCode, _):
            return configuration.mediaWikiAPIURLForLanguageCode(languageCode, siteDomain: Configuration.Domain.wikinews, queryParameters: queryParameters).url
        case .wikiversity(let languageCode, _):
            return configuration.mediaWikiAPIURLForLanguageCode(languageCode, siteDomain: Configuration.Domain.wikiversity, queryParameters: queryParameters).url
        case .wikivoyage(let languageCode, _):
            return configuration.mediaWikiAPIURLForLanguageCode(languageCode, siteDomain: Configuration.Domain.wikivoyage, queryParameters: queryParameters).url
        case .mediawiki:
            return configuration.mediaWikiAPIURLForHost(Configuration.Domain.mediaWiki, with: queryParameters).url
        case .wikispecies:
            return configuration.mediaWikiAPIURLForHost(Configuration.Domain.wikispecies, with: queryParameters).url
        }
    }
    
    private static func projectForLanguageSuffix(suffix: String, language: MWKLanguageLink?) -> WikimediaProject? {
        
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

    /// Initializes WikimediaProject with wiki identifier recognize by the MediaWiki Notifications API
    /// - Parameters:
    ///   - notificationsApiIdentifier: The API identifier used by the MediaWiki Notifications API. (e.g. "enwiki", "commonswiki", "wikidatawiki", etc.)
    ///   - languageLinkController: Included to validate project against a list of languages that the app recognizes. This also associates extra metadata to language enum associated value, like localizedName and languageVariantCode.
    public init?(notificationsApiIdentifier: String, languageLinkController: MWKLanguageLinkController? = nil) {
        
        switch notificationsApiIdentifier {
        case Self.commonsIdentifier:
            self = .commons
        case Self.wikidataIdentifier:
            self = .wikidata
        case Self.wikispeciesIdentifier:
            self = .wikispecies
        case Self.mediawikiIdentifier:
            self = .mediawiki
        default:
            
            let suffixes = [Self.wikipediaLanguageSuffix, Self.wikibooksLanguageSuffix, Self.wiktionaryLanguageSuffix, Self.wikiquoteLanguageSuffix, Self.wikimediaLanguageSuffix, Self.wikisourceLanguageSuffix, Self.wikinewsLanguageSuffix, Self.wikiversityLanguageSuffix, Self.wikivoyageLanguageSuffix]
            
            var project: WikimediaProject?
            for suffix in suffixes {
                let strippedIdentifier = notificationsApiIdentifier.hasSuffix(suffix) ? String(notificationsApiIdentifier.dropLast(suffix.count)) : notificationsApiIdentifier
                
                var language: MWKLanguageLink?
                // first try to map to app preferred languages
                // Note: This allows us to prefer a particular selected language variant for notificationsApiIdentifier 'zhwiki'
                language = languageLinkController?.preferredLanguages.first { languageLink in
                    languageLink.languageCode == strippedIdentifier
                }
                
                // then fall back to any language recognized by the app
                if language == nil {
                    language = languageLinkController?.allLanguages.first { languageLink in
                        languageLink.languageCode == strippedIdentifier
                    }
                }
                
                project = Self.projectForLanguageSuffix(suffix: suffix, language: language)
                
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
