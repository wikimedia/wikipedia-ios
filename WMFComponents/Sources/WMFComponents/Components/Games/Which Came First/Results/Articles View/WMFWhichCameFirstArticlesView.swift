import SwiftUI
import UIKit
import WMFData

/// A grid of article cards displayed after the user completes a Which Came First game.
/// Each card mirrors the visual style of the Article Tabs grid: thumbnail image on top,
/// article title, a short divider, and the event date below.
public struct WMFWhichCameFirstArticlesView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFWhichCameFirstArticlesViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// Tracks each card's global frame so share sheets can be anchored correctly.
    @State private var cellFrames: [UUID: CGRect] = [:]

    private var theme: WMFTheme { appEnvironment.theme }

    /// Number of columns adapts to device size class (iPad = 3, iPhone = 2).
    private var columnCount: Int {
        horizontalSizeClass == .regular ? 3 : 2
    }

    public init(viewModel: WMFWhichCameFirstArticlesViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.localizedStrings.sectionTitle)
                .font(Font(WMFFont.for(.semiboldHeadline)))
                .foregroundStyle(Color(uiColor: theme.text))

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: columnCount),
                spacing: 16
            ) {
                ForEach(viewModel.articleItems) { item in
                    ArticleCardMenuWrapper(item: item, viewModel: viewModel, theme: theme)
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .preference(
                                        key: ArticleCardFramePreferenceKey.self,
                                        value: [item.id: geo.frame(in: .global)]
                                    )
                            }
                        )
                }
            }
            .onPreferenceChange(ArticleCardFramePreferenceKey.self) { updates in
                cellFrames.merge(updates, uniquingKeysWith: { _, new in new })
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color(uiColor: theme.midBackground))
    }
}

// MARK: - Card + context menu wrapper

/// A wrapper view that observes a single article item so that the context menu label
/// (Save / Unsave) and icon react correctly when `item.isSaved` changes.
private struct ArticleCardMenuWrapper: View {

    @ObservedObject var item: WMFWhichCameFirstArticleItemViewModel
    @ObservedObject var viewModel: WMFWhichCameFirstArticlesViewModel
    let theme: WMFTheme

    var body: some View {
        WMFWhichCameFirstArticleCardView(item: item, theme: theme)
            .aspectRatio(3 / 4, contentMode: .fit)
            .contextMenu {
                Button {
                    if let url = item.articleURL { viewModel.didTapArticle?(url) }
                } label: {
                    Text(viewModel.localizedStrings.openArticleTitle)
                    Image(uiImage: WMFSFSymbolIcon.for(symbol: .chevronForward) ?? UIImage())
                }
                .labelStyle(.titleAndIcon)

                Button {
                    if let url = item.articleURL { viewModel.didTapOpenInNewTab?(url) }
                } label: {
                    Text(viewModel.localizedStrings.openInNewTabTitle)
                    Image(uiImage: WMFSFSymbolIcon.for(symbol: .tabsIcon) ?? UIImage())
                }
                .labelStyle(.titleAndIcon)

                Button {
                    if let url = item.articleURL { viewModel.didTapOpenInBackgroundTab?(url) }
                } label: {
                    Text(viewModel.localizedStrings.openInBackgroundTabTitle)
                    Image(uiImage: WMFSFSymbolIcon.for(symbol: .tabsIconBackground) ?? UIImage())
                }
                .labelStyle(.titleAndIcon)

                Button {
                    viewModel.toggleSave(for: item)
                } label: {
                    Text(item.isSaved ? viewModel.localizedStrings.unsaveTitle : viewModel.localizedStrings.saveForLaterTitle)
                    Image(uiImage: WMFSFSymbolIcon.for(symbol: item.isSaved ? .bookmarkFill : .bookmark) ?? UIImage())
                }
                .labelStyle(.titleAndIcon)

                Button {
                    if let url = item.articleURL { viewModel.didShareArticle?(url) }
                } label: {
                    Text(viewModel.localizedStrings.shareArticleTitle)
                    Image(uiImage: WMFSFSymbolIcon.for(symbol: .share) ?? UIImage())
                }
                .labelStyle(.titleAndIcon)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(item.title)
            .accessibilityActions {
                accessibilityAction(named: viewModel.localizedStrings.openArticleTitle) {
                    if let url = item.articleURL { viewModel.didTapArticle?(url) }
                }
                accessibilityAction(named: viewModel.localizedStrings.openInNewTabTitle) {
                    if let url = item.articleURL { viewModel.didTapOpenInNewTab?(url) }
                }
                accessibilityAction(named: viewModel.localizedStrings.openInBackgroundTabTitle) {
                    if let url = item.articleURL { viewModel.didTapOpenInBackgroundTab?(url) }
                }
                accessibilityAction(named: item.isSaved ? viewModel.localizedStrings.unsaveTitle : viewModel.localizedStrings.saveForLaterTitle) {
                    viewModel.toggleSave(for: item)
                }
                accessibilityAction(named: viewModel.localizedStrings.shareArticleTitle) {
                    if let url = item.articleURL { viewModel.didShareArticle?(url) }
                }
            }
            .onTapGesture {
                if let url = item.articleURL { viewModel.didTapArticle?(url) }
            }
    }
}

// MARK: - Frame preference key

private struct ArticleCardFramePreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]
    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

// MARK: - Card

/// A single article card styled to match the Article Tabs grid cards.
private struct WMFWhichCameFirstArticleCardView: View {

    @ObservedObject var item: WMFWhichCameFirstArticleItemViewModel
    let theme: WMFTheme

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// Image height mirrors the values used in WMFArticleTabsViewContent.
    private var imageHeight: CGFloat {
        horizontalSizeClass == .regular ? 110 : 95
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail
            thumbnailArea

            // Title (up to 2 lines)
            Text(item.title)
                .font(Font(WMFFont.for(.georgiaCallout)))
                .foregroundStyle(Color(uiColor: theme.text))
                .lineLimit(2)
                .padding(.horizontal, 10)
                .padding(.top, 10)
                .padding(.bottom, 4)

            // Description / summary snippet (up to 3 lines)
            if let snippet = item.snippetText {
                Text(snippet)
                    .font(Font(WMFFont.for(.caption1)))
                    .foregroundStyle(Color(uiColor: theme.secondaryText))
                    .lineLimit(3)
                    .lineSpacing(1.4)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 8)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(uiColor: theme.chromeBackground))
        .cornerRadius(12)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .inset(by: 0.5)
                .stroke(Color.clear, lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.05), radius: 16, x: 0, y: 0)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var thumbnailArea: some View {
        if let data = item.thumbnailImageData, let uiImage = UIImage(data: data) {
            // Image loaded successfully.
            GeometryReader { geo in
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: imageHeight)
                    .clipped()
            }
            .frame(height: imageHeight)
        } else if item.hasThumbnailURL {
            // URL exists but image hasn't loaded yet – show a loading placeholder.
            Color(uiColor: theme.midBackground)
                .frame(height: imageHeight)
                .overlay(ProgressView().scaleEffect(0.7))
        }
        // No thumbnail URL at all → no image area is rendered.
    }
}
// MARK: - Preview

#Preview {
    let strings = WMFWhichCameFirstArticlesViewModel.LocalizedStrings(
        sectionTitle: "Articles from today's game",
        openArticleTitle: "Open article",
        shareArticleTitle: "Share",
        articleTapAccessibility: "Open article"
    )

    let project = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))
    let items: [WMFWhichCameFirstArticleItemViewModel] = [
        WMFWhichCameFirstArticleItemViewModel(
            title: "Moon landing",
            apiTitle: "Moon_landing",
            project: project,
            articleURL: nil,
            thumbnailURL: nil
        ),
        WMFWhichCameFirstArticleItemViewModel(
            title: "World Wide Web",
            apiTitle: "World_Wide_Web",
            project: project,
            articleURL: nil,
            thumbnailURL: nil
        ),
        WMFWhichCameFirstArticleItemViewModel(
            title: "Berlin Wall",
            apiTitle: "Berlin_Wall",
            project: project,
            articleURL: nil,
            thumbnailURL: nil
        ),
        WMFWhichCameFirstArticleItemViewModel(
            title: "DNA double helix",
            apiTitle: "DNA",
            project: project,
            articleURL: nil,
            thumbnailURL: nil
        )
    ]

    let viewModel = WMFWhichCameFirstArticlesViewModel(
        articleItems: items,
        localizedStrings: strings
    )

    ScrollView {
        WMFWhichCameFirstArticlesView(viewModel: viewModel)
            .padding(.vertical, 16)
    }
    .background(Color(.systemGroupedBackground))
}

