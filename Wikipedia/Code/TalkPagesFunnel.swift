import Foundation

final class TalkPagesFunnel {
   
    public static let shared = TalkPagesFunnel()
    
    private enum Action: String, Codable {
        case openTopic = "open_topic"
        case newTopicClick = "new_topic_click"
        case replyClick = "reply_click"
        case refresh
        case langChange = "lang_change"
        case submit
        case contributions = "overflow_contributions"
    }
    
    private enum Source: String, Codable {
        case talkPage = "talk_page"
        case talkPageArchives = "talk_page_archives"
        case article
        case notificationsCenter = "notifications_center"
        case deepLink = "deep_link"
        case account
        case search
        case inAppWebView = "in_app_web_view"
        case watchlist
        case unknown
        case profile

        init(routingSource: RoutingUserInfoSourceValue) {
            switch routingSource {
            case .talkPage: self = .talkPage
            case .talkPageArchives: self = .talkPageArchives
            case .article: self = .article
            case .notificationsCenter: self = .notificationsCenter
            case .deepLink: self = .deepLink
            case .account: self = .account
            case .search: self = .search
            case .inAppWebView: self = .inAppWebView
            case .watchlist: self = .watchlist
            case .unknown: self = .unknown
            case .profile: self = .profile
            }
        }
    }
    
    private struct Event: EventInterface {
        static let schema: EventPlatformClient.Schema = .talkPages
        let action: Action
        let source: Source
        let page_ns: String
        let time_spent: Int
        let wiki_id: String
    }
   
    private func logEvent(action: TalkPagesFunnel.Action, routingSource: RoutingUserInfoSourceValue, project: WikimediaProject, talkPageType: TalkPageType, lastViewDidAppearDate: Date) {
        
        let source = Source(routingSource: routingSource)
        let wikiID = project.notificationsApiWikiIdentifier
        let timeSpent = -(lastViewDidAppearDate.timeIntervalSinceNow)

        let event: TalkPagesFunnel.Event = TalkPagesFunnel.Event(action: action, source: source, page_ns: talkPageType.namespaceCodeStringForLogging, time_spent: Int(timeSpent), wiki_id: wikiID)
        EventPlatformClient.shared.submit(stream: .talkPagesInteraction, event: event)
    }
    
    public func logExpandedTopic(routingSource: RoutingUserInfoSourceValue, project: WikimediaProject, talkPageType: TalkPageType, lastViewDidAppearDate: Date) {
        logEvent(action: .openTopic, routingSource: routingSource, project: project, talkPageType: talkPageType, lastViewDidAppearDate: lastViewDidAppearDate)
    }
    
    public func logTappedNewTopic(routingSource: RoutingUserInfoSourceValue, project: WikimediaProject, talkPageType: TalkPageType, lastViewDidAppearDate: Date) {
        logEvent(action: .newTopicClick, routingSource: routingSource, project: project, talkPageType: talkPageType, lastViewDidAppearDate: lastViewDidAppearDate)
    }
    
    public func logTappedInlineReply(routingSource: RoutingUserInfoSourceValue, project: WikimediaProject, talkPageType: TalkPageType, lastViewDidAppearDate: Date) {
        logEvent(action: .replyClick, routingSource: routingSource, project: project, talkPageType: talkPageType, lastViewDidAppearDate: lastViewDidAppearDate)
    }
    
    // Note: Pull to refresh is not implemented in the UI yet
    public func logPulledToRefresh(routingSource: RoutingUserInfoSourceValue, project: WikimediaProject, talkPageType: TalkPageType, lastViewDidAppearDate: Date) {
        logEvent(action: .refresh, routingSource: routingSource, project: project, talkPageType: talkPageType, lastViewDidAppearDate: lastViewDidAppearDate)
    }
    
    public func logChangedLanguage(routingSource: RoutingUserInfoSourceValue, project: WikimediaProject, talkPageType: TalkPageType, lastViewDidAppearDate: Date) {
        logEvent(action: .langChange, routingSource: routingSource, project: project, talkPageType: talkPageType, lastViewDidAppearDate: lastViewDidAppearDate)
    }
    
    public func logTappedPublishNewTopicOrInlineReply(routingSource: RoutingUserInfoSourceValue, project: WikimediaProject, talkPageType: TalkPageType, lastViewDidAppearDate: Date) {
        logEvent(action: .submit, routingSource: routingSource, project: project, talkPageType: talkPageType, lastViewDidAppearDate: lastViewDidAppearDate)
    }

    public func logTappedContributions(routingSource: RoutingUserInfoSourceValue, project: WikimediaProject, talkPageType: TalkPageType, lastViewDidAppearDate: Date) {
        logEvent(action: .contributions, routingSource: routingSource, project: project, talkPageType: talkPageType, lastViewDidAppearDate: lastViewDidAppearDate)
    }
}
