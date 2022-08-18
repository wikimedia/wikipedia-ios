import Foundation

public enum WikimediaProject: Hashable {
    public typealias LanguageCode = String
    public typealias LocalizedLanguageName = String
    public typealias LanguageVariantCode = String
    case wikipedia(LanguageCode, LocalizedLanguageName, LanguageVariantCode?)
    case wikibooks(LanguageCode, LocalizedLanguageName)
    case wiktionary(LanguageCode, LocalizedLanguageName)
    case wikiquote(LanguageCode, LocalizedLanguageName)
    case wikisource(LanguageCode, LocalizedLanguageName)
    case wikinews(LanguageCode, LocalizedLanguageName)
    case wikiversity(LanguageCode, LocalizedLanguageName)
    case wikivoyage(LanguageCode, LocalizedLanguageName)
    case mediawiki
    case wikispecies
    case commons
    case wikidata
    
    public var projectIconName: String? {
        switch self {
        case .commons:
            return "wikimedia-project-commons"
        case .wikidata:
            return "wikimedia-project-wikidata"
        case .wikiquote:
            return "wikimedia-project-wikiquote"
        case .wikipedia:
            return nil
        case .wikibooks:
            return "wikimedia-project-wikibooks"
        case .wiktionary:
            return "wikimedia-project-wiktionary"
        case .wikisource:
            return "wikimedia-project-wikisource"
        case .wikinews:
            return "wikimedia-project-wikinews"
        case .wikiversity:
            return "wikimedia-project-wikiversity"
        case .wikivoyage:
            return "wikimedia-project-wikivoyage"
        case .mediawiki:
            return "wikimedia-project-mediawiki"
        case .wikispecies:
            return "wikimedia-project-wikispecies"
        }
    }
}
