extension WMFContentGroupKind {
    var isInFeed: Bool {
        return !SessionSingleton.sharedInstance().dataStore.feedContentController.languageCodes(for: self).isEmpty
    }

    var isCustomizable: Bool {
        let contentGroupKindNumber = NSNumber(value: self.rawValue)
        return WMFExploreFeedContentController.customizableContentGroupKindNumbers().contains(contentGroupKindNumber)
    }
}
