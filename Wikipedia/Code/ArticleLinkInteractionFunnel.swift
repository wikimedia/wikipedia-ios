import Foundation
import WMF

final class ArticleLinkInteractionFunnel {
   
    static let shared = ArticleLinkInteractionFunnel()
    
    private enum Action: String, Codable {
        case navigate = "navigate"
    }
    
    private struct Event: EventInterface {
        static let schema: EventPlatformClient.Schema = .articleLinkInteraction
        let action: Action
        let pageID: Int
        let wikiID: String
        let source: Int?

        enum CodingKeys: String, CodingKey {
            case action = "action"
            case pageID = "page_id"
            case wikiID = "wiki_db"
            case source
        }
    }
   
    private func logEvent(action: ArticleLinkInteractionFunnel.Action, pageID: Int, project: WikimediaProject, source: Int? = nil) {

        let wikiID = project.notificationsApiWikiIdentifier
        
        let event: ArticleLinkInteractionFunnel.Event = ArticleLinkInteractionFunnel.Event(action: action, pageID: pageID, wikiID: wikiID, source: source)
        EventPlatformClient.shared.submit(stream: .articleLinkInteraction, event: event)
    }
    
    func logArticleView(pageID: Int, project: WikimediaProject, source: ArticleSource? = nil) {
        // Avoid sending 0 to backend. It doesn't throw an error, but is unexpected
        let loggingSource = source == .undefined ? nil : source?.rawValue
        logEvent(action: .navigate, pageID: pageID, project: project, source: loggingSource)
    }
}

@objc
public enum ArticleSource: Int {
    case undefined = 0 // temporary
    case search = 1
    case internal_link = 2
    case external_link = 3
    case history = 4
    case activity = 45 
    case places = 9
}

public struct ArticleSourceUserInfoKeys {
    static let articleSource = "articleSource"
}
