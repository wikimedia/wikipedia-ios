extension ArticleViewController: MEPEventsProviding {
    var eventLoggingLabel: EventLabelMEP? {
        return .outLink
    }
    
    var eventLoggingCategory: EventCategoryMEP {
        return .article
    }
}
