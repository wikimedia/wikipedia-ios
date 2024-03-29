import Foundation
import WKData

extension WKProject {
    var siteURL: URL? {
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
