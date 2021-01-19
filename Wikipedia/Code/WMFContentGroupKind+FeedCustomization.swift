extension WMFContentGroupKind {
    var isInFeed: Bool {
        guard isGlobal else {
            return !feedContentController.contentLanguageCodes(for: self).isEmpty
        }
        return feedContentController.isGlobalContentGroupKind(inFeed: self)
    }

    var isCustomizable: Bool {
        return WMFExploreFeedContentController.customizableContentGroupKindNumbers().contains(NSNumber(value: rawValue))
    }

    var isGlobal: Bool {
        return WMFExploreFeedContentController.globalContentGroupKindNumbers().contains(NSNumber(value: rawValue))
    }

    var contentLanguageCodes: Array<String> {
        return feedContentController.contentLanguageCodes(for: self)
    }

    private var feedContentController: WMFExploreFeedContentController {
        return MWKDataStore.shared().feedContentController
    }
}
