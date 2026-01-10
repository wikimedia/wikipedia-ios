import SwiftUI
import WMFData

public struct WMFSearchResultsView: View {

    @ObservedObject public var viewModel: WMFSearchResultsViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    private var theme: WMFTheme {
        appEnvironment.theme
    }

    public init(viewModel: WMFSearchResultsViewModel) {
        self.viewModel = viewModel
    }
    
    private func previewViewModel(url: URL?, titleHtml: String, description: String, imageURL: URL?, isSaved: Bool, snippet: String?) -> WMFArticlePreviewViewModel {
        WMFArticlePreviewViewModel(
            url: url,
            titleHtml: titleHtml,
            description: description,
            imageURL: imageURL,
            isSaved: isSaved,
            snippet: snippet
        )
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch viewModel.displayState {
            case .results:
                resultsView

            case .recentSearches:
                WMFRecentlySearchedView(
                    viewModel: viewModel.recentSearchesViewModel
                )

            case .noResults:
                noResultsView
            }
        }
        .frame(maxHeight: .infinity)
        .background(Color(theme.midBackground))
    }
    
    private var resultsView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.results, id: \.articleURL) { result in
                    WMFSearchResultRow(
                        result: result,
                        description: viewModel.description(for: result),
                        siteURL: viewModel.siteURL
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if let url = result.articleURL {
                            viewModel.tappedSearchResultAction?(url)
                        }
                    }
                    .contextMenu(menuItems: {
                        if let url = result.articleURL {
                            Button(viewModel.localizedStrings.openInNewTab) {
                                viewModel.longPressOpenInNewTabAction?(url)
                            }
                            Button(viewModel.localizedStrings.preview) {
                                viewModel.longPressSearchResultAction?(url)
                            }
                        }
                    }, preview: {
                        WMFArticlePreviewView(
                            viewModel: previewViewModel(
                                url: result.articleURL,
                                titleHtml: result.displayTitleHTML ?? result.displayTitle ?? "",
                                description: result.description ?? "",
                                imageURL: result.thumbnailURL,
                                isSaved: false,
                                snippet: result.extract
                            )
                        )
                    })
                }
            }
            .padding(.top, viewModel.topPadding)
        }
    }

    private var noResultsView: some View {
        HStack {
            Spacer()
            Text(viewModel.localizedStrings.emptyText)
                .font(Font(WMFFont.for(.callout)))
                .foregroundStyle(Color(uiColor: theme.secondaryText))
            Spacer()
        }
    }
}

struct WMFSearchResultRow: View {

    let result: SearchResult
    let description: String
    let siteURL: URL?
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    private var theme: WMFTheme {
        appEnvironment.theme
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                if let html = result.displayTitleHTML {
                    WMFHtmlText(html: html, styles: styles)
                } else {
                    Text(result.title)
                        .font(Font(WMFFont.for(.headline)))
                }
                Text(description)
                    .font(Font(WMFFont.for(.subheadline)))
                    .foregroundColor(Color(uiColor: theme.secondaryText))
                    .lineLimit(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if let thumbnailURL = result.thumbnailURL {
                AsyncImage(url: thumbnailURL) { phase in
                    switch phase {
                    case .empty:
                        Color.gray.opacity(0.2)
                    case .success(let image):
                        image.resizable()
                    case .failure:
                        Color.gray.opacity(0.2)
                    @unknown default:
                        Color.gray.opacity(0.2)
                    }
                }
                .scaledToFill()
                .frame(width: 40, height: 40)
                .cornerRadius(4)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
    }
    
    private var styles: HtmlUtils.Styles {
        return HtmlUtils.Styles(font: WMFFont.for(.headline), boldFont: WMFFont.for(.boldHeadline), italicsFont: WMFFont.for(.italicSubheadline), boldItalicsFont: WMFFont.for(.boldItalicSubheadline), color: theme.text, linkColor: theme.link, lineSpacing: 3)
    }
}
