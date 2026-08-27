import Foundation
import WMFNativeLocalizations

/// The final page of the For You feed. It tells the reader they have seen everything in today's
/// digest and offers two ways forward: adding interests and visiting the Community tab.
///
/// Until the Random article module ships, this card is also the empty state shown when the feed
/// has no personalized content at all (no interests and no reading history). It is not shown when
/// the reader has content but turned every module off - that case keeps the settings empty state.
@MainActor
public final class WMFForYouEndOfFeedCardViewModel: ObservableObject, Identifiable {

    /// Identity of the end of feed page in the vertical paging layout, alongside the module page IDs.
    public let id = UUID()

    /// Which copy, illustration, and analytics identity the card has. Set once per feed by
    /// `WMFForYouViewModel`: a feed with no pages at all is the empty feed; otherwise the card
    /// is the last page of the feed.
    public enum Variant {
        case endOfFeed
        case emptyFeed
    }

    public var variant: Variant = .endOfFeed

    /// Sent as `actionSource` on this card's events.
    public var loggingId: String {
        switch variant {
        case .endOfFeed: return "end_of_feed"
        case .emptyFeed: return "feed_empty"
        }
    }

    // MARK: - Localized strings

    let title = WMFLocalizedString("for-you-end-of-feed-title", value: "That's it for today!", comment: "Heading on the card shown at the end of the For You feed, telling the reader they have seen all of today's recommendations.")

    let subtitle = WMFLocalizedString("for-you-end-of-feed-subtitle", value: "Come back tomorrow to find fresh new articles customized for you.", comment: "Message on the card shown at the end of the For You feed, encouraging the reader to return the next day for new content.")

    let waysToKeepLearningTitle = WMFLocalizedString("for-you-end-of-feed-ways-to-keep-learning", value: "Ways to keep learning:", comment: "Label above the list of suggested actions on the card at the end of the For You feed.")

    /// The sentence around the add interests link. %1$@ is filled with the underlined link text.
    let addInterestsFormat = WMFLocalizedString("for-you-end-of-feed-add-interests-format", value: "Add %1$@", comment: "Suggested action on the card at the end of the For You feed. %1$@ is replaced with the tappable link text that opens the interests settings screen, e.g. \"new interests\".")

    /// The underlined, tappable part of the add interests sentence.
    let addInterestsLinkText = WMFLocalizedString("for-you-end-of-feed-add-interests-link", value: "new interests", comment: "Tappable link text within the add interests suggestion on the card at the end of the For You feed. It opens the interests settings screen.")

    /// The sentence around the community link. %1$@ is filled with the underlined link text.
    let communityFormat = WMFLocalizedString("for-you-end-of-feed-community-format", value: "See what's happening in %1$@", comment: "Suggested action on the card at the end of the For You feed. %1$@ is replaced with the tappable link text that switches to the Community tab, e.g. \"community\".")

    /// The underlined, tappable part of the community sentence.
    let communityLinkText = WMFLocalizedString("for-you-end-of-feed-community-link", value: "community", comment: "Tappable link text within the community suggestion on the card at the end of the For You feed. It switches the reader to the Community tab.")
    
    let emptyTitle = WMFLocalizedString("for-you-empty-feed-title", value: "Your feed is empty for now", comment: "Heading on the For You feed empty state, shown when there is no personalized content yet.")

    let emptySubtitle = WMFLocalizedString("for-you-empty-feed-subtitle", value: "Your \"For you\" feed will populate with personalized articles as you explore.", comment: "Message on the For You feed empty state, explaining the feed fills with personalized articles as the reader uses the app.")

    let waysToGetStartedTitle = WMFLocalizedString("for-you-empty-feed-ways-to-get-started", value: "Ways to get started:", comment: "Label above the list of suggested actions on the For You feed empty state.")

    let emptyAddInterestsLinkText = WMFLocalizedString("for-you-empty-feed-add-interests-link", value: "some interests", comment: "Tappable link text within the add interests suggestion on the For You feed empty state. It opens the interests settings screen.")

    // MARK: - Actions

    /// Opens the interests settings screen.
    public var onTapAddInterests: (() -> Void)?

    /// Switches the reader to the Community tab.
    public var onTapCommunity: (() -> Void)?

    /// Called the first time the card fills the screen for this feed. The flag lives here rather
    /// than in `WMFHomeViewModel` because a refresh builds a new `WMFForYouViewModel`, and with it
    /// a new end of feed card, so the impression naturally logs once per feed.
    public var onShow: (() -> Void)?

    private var hasReportedShow = false

    func reportShownIfNeeded() {
        guard !hasReportedShow else { return }
        hasReportedShow = true
        onShow?()
    }

    public init() {}
}
