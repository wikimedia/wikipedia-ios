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

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if viewModel.shouldShowResults {
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
                            .contextMenu {
                                if let url = result.articleURL {
                                    Button(viewModel.localizedStrings.openInNewTab) {
                                        viewModel.longPressOpenInNewTabAction?(url)
                                    }
                                    Button(viewModel.localizedStrings.preview) {
                                        viewModel.longPressSearchResultAction?(url)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, viewModel.topPadding)
                }
            } else if viewModel.shouldShowRecentSearches {
                WMFRecentlySearchedView(viewModel: viewModel.recentSearchesViewModel)
            } else {
                HStack {
                    Spacer()
                    Text(viewModel.localizedStrings.emptyText)
                        .font(Font(WMFFont.for(.callout)))
                        .foregroundStyle(Color(uiColor: theme.secondaryText))
                    Spacer()
                }
            }
        }
        .frame(maxHeight: .infinity)
        .background(Color(theme.midBackground))
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
