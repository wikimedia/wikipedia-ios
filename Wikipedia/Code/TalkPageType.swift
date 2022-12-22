import Foundation

enum TalkPageType {
    case article
    case user
    
    var namespaceCodeStringForLogging: String {
        switch self {
        case .article: return String(PageNamespace.talk.rawValue)
        case .user: return String(PageNamespace.userTalk.rawValue)
        }
    }
}
