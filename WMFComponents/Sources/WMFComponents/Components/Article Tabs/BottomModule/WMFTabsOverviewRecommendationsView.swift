import SwiftUI
import WMFData
import UIKit

@MainActor
public struct WMFTabsOverviewRecommendationsView: View {

    let viewModel: WMFTabsOverviewRecommendationsViewModel
    private let horizontalInset: CGFloat = 16
    private let interCardSpacing: CGFloat
    private let topSpacing: CGFloat

    public init(
        interCardSpacing: CGFloat = 12,
        topSpacing: CGFloat = 16,
        viewModel: WMFTabsOverviewRecommendationsViewModel
    ) {
        self.interCardSpacing = interCardSpacing
        self.topSpacing = topSpacing
        self.viewModel = viewModel
    }

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    private var theme: WMFTheme { appEnvironment.theme }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(viewModel.title)
                .font(WMFSwiftUIFont.font(.mediumSubheadline))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .foregroundStyle(Color(theme.text))
                .padding(.horizontal, horizontalInset)
                .padding(.top, topSpacing)
                .padding(.bottom, 8)
            GeometryReader { geo in
                ScrollContainer(
                    interCardSpacing: interCardSpacing,
                    horizontalInset: horizontalInset,
                    viewModel: viewModel
                )
            }
        }
        .background(Color(theme.midBackground))
    }
}

// MARK: - Internals

@MainActor
private struct ScrollContainer: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    private var theme: WMFTheme { appEnvironment.theme }
    let cardWidth: CGFloat = 234
    let interCardSpacing: CGFloat
    let horizontalInset: CGFloat
    let viewModel: WMFTabsOverviewRecommendationsViewModel

    var body: some View {
        if #available(iOS 17.0, *) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: interCardSpacing) {
                    ForEach(viewModel.getItems()) { item in
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
                    ForEach(viewModel.getItems()) { item in
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
    @Environment(\.sizeCategory) var sizeCategory: ContentSizeCategory

    var lineLimit: Int {
        sizeCategory > .large ? 2 : 1
    }

    var body: some View {
        Button(action: { viewModel.onTap(item) }) {
            WMFPageRow(
                id: item.id,
                titleHtml: item.titleHtml,
                articleDescription: item.description,
                imageURLString: item.imageURLString,
                titleLineLimit: lineLimit,
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
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(theme.paperBackground))
                    .shadow(color: Color.black.opacity(0.10), radius: 10, x: 0, y: 4)
                    .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}
