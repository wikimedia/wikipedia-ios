extension WMFContentGroupKind {
    var isInFeed: Bool {
        return !SessionSingleton.sharedInstance().dataStore.feedContentController.languageCodes(for: self).isEmpty
    }

    var isCustomizable: Bool {
        let contentGroupKindNumber = NSNumber(value: self.rawValue)
        return WMFExploreFeedContentController.customizableContentGroupKindNumbers().contains(contentGroupKindNumber)
    }

    var isGlobal: Bool {
        switch self {
        case .relatedPages:
            fallthrough
        case .continueReading:
            fallthrough
        case .pictureOfTheDay:
            return true
        default:
            return false
        }
    }

    var languageCodes: Set<String> {
        return SessionSingleton.sharedInstance().dataStore.feedContentController.languageCodes(for: self)
    }
}
