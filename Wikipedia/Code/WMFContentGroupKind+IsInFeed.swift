extension WMFContentGroupKind {
    var isInFeed: Bool {
        return !SessionSingleton.sharedInstance().dataStore.feedContentController.languageCodes(for: self).isEmpty
    }
}
