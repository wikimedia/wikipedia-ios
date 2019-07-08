// https://en.wikipedia.org/wiki/Wikipedia:Namespace
@objc public enum PageNamespace: Int {
    case main
    case talk
    case user
    case userTalk
    case project
    case projectTalk
    case file
    case fileTalk
}

extension PageNamespace {
    init?(namespaceValue: Int?) {
        guard let rawValue = namespaceValue else {
            return nil
        }
        self.init(rawValue: rawValue)
    }
}

extension WMFArticle {
    public var pageNamespace: PageNamespace? {
        return PageNamespace(namespaceValue: ns?.intValue)
    }
}

extension MWKSearchResult {
    public var pageNamespace: PageNamespace? {
        return PageNamespace(namespaceValue: titleNamespace?.intValue)
    }
}
