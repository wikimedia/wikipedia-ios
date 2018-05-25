@objc public extension WMFContentGroup {
    public var eventLoggingLabel: EventLoggingLabel? {
        switch contentGroupKind {
        case .featuredArticle:
            return "featured_article"
        case .topRead:
            return "top_read"
        case .onThisDay:
            return "on_this_day"
        case .random:
            return "random"
        case .news:
            return "news"
        case .relatedPages:
            return "related_pages"
        case .locationPlaceholder:
            fallthrough
        case .location:
            return "location"
        case .mainPage:
            return "main_page"
        default:
            return nil
        }
    }
}

