import Foundation

extension URL {
    static func mediaWikiAPIURL(project: WKProject) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.path = "/w/api.php"
        
        switch project {
        case .wikipedia(let language):
            components.host = "\(language.languageCode).wikipedia.org"
        case .commons:
            components.host = "commons.wikimedia.org"
        case .wikidata:
            components.host = "www.wikidata.org"
        }
        
        return components.url
    }
}
