import Foundation

public enum WMFProject: Equatable, Hashable, Identifiable, Codable, Sendable {
    
    case wikipedia(WMFLanguage)
    case wikidata
    case commons
    case mediawiki
    
    public var id: String {
        switch self {
        case .commons:
            return "commons"
        case .wikidata:
            return "wikidata"
        case .mediawiki:
            return "mediawiki"
        case .wikipedia(let language):
            var identifier = "wikipedia~\(language.languageCode)"
            if let variantCode = language.languageVariantCode {
                identifier.append("~\(variantCode)")
            }
            return identifier
        }
    }
    
    public static func == (lhs: WMFProject, rhs: WMFProject) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .wikipedia(let language):
            hasher.combine("wikipedia")
            hasher.combine(language.languageCode)
            hasher.combine(language.languageVariantCode)
        case .wikidata:
            hasher.combine("wikidata")
        case .commons:
            hasher.combine("commons")
        case .mediawiki:
            hasher.combine("mediawiki")
        }
    }
    
    init?(id: String) {
        switch id {
        case "commons":
            self = .commons
        case "wikidata":
            self = .wikidata
        default:
            // Expected format: wikipedia~languageCode or wikipedia~languageCode~variant
            let components = id.components(separatedBy: "~")
            guard components.count >= 2, components[0] == "wikipedia" else {
                return nil
            }
            
            let languageCode = components[1]
            let variantCode = components.count > 2 ? components[2] : nil
            let language = WMFLanguage(languageCode: languageCode, languageVariantCode: variantCode)
            self = .wikipedia(language)
        }
    }
    
    var languageVariantCode: String? {
        switch self {
        case .wikipedia(let language):
            return language.languageVariantCode
        default:
            break
        }
        
        return nil
    }
    
    public var languageCode: String? {
        switch self {
        case .wikipedia(let language):
            return language.languageCode
        default:
            break
        }
        
        return nil
    }
    
    static func projectsFromLanguages(languages: [WMFLanguage]) -> [WMFProject] {
        return languages.map { .wikipedia($0) }
    }
    
    public var isEnglishWikipedia: Bool {
        switch self {
        case .wikipedia(let language):
            return language.languageCode.lowercased() == "en"
        default:
            return false
        }
    }
    
    public var siteURL: URL? {
        var components = URLComponents()
        components.scheme = "https"

        switch self {
        case .wikipedia(let language):
            components.host = "\(language.languageCode).wikipedia.org"
        default:
            return nil
        }

        return components.url
    }
}
