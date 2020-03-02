extension ArticleViewController: EventLoggingEventValuesProviding {
    var eventLoggingLabel: EventLoggingLabel? {
        return .outLink
    }
    
    var eventLoggingCategory: EventLoggingCategory {
        return .article
    }
}
