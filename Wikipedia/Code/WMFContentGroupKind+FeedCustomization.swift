extension WMFContentGroupKind {
    var isInFeed: Bool {
        guard isGlobal else {
            return !feedContentController.languageCodes(for: self).isEmpty
        }
        return feedContentController.isGlobalContentGroupKind(inFeed: self)
    }
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
