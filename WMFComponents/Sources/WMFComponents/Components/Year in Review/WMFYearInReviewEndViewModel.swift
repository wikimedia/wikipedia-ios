import Foundation
import WMFNativeLocalizations

@MainActor
public final class WMFYearInReviewEndViewModel: ObservableObject {

    /// One card in the carousel. Each card has one button.
    public struct Card: Identifiable {
        public enum Action {
            case store
            case whichWikipedia
        }

        public let id: String
        public let title: String
        public let body: String
        public let buttonTitle: String
        public let action: Action
    }

    // MARK: - Localized strings

    public let headline = WMFLocalizedString("year-in-review-2026-end-headline", value: "Until the next rabbit hole", comment: "Headline of the last Year in Review screen.")
    public let body = WMFLocalizedString("year-in-review-2026-end-body", value: "Whether you came for one article or one hundred, thanks for exploring, reading, and staying curious with us on Wikipedia.", comment: "Body text of the last Year in Review screen.")
    public let shareHighlightsButtonTitle = WMFLocalizedString("year-in-review-2026-end-share-highlights", value: "Share highlights", comment: "Button on the last Year in Review screen that shares the reader's highlights.")

    private let contributorGiftTitle = WMFLocalizedString("year-in-review-2026-end-contributor-gift-title", value: "A small thank-you", comment: "Title of the Year in Review end screen card that thanks contributors with a store discount.")
    private let contributorGiftBody = WMFLocalizedString("year-in-review-2026-end-contributor-gift-body", value: "Because you help keep knowledge free, we're giving you 15% off the Wikipedia store. No code needed, it's applied at checkout.", comment: "Body of the Year in Review end screen card that thanks contributors with a store discount.")
    private let contributorGiftButtonTitle = WMFLocalizedString("year-in-review-2026-end-contributor-gift-button", value: "Visit the store", comment: "Button on the Year in Review end screen card that opens the Wikipedia store.")

    private let whichWikipediaTitle = WMFLocalizedString("year-in-review-2026-end-which-wikipedia-title", value: "Which Wikipedia are you?", comment: "Title of the Year in Review end screen card that opens a quiz about Wikipedia's history.")
    private let whichWikipediaBody = WMFLocalizedString("year-in-review-2026-end-which-wikipedia-body", value: "From dial-up days to now, travel through Wikipedia's history.", comment: "Body of the Year in Review end screen card that opens a quiz about Wikipedia's history.")
    private let whichWikipediaButtonTitle = WMFLocalizedString("year-in-review-2026-end-which-wikipedia-button", value: "Take the quiz", comment: "Button on the Year in Review end screen card that opens a quiz about Wikipedia's history.")

    // MARK: - State

    /// `false` for readers who saw the collective slides. They do not get the share button.
    public let showsShareHighlights: Bool

    /// The cards in display order. The contributor gift card is only here for contributors.
    public let cards: [Card]

    // MARK: - Callbacks

    public var didTapShareHighlights: (() -> Void)?
    public var didTapStore: (() -> Void)?
    public var didTapWhichWikipedia: (() -> Void)?

    public init(
        isContributor: Bool,
        showsShareHighlights: Bool
    ) {
        self.showsShareHighlights = showsShareHighlights

        var cards: [Card] = []
        if isContributor {
            cards.append(Card(
                id: "contributorGift",
                title: contributorGiftTitle,
                body: contributorGiftBody,
                buttonTitle: contributorGiftButtonTitle,
                action: .store
            ))
        }
        cards.append(Card(
            id: "whichWikipedia",
            title: whichWikipediaTitle,
            body: whichWikipediaBody,
            buttonTitle: whichWikipediaButtonTitle,
            action: .whichWikipedia
        ))
        self.cards = cards
    }

    // MARK: - Actions

    public func didTap(_ card: Card) {
        switch card.action {
        case .store:
            didTapStore?()
        case .whichWikipedia:
            didTapWhichWikipedia?()
        }
    }
}
