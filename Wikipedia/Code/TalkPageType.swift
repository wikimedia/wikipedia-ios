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

    func canonicalNamespacePrefix(for siteURL: URL) -> String? {
        let namespace: PageNamespace
        switch self {
        case .article:
            namespace = PageNamespace.talk
        case .user:
            namespace = PageNamespace.userTalk
        }
        return namespace.canonicalName + ":"
    }

    func titleWithCanonicalNamespacePrefix(title: String, siteURL: URL) -> String {
        return (canonicalNamespacePrefix(for: siteURL) ?? "") + title
    }

}
