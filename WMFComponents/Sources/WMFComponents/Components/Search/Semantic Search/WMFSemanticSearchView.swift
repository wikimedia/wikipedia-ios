import SwiftUI

public struct WMFSemanticSearchView: View {

    @ObservedObject var viewModel: WMFSemanticSearchViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    public init(viewModel: WMFSemanticSearchViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            Color(uiColor: theme.paperBackground)
                .ignoresSafeArea()

            switch viewModel.state {
            case .loading:
                ProgressView()
            case .loaded:
                ScrollView {
                    // Lazy so a row's onAppear fires when it is scrolled near, rather than when
                    // the list is built. A plain VStack builds every row up front, which makes the
                    // last row appear immediately and pages forever.
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.rows) { row in
                            WMFSemanticSearchResultCard(viewModel: row, readInArticleText: viewModel.localizedStrings.readInArticle)
                                .onAppear {
                                    viewModel.loadNextPageIfNeeded(afterDisplaying: row)
                                }
                        }

                        if viewModel.isLoadingNextPage {
                            ProgressView()
                                .padding(.vertical, 12)
                        }
                    }
                    .padding(16)
                }
            case .empty:
                message(viewModel.localizedStrings.emptyResults)
            case .error:
                message(viewModel.localizedStrings.errorTitle)
            }
        }
        .onAppear {
            viewModel.fetch()
        }
    }

    private func message(_ text: String) -> some View {
        Text(text)
            .font(Font(WMFFont.for(.body)))
            .foregroundStyle(Color(uiColor: theme.secondaryText))
            .multilineTextAlignment(.center)
            .padding(32)
    }
}

struct WMFSemanticSearchResultCard: View {

    @ObservedObject var viewModel: WMFSemanticSearchRowViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    let readInArticleText: String

    private static let thumbnailLength: CGFloat = 26

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            snippet
            breadcrumb
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: theme.midBackground))
        )
        .onAppear {
            viewModel.loadImageIfNeeded()
        }
    }

    private var snippet: some View {
        Group {
            if let quoteImage = WMFSFSymbolIcon.for(symbol: .quoteOpening, font: .boldSubheadline) {
                Text(Image(uiImage: quoteImage))
                    .foregroundStyle(Color(uiColor: theme.text))
                + Text(" ")
                + Text(attributedSnippet)
            } else {
                Text(attributedSnippet)
            }
        }
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var breadcrumb: some View {
        HStack(spacing: 8) {
            if let thumbnail = viewModel.thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: Self.thumbnailLength, height: Self.thumbnailLength)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            Text(viewModel.breadcrumb)
                .font(Font(WMFFont.for(.caption1)))
                .foregroundStyle(Color(uiColor: theme.secondaryText))
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }

    /// Built here rather than in the view model so highlight and text colors follow theme changes.
    private var attributedSnippet: AttributedString {
        var attributedString = AttributedString()

        for segment in viewModel.snippetSegments {
            var attributedSegment = AttributedString(segment.text)
            attributedSegment.font = Font(WMFFont.for(.callout))
            attributedSegment.foregroundColor = Color(uiColor: theme.text)

            if segment.isMatch {
                attributedSegment.backgroundColor = Color(uiColor: theme.editorMatchBackground)
            }

            attributedString.append(attributedSegment)
        }

        if viewModel.isSnippetTruncated {
            var ellipsis = AttributedString("...")
            ellipsis.font = Font(WMFFont.for(.callout))
            ellipsis.foregroundColor = Color(uiColor: theme.text)
            attributedString.append(ellipsis)
        }

        var readInArticle = AttributedString("  \(readInArticleText)")
        readInArticle.font = Font(WMFFont.for(.callout))
        readInArticle.foregroundColor = Color(uiColor: theme.secondaryText)
        attributedString.append(readInArticle)

        return attributedString
    }
}
