extension TalkPageTopic {
    var isRead: Bool {
        get {
            return content?.isRead ?? false
        }
        set {
            content?.isRead = newValue
            relatedObjectsVersion += 1 // triggers an update of any NSFetchedResultsController observing this topic
        }
    }
}
