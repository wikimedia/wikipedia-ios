import Foundation
import UIKit
import WMFNativeLocalizations

@MainActor
public final class WMFYearInReviewEndViewModel: ObservableObject {

    /// One card in the carousel. Each card has one button.
    public struct Card: Identifiable {
        public enum Action {
            case store
            case games
            case interests
            case topRead
            case whichWikipedia
        }

        public let id: String
        public let title: String
        public let body: String
        public let buttonTitle: String
        public let action: Action
        public let uppercaseLocale: Locale?

        init(id: String, title: String, body: String, buttonTitle: String, action: Action, uppercaseLocale: Locale? = nil) {
            self.id = id
            self.title = title
            self.body = body
            self.buttonTitle = buttonTitle
            self.action = action
            self.uppercaseLocale = uppercaseLocale
        }

        /// The title in capital letters, as the card shows it.
        public var uppercasedTitle: String {
            guard let uppercaseLocale else {
                return title.localizedUppercase
            }
            return title.uppercased(with: uppercaseLocale)
        }
    }

    // MARK: - Design colors

    /// From the Figma design. The dark end of the sky gradient. It continues below the sky, behind
    /// the whole page. Only the toolbar is black.
    public static let skyBottomColor = UIColor(red: 0.11, green: 0.13, blue: 0.24, alpha: 1)

    /// From the Figma design. The bottom of the gradient in the glow under the illustration. The top is white.
    public static let glowBottomColor = UIColor(red: 0.82, green: 0.82, blue: 0.82, alpha: 1)

    /// From Figma's elliptical gradient. `location` is 0 at the center of the ellipse and 1 at its edge.
    public static let skyGradientStops: [(color: UIColor, location: CGFloat)] = [
        (skyBottomColor, 0.15),
        (UIColor(red: 0.05, green: 0.15, blue: 0.32, alpha: 1), 0.27),
        (UIColor(red: 0, green: 0.6, blue: 0.85, alpha: 1), 0.59),
        (UIColor(red: 0.27, green: 0.83, blue: 0.94, alpha: 1), 0.78),
        (UIColor(red: 0.97, green: 0.98, blue: 0.98, alpha: 1), 1.0)
    ]

    /// The height of the sky, from Figma.
    public static let skyHeight: CGFloat = 372

    /// Where the ellipse is centered, as a fraction of the sky's width and height. Figma exports y as
    /// -0.02, which is the top. The design shows the dark end at the bottom and the light end at the
    /// top, so this puts the center at the bottom.
    public static let skyGradientCenter = CGPoint(x: 0.5, y: 1.02)

    /// How far the ellipse reaches from its center, as a fraction of the sky's width and height.
    /// Fitted to the design, where the bands are nearly flat across the screen with a slight dome.
    /// `EllipticalGradient` sizes its ellipse differently from Figma and came out far too narrow,
    /// so the sky draws a stretched circular gradient with these radii instead.
    public static let skyGradientRadius = CGSize(width: 2.66, height: 1.04)

    // MARK: - Localized strings

    /// The percent off the Wikipedia store for contributors. It matches the discount of the store link.
    private static let storeDiscount = 0.15

    public let headline = CommonStrings.yearInReviewOutroTitle
    public let body = CommonStrings.yearInReviewOutroSubtitle

    private let contributorGiftTitle = CommonStrings.yearInReviewStoreCardTitle
    private let contributorGiftBody = CommonStrings.yearInReviewStoreCardSubtitle(percent: NumberFormatter.localizedString(from: NSNumber(value: storeDiscount), number: .percent))
    private let contributorGiftButtonTitle = CommonStrings.yearInReviewStoreCardButtonTitle

    /// The most-read articles card only goes to readers with English as an app language, because
    /// it links to an English blog post. So its copy is in English and is not translated.
    private let topReadTitle = "2026's most-read articles"
    private let topReadBody = "Learn what everyone read about on Wikipedia this year. Did the World Cup make the list?"
    private let topReadButtonTitle = "Explore the top 25"

    private let gamesTitle = CommonStrings.yearInReviewGamesCardTitle
    private let gamesBody = CommonStrings.yearInReviewGamesCardSubtitle
    private let gamesButtonTitle = CommonStrings.yearInReviewGamesCardButtonTitle

    private let interestsTitle = CommonStrings.yearInReviewInterestsCardTitle
    private let interestsBody = CommonStrings.yearInReviewInterestsCardSubtitle
    private let interestsButtonTitle = CommonStrings.yearInReviewInterestsCardButtonTitle

    private let whichWikipediaTitle = CommonStrings.yearInReviewQuizCardTitle
    private let whichWikipediaBody = CommonStrings.yearInReviewQuizCardSubtitle
    private let whichWikipediaButtonTitle = CommonStrings.yearInReviewQuizCardButtonTitle

    // MARK: - State

    /// The cards in display order. The contributor gift card is only here for contributors, the
    /// games and interests cards are only here for group B of the end screen cards experiment
    /// (T441006), and the most-read articles card is only here for readers with English as an app
    /// language.
    public let cards: [Card]

    // MARK: - Callbacks

    public var didTapStore: (@MainActor @Sendable () -> Void)?
    public var didTapGames: (@MainActor @Sendable () -> Void)?
    public var didTapInterests: (@MainActor @Sendable () -> Void)?
    public var didTapTopRead: (@MainActor @Sendable () -> Void)?
    public var didTapWhichWikipedia: (@MainActor @Sendable () -> Void)?

    /// - Parameters:
    ///   - showsGamesCard: true for group B of the end screen cards experiment while the primary app
    ///     language has the game.
    ///   - showsInterestsCard: true for group B of the end screen cards experiment.
    public init(isContributor: Bool, hasEnglishAppLanguage: Bool = false, showsGamesCard: Bool = false, showsInterestsCard: Bool = false) {
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
        if showsGamesCard {
            cards.append(Card(
                id: "games",
                title: gamesTitle,
                body: gamesBody,
                buttonTitle: gamesButtonTitle,
                action: .games
            ))
        }
        if showsInterestsCard {
            cards.append(Card(
                id: "interests",
                title: interestsTitle,
                body: interestsBody,
                buttonTitle: interestsButtonTitle,
                action: .interests
            ))
        }
        if hasEnglishAppLanguage {
            cards.append(Card(
                id: "topRead",
                title: topReadTitle,
                body: topReadBody,
                buttonTitle: topReadButtonTitle,
                action: .topRead,
                uppercaseLocale: Locale(identifier: "en")
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
        case .games:
            didTapGames?()
        case .interests:
            didTapInterests?()
        case .topRead:
            didTapTopRead?()
        case .whichWikipedia:
            didTapWhichWikipedia?()
        }
    }
}
