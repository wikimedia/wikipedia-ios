
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
