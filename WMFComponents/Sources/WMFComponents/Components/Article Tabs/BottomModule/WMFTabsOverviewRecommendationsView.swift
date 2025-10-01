import SwiftUI
import WMFData
import UIKit

@MainActor
public struct WMFTabsOverviewRecommendationsView: View {

    let viewModel: WMFTabsOverviewRecommendationsViewModel

    private let title: String
    private let items: [HistoryItem]
    private let horizontalInset: CGFloat
    private let cardWidth: CGFloat?
    private let interCardSpacing: CGFloat
    private let topSpacing: CGFloat

    public init(
        title: String,
        items: [HistoryItem],
        horizontalInset: CGFloat = 16,
        cardWidth: CGFloat? = nil,
        interCardSpacing: CGFloat = 12,
        topSpacing: CGFloat = 8,
        viewModel: WMFTabsOverviewRecommendationsViewModel
    ) {
        self.title = title
        self.items = items
        self.horizontalInset = horizontalInset
        self.cardWidth = cardWidth
        self.interCardSpacing = interCardSpacing
        self.topSpacing = topSpacing
        self.viewModel = viewModel
    }

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    private var theme: WMFTheme { appEnvironment.theme }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title
            Text(title)
                .font(Font(WMFFont.for(.boldHeadline)))
                .foregroundStyle(Color(theme.text))
                .padding(.horizontal, horizontalInset)
                .padding(.bottom, topSpacing)
                .accessibilityAddTraits(.isHeader)

            // Strip
            GeometryReader { geo in
                let availableWidth = geo.size.width - (horizontalInset * 2)
                let targetWidth = cardWidth ?? max(260, min(340, availableWidth * (availableWidth > 600 ? 0.36 : 0.44)))

                ScrollContainer(
                    items: items,
                    cardWidth: targetWidth,
                    interCardSpacing: interCardSpacing,
                    horizontalInset: horizontalInset,
                    viewModel: viewModel
                )
            }
            .frame(height: calculatedStripHeight)
        }
        .background(Color(theme.paperBackground))
    }

    private var calculatedStripHeight: CGFloat { 120 }
}

// MARK: - Internals

@MainActor
private struct ScrollContainer: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    private var theme: WMFTheme { appEnvironment.theme }
    let items: [HistoryItem]
    let cardWidth: CGFloat
    let interCardSpacing: CGFloat
    let horizontalInset: CGFloat
    let viewModel: WMFTabsOverviewRecommendationsViewModel

    var body: some View {
        if #available(iOS 17.0, *) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: interCardSpacing) {
                    ForEach(items) { item in
                        Card(item: item, viewModel: viewModel)
                            .frame(width: cardWidth)
                            .scrollTargetLayout()
                    }
                }
                .padding(.horizontal, horizontalInset)
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
            .contentMargins(.horizontal, 0, for: .scrollContent)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: interCardSpacing) {
                    ForEach(items) { item in
                        Card(item: item, viewModel: viewModel)
                            .frame(width: cardWidth)
                    }
                }
                .padding(.horizontal, horizontalInset)
            }
        }
    }
}

@MainActor
private struct Card: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    private var theme: WMFTheme { appEnvironment.theme }
    let item: HistoryItem
    let viewModel: WMFTabsOverviewRecommendationsViewModel

    var body: some View {
        Button(action: { viewModel.onTap(item) }) {
            WMFPageRow(
                id: item.id,
                titleHtml: item.titleHtml,
                articleDescription: item.description,
                imageURLString: item.imageURLString,
                isSaved: item.isSaved,
                deleteAccessibilityLabel: "",
                shareAccessibilityLabel: "",
                saveAccessibilityLabel: "",
                unsaveAccessibilityLabel: "",
                showsSwipeActions: false,
                deleteItemAction: nil,
                shareItemAction: nil,
                saveOrUnsaveItemAction: nil,
                loadImageAction: { imageURLString in
                    return try? await viewModel.loadImage(imageURLString: imageURLString)
                }
            )
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(theme.midBackground))
                    .shadow(color: Color.black.opacity(0.10), radius: 10, x: 0, y: 4)
                    .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}
