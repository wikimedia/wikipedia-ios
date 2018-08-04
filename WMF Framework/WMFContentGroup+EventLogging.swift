@objc public extension WMFContentGroup {
    public var eventLoggingLabel: EventLoggingLabel? {
        switch contentGroupKind {
        case .featuredArticle:
            return .featuredArticle
        case .topRead:
            return .topRead
        case .onThisDay:
            return .onThisDay
        case .random:
            return .random
        case .news:
            return .news
        case .relatedPages:
            return .relatedPages
        case .locationPlaceholder:
            fallthrough
        case .location:
            return .location
        case .mainPage:
            return .mainPage
        default:
            return nil
        }
    }
}

