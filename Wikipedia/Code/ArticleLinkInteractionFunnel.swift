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
    
    func logArticleView(pageID: Int, project: WikimediaProject) {
        logEvent(action: .navigate, pageID: pageID, project: project)
    }

    func logArticleImpression(pageID: Int, project: WikimediaProject, source: ArticleSource) {
        ///Undefined is a temporary property we're using before we add all sources to the app. No need to log undefined as it is not expected by the backend. This can be removed when all sources are logged.
        guard source != .undefined else { return }

        logEvent(action: .navigate, pageID: pageID, project: project, source: source.rawValue)
    }
}

