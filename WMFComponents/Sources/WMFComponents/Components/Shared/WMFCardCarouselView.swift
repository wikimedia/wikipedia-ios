import SwiftUI

/// A row of cards the reader swipes through from left to right.
/// It knows nothing about what a card looks like. The caller supplies each card.
public struct WMFCardCarouselView<Item: Identifiable, Card: View>: View {

    private let items: [Item]
    private let cardSpacing: CGFloat
    private let cardWidthFraction: CGFloat
    private let card: (Item) -> Card

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
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: cardSpacing) {
                ForEach(items) { item in
                    card(item)
                        .containerRelativeFrame(.horizontal) { width, _ in
                            width * cardWidthFraction
                        }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .contentMargins(.horizontal, cardSpacing, for: .scrollContent)
    }
}
