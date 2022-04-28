import Foundation
import WMF

enum NotificationsCenterAction: Hashable {
    case markAsReadOrUnread(NotificationsCenterActionData)
    case custom(NotificationsCenterActionData)
    case notificationSubscriptionSettings(NotificationsCenterActionData)

    var actionData: NotificationsCenterActionData? {
        switch self {
        case .notificationSubscriptionSettings(let data), .markAsReadOrUnread(let data), .custom(let data):
            return data
        }
    }
}

struct NotificationsCenterActionData: Hashable {
    let text: String
    let url: URL?
    let iconType: NotificationsCenterIconType?
    let destinationText: String?
    let actionType: LoggingLabel?
    
    public enum LoggingLabel: Hashable {
        case markRead
        case markUnread
        case userTalk
        case senderPage
        case diff
        case articleTalk
        case article
        case wikidataItem
        case listGroupRights
        case linkedFromArticle
        case settings
        case gettingStarted
        case login
        case changePassword
        case linkNonspecific
        case link(PageNamespace)
        
        var stringValue: String {
            switch self {
            case .markRead: return "mark_read"
            case .markUnread: return "mark_unread"
            case .userTalk: return "user_talk"
            case .senderPage: return "sender_page"
            case .diff: return "diff"
            case .articleTalk: return "article_talk"
            case .article: return "article"
            case .wikidataItem: return "wikidata_item"
            case .listGroupRights: return "list_group_rights"
            case .linkedFromArticle: return "linked_from_article"
            case .settings: return "settings"
            case .gettingStarted: return "getting_started"
            case .login: return "login_notification"
            case .changePassword: return "change_password"
            case .linkNonspecific: return "link_nonspecific"
            case .link(let namespace):
                return "link_\(namespace.stringValue)"
            }
        }
    }
}

private extension PageNamespace {
    var stringValue: String {
        switch self {
        case .media: return "media"
        case .special: return "special"
        case .main: return "main"
        case .talk: return "talk"
        case .user: return "user"
        case .userTalk: return "userTalk"
        case .wikipedia: return "wikipedia"
        case .wikipediaTalk: return "wikipediaTalk"
        case .file: return "file"
        case .fileTalk: return "fileTalk"
        case .mediawiki: return "mediawiki"
        case .mediawikiTalk: return "mediawikiTalk"
        case .template: return "template"
        case .templateTalk: return "templateTalk"
        case .help: return "help"
        case .helpTalk: return "helpTalk"
        case .category: return "category"
        case .cateogryTalk: return "cateogryTalk"
        case .thread: return "thread"
        case .threadTalk: return "threadTalk"
        case .summary: return "summary"
        case .summaryTalk: return "summaryTalk"
        case .portal: return "portal"
        case .portalTalk: return "portalTalk"
        case .project: return "project"
        case .projectTalk: return "projectTalk"
        case .book: return "book"
        case .bookTalk: return "bookTalk"
        case .draft: return "draft"
        case .draftTalk: return "draftTalk"
        case .educationProgram: return "educationProgram"
        case .educationProgramTalk: return "educationProgramTalk"
        case .campaign: return "campaign"
        case .campaignTalk: return "campaignTalk"
        case .timedText: return "timedText"
        case .timedTextTalk: return "timedTextTalk"
        case .module: return "module"
        case .moduleTalk: return "moduleTalk"
        case .gadget: return "gadget"
        case .gadgetTalk: return "gadgetTalk"
        case .gadgetDefinition: return "gadgetDefinition"
        case .gadgetDefinitionTalk: return "gadgetDefinitionTalk"
        case .topic: return "topic"
        }
    }
}
