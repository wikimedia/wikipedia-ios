import SwiftUI
import WMFData

/// The card of a result of the semantic search interleaved treatment: the article, the passage, and the
/// signals that help a reader trust it. The list and the sheet that explains the list draw the same card.
struct WMFSearchResultInterleavedCard: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var rowViewModel: WMFSearchResultInterleavedRowViewModel
    let thumbnail: UIImage?
    let showsThumbnail: Bool
    let horizontalPadding: CGFloat
    let bottomPadding: CGFloat
    let isRightToLeft: Bool

    @Environment(\.displayScale) private var displayScale

    private static let thumbnailSize: CGFloat = 52
    private static let extractLineLimit = 8

    private var theme: WMFTheme {
        appEnvironment.theme
    }

    private var result: WMFSearchResultsViewModel.SearchResult {
        rowViewModel.result
    }

    private var hairline: CGFloat {
        max(1.0 / displayScale, 0.5)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: WMFSpacing.small) {
            header
            if let extract = result.extract, !extract.isEmpty {
                divider
                extractText(extract)
            }
            readInArticle
            if rowViewModel.showsAttributionRow {
                divider
                attributionRow
            }
            if let sourceBadge = result.sourceBadge {
                debugBadge(sourceBadge)
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, WMFSpacing.large)
        .padding(.bottom, bottomPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(theme.midBackground))
        .contentShape(Rectangle())
        .environment(\.layoutDirection, isRightToLeft ? .rightToLeft : .leftToRight)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: WMFSpacing.medium) {
            VStack(alignment: .leading, spacing: WMFSpacing.xSmall) {
                Text(result.title)
                    .font(Font(WMFFont.for(.boldCallout)))
                    .foregroundStyle(Color(theme.text))
                    .lineLimit(2)
                if let displayedDescription = result.displayedDescription {
                    Text(displayedDescription)
                        .font(Font(WMFFont.for(.subheadline)))
                        .foregroundStyle(Color(theme.secondaryText))
                        .lineLimit(1)
                }
                
                sectionRow
                    .padding(.top, WMFSpacing.xSmall)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if showsThumbnail {
                thumbnailView
            }
        }
    }

    private var sectionRow: some View {
        HStack(spacing: WMFSpacing.xSmall) {
            Image(uiImage: WMFSFSymbolIcon.for(symbol: .arrowTurnDownRight, font: .caption1) ?? UIImage())
                .flipsForRightToLeftLayoutDirection(true)
                .foregroundStyle(Color(theme.text))
                .accessibilityHidden(true)
            Text(rowViewModel.displayedSectionTitle)
                .font(Font(WMFFont.for(.caption1)))
                .foregroundStyle(Color(theme.text))
                .lineLimit(2)
        }
    }

    private func extractText(_ extract: String) -> some View {
        Text(extract)
            .font(Font(WMFFont.for(.subheadline)))
            .foregroundStyle(Color(theme.text))
            .lineLimit(Self.extractLineLimit)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var readInArticle: some View {
        Text(rowViewModel.localizedStrings.readInArticleTitle)
            .font(Font(WMFFont.for(.mediumFootnote)))
            .foregroundStyle(Color(theme.secondaryText))
    }

    /// The labels sit side by side. When they do not fit in one line, as with very large text, they stack
    /// instead of one of them being cut off.
    private var attributionRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: WMFSpacing.large) {
                attributionLabels
            }
            VStack(alignment: .leading, spacing: WMFSpacing.xSmall) {
                attributionLabels
            }
        }
        .frame(maxWidth: .infinity, minHeight: WMFSpacing.large, alignment: .leading)
    }

    @ViewBuilder
    private var attributionLabels: some View {
        switch rowViewModel.attributionState {
        case .loading:
            // Invisible, but as tall as a loaded label, so the card does not grow when the counts arrive.
            attributionLabel(symbol: .person2Fill, text: " ")
                .hidden()
        case .loaded:
            if let contributorsText = rowViewModel.contributorsText {
                attributionLabel(symbol: .person2Fill, text: contributorsText)
            }
            if let referencesText = rowViewModel.referencesText {
                attributionLabel(symbol: .booksVerticalFill, text: referencesText)
            }
            if let lastUpdatedText = rowViewModel.lastUpdatedText {
                attributionLabel(symbol: .clockFill, text: lastUpdatedText)
            }
        }
    }

    private func attributionLabel(symbol: WMFSFSymbolIcon, text: String) -> some View {
        HStack(spacing: WMFSpacing.xSmall) {
            Image(uiImage: WMFSFSymbolIcon.for(symbol: symbol, font: .caption1) ?? UIImage())
                .foregroundStyle(Color(theme.secondaryText))
                .accessibilityHidden(true)
            Text(text)
                .font(Font(WMFFont.for(.caption1)))
                .foregroundStyle(Color(theme.secondaryText))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
    }

    private var divider: some View {
        Divider()
            .background(Color(theme.newBorder))
            .frame(height: hairline)
    }

    /// A developer setting labels each result with the request that gave it and the state the list ended in.
    private func debugBadge(_ text: String) -> some View {
        Text(text)
            .font(Font(WMFFont.for(.caption1)))
            .foregroundStyle(Color(theme.secondaryText))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color(theme.paperBackground))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var thumbnailView: some View {
        ZStack {
            Color(theme.paperBackground)
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(width: Self.thumbnailSize, height: Self.thumbnailSize)
        .clipShape(RoundedRectangle(cornerRadius: WMFCornerRadius.medium))
        .accessibilityHidden(true)
    }
}
