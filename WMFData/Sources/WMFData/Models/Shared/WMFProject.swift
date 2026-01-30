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
    
    public init?(id: String) {
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
    
    public var languageVariantCode: String? {
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
        case .commons:
            components.host = "commons.wikimedia.org"
        case .wikidata:
            components.host = "www.wikidata.org"
        case .mediawiki:
            components.host = "www.mediawiki.org"
        }

        return components.url
    }
    
    public var isRTL: Bool {
        switch self {
        case .wikipedia(let language):
            return language.isRTL
        default:
            return false
        }
    }
    
    
    /// Helper method to generate help or FAQ URLs for in-app web views.
    /// - Parameters:
    ///   - pathComponents: path components, starting wtih page title. Include namespace in page title if non-main. E.g.  ["Wikimedia Apps","Team","iOS","Personalized Wikipedia Year in Review", "How your data is used"]
    ///   - section: anchor tag to scroll to upon load (generally section name) e.g. "Editing". # will be added automatically.
    ///   - language: Language translation to request, will be added as ?uselang={languageCode} query item
    /// - Returns: Url to load in web view.
    public func translatedHelpURL(pathComponents: [String], section: String?, language: WMFLanguage) -> URL? {
        
        guard let siteURL = self.siteURL else {
            return nil
        }
        
        guard var components = URLComponents(url: siteURL, resolvingAgainstBaseURL: false) else {
            return nil
        }
        
        let normalizedPathComponents = pathComponents.map { $0.replacingOccurrences(of: " ", with: "_") }
        let normalizedSection = section?.replacingOccurrences(of: " ", with: "_")
        
        components.path = "/" + (["wiki", "Special:MyLanguage"] + normalizedPathComponents).joined(separator: "/")
        components.fragment = normalizedSection
        components.queryItems = [URLQueryItem(name: "uselang", value: language.languageCode)]
        
        return components.url
    }
}
