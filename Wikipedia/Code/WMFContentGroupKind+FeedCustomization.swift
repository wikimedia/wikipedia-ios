extension WMFContentGroupKind {
    var isInFeed: Bool {
        guard isGlobal else {
            return !feedContentController.languageCodes(for: self).isEmpty
        }
        return feedContentController.isGlobalContentGroupKind(inFeed: self)
    }

    var isCustomizable: Bool {
        return WMFExploreFeedContentController.customizableContentGroupKindNumbers().contains(NSNumber(value: rawValue))
    }

    var isGlobal: Bool {
        return WMFExploreFeedContentController.globalContentGroupKindNumbers().contains(NSNumber(value: rawValue))
    }

    var languageCodes: Array<String> {
        return feedContentController.languageCodes(for: self)
    }

    private var feedContentController: WMFExploreFeedContentController {
        return MWKDataStore.shared().feedContentController
    }
}
