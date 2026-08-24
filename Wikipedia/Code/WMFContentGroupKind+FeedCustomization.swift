extension WMFContentGroupKind {

    /// The card kinds the Community feed settings screen lets the reader turn on and off, in the
    /// order the screen lists them.
    ///
    /// Also the set the Home tab's Community segment checks to decide whether every card is hidden,
    /// so the two stay in step. The global kinds that screen leaves out (continue reading, related
    /// pages, suggested edits) are deliberately absent: they are on by default and not the reader's
    /// to turn off here.
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
