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
        
        enum CodingKeys: String, CodingKey {
            case action = "action"
            case pageID = "page_id"
            case wikiID = "wiki_db"
        }
    }
   
    private func logEvent(action: ArticleLinkInteractionFunnel.Action, pageID: Int, project: WikimediaProject) {
        
        let wikiID = project.notificationsApiWikiIdentifier
        
        let event: ArticleLinkInteractionFunnel.Event = ArticleLinkInteractionFunnel.Event(action: action, pageID: pageID, wikiID: wikiID)
        EventPlatformClient.shared.submit(stream: .articleLinkInteraction, event: event)
    }
    
    func logArticleView(pageID: Int, project: WikimediaProject) {
        logEvent(action: .navigate, pageID: pageID, project: project)
    }
}

