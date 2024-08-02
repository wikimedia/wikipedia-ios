import Foundation

public enum WMFProject: Equatable, Hashable, Identifiable, Codable {
    public var id: String {
        switch self {
        case .commons:
            return "commons"
        case .wikidata:
            return "wikidata"
        case .wikipedia(let language):
            if let languageVariantCode = language.languageVariantCode {
                return "wikipedia-" + language.languageCode + "-" + languageVariantCode
            } else {
                return "wikipedia-" + language.languageCode
            }
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
        }
    }
    
    case wikipedia(WMFLanguage)
    case wikidata
    case commons
    
    static func projectsFromLanguages(languages: [WMFLanguage]) -> [WMFProject] {
        return languages.map { .wikipedia($0) }
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
}
