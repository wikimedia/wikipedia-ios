import Foundation
import UIKit
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

    private let whichWikipediaTitle = CommonStrings.yearInReviewQuizCardTitle
    private let whichWikipediaBody = CommonStrings.yearInReviewQuizCardSubtitle
    private let whichWikipediaButtonTitle = CommonStrings.yearInReviewQuizCardButtonTitle

    // MARK: - State

    /// The cards in display order. The contributor gift card is only here for contributors.
    public let cards: [Card]

    // MARK: - Callbacks

    public var didTapStore: (@MainActor @Sendable () -> Void)?
    public var didTapWhichWikipedia: (@MainActor @Sendable () -> Void)?

    public init(isContributor: Bool) {
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
