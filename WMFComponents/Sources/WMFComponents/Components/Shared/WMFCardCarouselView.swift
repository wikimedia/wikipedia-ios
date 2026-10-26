import SwiftUI

/// A row of cards the reader swipes through from left to right.
/// It knows nothing about what a card looks like. The caller supplies each card.
public struct WMFCardCarouselView<Item: Identifiable, Card: View>: View {

    private let items: [Item]
    private let cardSpacing: CGFloat
    private let cardWidthFraction: CGFloat
    private let card: (Item) -> Card

    @Environment(\.accessibilityVoiceOverEnabled) private var isVoiceOverRunning

    /// - Parameters:
    ///   - cardWidthFraction: How much of the screen width one card takes. Less than 1 lets the next card peek in.
    public init(
        items: [Item],
        cardSpacing: CGFloat = 24,
        cardWidthFraction: CGFloat = 0.8,
        @ViewBuilder card: @escaping (Item) -> Card
    ) {
        self.items = items
        self.cardSpacing = cardSpacing
        self.cardWidthFraction = cardWidthFraction
        self.card = card
    }

    public var body: some View {
        // Each branch is a full carousel. Do not put a condition between the scroll view
        // and the stack that has scrollTargetLayout. WMFForYouView uses the same structure.
        if isVoiceOverRunning {
            // A lazy stack makes only the visible card and the next card. VoiceOver can only
            // move to a card that exists. Thus, while VoiceOver runs, make all the cards.
            carousel {
                HStack(alignment: .top, spacing: cardSpacing) {
                    cards
                }
                .scrollTargetLayout()
            }
        } else {
            carousel {
                LazyHStack(alignment: .top, spacing: cardSpacing) {
                    cards
                }
                .scrollTargetLayout()
            }
        }
    }

    @ViewBuilder
    private var cards: some View {
        ForEach(items) { item in
            card(item)
                .containerRelativeFrame(.horizontal) { width, _ in
                    width * cardWidthFraction
                }
        }
    }

    private func carousel<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            content()
        }
        .scrollTargetBehavior(.viewAligned)
        .contentMargins(.horizontal, cardSpacing, for: .scrollContent)
    }
}
