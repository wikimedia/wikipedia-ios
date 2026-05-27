import SwiftUI
import UIKit

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
                    WMFWhichCameFirstArticleCardView(item: item, theme: theme)
                        .aspectRatio(3 / 4, contentMode: .fit)
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .preference(
                                        key: ArticleCardFramePreferenceKey.self,
                                        value: [item.id: geo.frame(in: .global)]
                                    )
                            }
                        )
                        .contextMenu(menuItems: {
                            Button {
                                if let url = item.articleURL {
                                    viewModel.didTapArticle?(url)
                                }
                            } label: {
                                Text(viewModel.localizedStrings.openArticleTitle)
                                Image(uiImage: WMFSFSymbolIcon.for(symbol: .chevronForward) ?? UIImage())
                            }

                            Button {
                                if let url = item.articleURL {
                                    viewModel.didShareArticle?(url)
                                }
                            } label: {
                                Text(viewModel.localizedStrings.shareArticleTitle)
                                Image(uiImage: WMFSFSymbolIcon.for(symbol: .share) ?? UIImage())
                            }
                        }, preview: {
                            WMFArticlePreviewView(viewModel: WMFArticlePreviewViewModel(
                                url: item.articleURL,
                                titleHtml: item.title,
                                description: item.dateString,
                                imageURL: nil,
                                isSaved: false,
                                snippet: nil
                            ))
                        })
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(item.title)
                        .accessibilityActions {
                            accessibilityAction(named: viewModel.localizedStrings.openArticleTitle) {
                                if let url = item.articleURL {
                                    viewModel.didTapArticle?(url)
                                }
                            }
                            accessibilityAction(named: viewModel.localizedStrings.shareArticleTitle) {
                                if let url = item.articleURL {
                                    viewModel.didShareArticle?(url)
                                }
                            }
                        }
                        .onTapGesture {
                            if let url = item.articleURL {
                                viewModel.didTapArticle?(url)
                            }
                        }
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

            // Title
            Text(item.title)
                .font(Font(WMFFont.for(.georgiaCallout)))
                .foregroundStyle(Color(uiColor: theme.text))
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.top, 10)
                .padding(.bottom, 2)

            // Divider + date
            VStack(alignment: .leading, spacing: 0) {
                Divider()
                    .frame(width: 24)
                    .padding(.bottom, 8)
                    .padding(.top, 6)
                    .foregroundStyle(Color(uiColor: theme.secondaryText))

                Text(item.dateString)
                    .font(Font(WMFFont.for(.caption1)))
                    .foregroundStyle(Color(uiColor: theme.text))
                    .lineLimit(2)
                    .lineSpacing(1.4)
                    .padding(.bottom, 4)
            }
            .padding(.horizontal, 10)

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

    let calendar = Calendar.current
    let items: [WMFWhichCameFirstArticleItemViewModel] = [
        WMFWhichCameFirstArticleItemViewModel(
            title: "Moon landing",
            date: calendar.date(from: DateComponents(year: 1969, month: 7, day: 20)) ?? Date(),
            articleURL: nil,
            thumbnailURL: nil
        ),
        WMFWhichCameFirstArticleItemViewModel(
            title: "World Wide Web",
            date: calendar.date(from: DateComponents(year: 1991, month: 8, day: 6)) ?? Date(),
            articleURL: nil,
            thumbnailURL: nil
        ),
        WMFWhichCameFirstArticleItemViewModel(
            title: "Berlin Wall",
            date: calendar.date(from: DateComponents(year: 1989, month: 11, day: 9)) ?? Date(),
            articleURL: nil,
            thumbnailURL: nil
        ),
        WMFWhichCameFirstArticleItemViewModel(
            title: "DNA double helix",
            date: calendar.date(from: DateComponents(year: 1953, month: 4, day: 25)) ?? Date(),
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

