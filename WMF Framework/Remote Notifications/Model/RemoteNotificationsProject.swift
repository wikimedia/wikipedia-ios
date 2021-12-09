
import Foundation

public enum RemoteNotificationsProject: Hashable {
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
    
    public var inboxFiltersIconName: String? {
        switch self {
        case .commons:
            return "notifications-project-commons"
        case .wikidata:
            return "notifications-project-wikidata"
        default:
            return nil
        }
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
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(notificationsApiWikiIdentifier)
    }
    
    /// Returns formatted descriptive project name
    /// - Parameters:
    ///   - project: RemoteNotificationsProject that the notification is from
    ///   - shouldReturnCodedFormat: Boolean for if you want description in coded format for langauge projects ("EN-Wikipedia" vs  "English Wikipedia"). This is ignored for commons and wikidata projects.
    /// - Returns: Formatted descriptive project name
    public func projectName(shouldReturnCodedFormat: Bool) -> String {
        switch self {
        case .language(let languageCode, let localizedLanguageName, _):
            let format = WMFLocalizedString("notifications-center-language-project-name-format", value: "%1$@ %2$@", comment: "Format used for the ordering of language project name descriptions. This description is inserted into the header text of notifications in Notifications Center. For example, \"English Wikipedia\". Use this format to reorder these words if necessary or insert additional connecting words. Parameters: %1$@ = localized language name (\"English\"), %2$@ = localized name for Wikipedia (\"Wikipedia\")")

            if let localizedLanguageName = localizedLanguageName,
               !shouldReturnCodedFormat {
                return String.localizedStringWithFormat(format, localizedLanguageName, CommonStrings.plainWikipediaName)
            } else {
                let codedProjectName = "\(languageCode.localizedUppercase)-\(CommonStrings.plainWikipediaName)"
                return codedProjectName
            }
            
        case .commons:
            return WMFLocalizedString("notifications-center-commons-project-name", value: "Wikimedia Commons", comment: "Project name description for Wikimedia Commons, used in notification headers.")
        case .wikidata:
            return WMFLocalizedString("notifications-center-wikidata-project-name", value: "Wikidata", comment: "Project name description for Wikidata, used in notification headers.")
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

    /// Initializes RemoteNotificationProject with wiki identifier recognize by the MediaWiki Notifications API
    /// - Parameters:
    ///   - apiIdentifier: The API identifier used by the MediaWiki Notifications API. (e.g. "enwiki", "commonswiki", "wikidatawiki", etc.)
    ///   - languageLinkController: Include if you want to validate project against a list of languages that the app recognizes. If it isn't contained in languageLinkController's allLanguages property, instantiation fails. Including this also associates extra metadata to language enum associated value, like localizedName and languageVariantCode.
    public init?(apiIdentifier: String, languageLinkController: MWKLanguageLinkController? = nil) {
        
        switch apiIdentifier {
        case "commonswiki":
            self = .commons
        case "wikidatawiki":
            self = .wikidata
        default:
            
            let suffix = Self.languageIdentifierSuffix
            let strippedIdentifier = apiIdentifier.hasSuffix(suffix) ? String(apiIdentifier.dropLast(suffix.count)) : apiIdentifier
            
            guard let languageLinkController = languageLinkController else {
                self = .language(strippedIdentifier, nil, nil)
                return
            }
            
            //confirm it is a recognized language
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

extension RemoteNotificationsProject: Equatable {
    public static func ==(lhs: RemoteNotificationsProject, rhs: RemoteNotificationsProject) -> Bool {
        
        switch lhs {
        case .language(let lhsLanguageCode, _, _):
            switch rhs {
            case .language(let rhsLanguageCode, _, _):
                return lhsLanguageCode == rhsLanguageCode
            default:
                return false
        
            }
        case .commons:
            switch rhs {
            case .commons:
                return true
            default:
                return false
            }
        case .wikidata:
            switch rhs {
            case .wikidata:
                return true
            default:
                return false
            }
        }
    }
}
