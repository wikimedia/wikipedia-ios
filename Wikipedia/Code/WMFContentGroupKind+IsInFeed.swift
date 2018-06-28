extension WMFContentGroupKind {
    var isInFeed: Bool {
        return !SessionSingleton.sharedInstance().dataStore.feedContentController.languageCodes(for: self).isEmpty
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
}
