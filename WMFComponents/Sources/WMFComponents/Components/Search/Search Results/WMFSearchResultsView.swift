import SwiftUI
import WMFData

public struct WMFSearchResultsView: View {

    @ObservedObject public var viewModel: WMFSearchResultsViewModel
    @ObservedObject private var appEnvironment = WMFAppEnvironment.current

    private var theme: WMFTheme {
        appEnvironment.theme
    }

    public init(viewModel: WMFSearchResultsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Group {
            if viewModel.results.isEmpty {
                Text(viewModel.localizedStrings.emptyText)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.results, id: \.articleURL) { result in
                            WMFSearchResultRow(
                                result: result,
                                siteURL: viewModel.siteURL
                            )
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
            }
        }
        .background(Color(theme.destructive))
    }
}

struct WMFSearchResultRow: View {

    let result: SearchResult
    let siteURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {

            Text(result.displayTitleHTML ?? result.title)
                .font(.body)

            if let description = result.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}
