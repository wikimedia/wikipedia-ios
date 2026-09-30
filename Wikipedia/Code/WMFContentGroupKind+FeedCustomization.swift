extension WMFContentGroupKind {

    /// The card kinds that the Community feed settings screen can turn on and off, in the screen order.
    ///
    /// The Home tab's Community segment reads the same list to find if all the cards are hidden. The
    /// list does not include continue reading, related pages and suggested edits. That screen does not
    /// show those kinds, and they stay on.
    static let communityFeedCardKinds: [WMFContentGroupKind] = [.news, .onThisDay, .featuredArticle, .dailyGame, .topRead, .location, .random, .pictureOfTheDay]

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
    
    var isNonDateBased: Bool {
        return WMFExploreFeedContentController.nonDateBasedContentGroupKindNumbers().contains(NSNumber(value: rawValue))
    }

    var contentLanguageCodes: [String] {
        return feedContentController.contentLanguageCodes(for: self)
    }

    private var feedContentController: WMFExploreFeedContentController {
        return MWKDataStore.shared().feedContentController
    }
}
