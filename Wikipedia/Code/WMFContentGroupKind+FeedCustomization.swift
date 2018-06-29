extension WMFContentGroupKind {
    var isInFeed: Bool {
        guard isGlobal else {
            return !feedContentController.languageCodes(for: self).isEmpty
        }
        return feedContentController.isGlobalContentGroupKind(inFeed: self)
    }
    }

    var isGlobal: Bool {
        return WMFExploreFeedContentController.globalContentGroupKindNumbers().contains(NSNumber(value: rawValue))
    }

    var languageCodes: Set<String> {
        return feedContentController.languageCodes(for: self)
    }

    private var feedContentController: WMFExploreFeedContentController {
        return SessionSingleton.sharedInstance().dataStore.feedContentController
    }
}
