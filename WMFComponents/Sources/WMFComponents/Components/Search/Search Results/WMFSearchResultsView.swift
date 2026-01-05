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
                Text("Empty?")
            }
        }
        .background(Color(theme.midBackground))
    }
}

struct WMFSearchResultRow: View {

    let result: SearchResult
    let description: String
    let siteURL: URL?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
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
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(result.displayTitleHTML ?? result.title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
    }
}
