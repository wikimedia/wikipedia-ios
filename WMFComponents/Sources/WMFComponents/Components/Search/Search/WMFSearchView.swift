import SwiftUI
import WMFData

public struct WMFSearchView: View {
    @ObservedObject public var viewModel: WMFSearchViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme { appEnvironment.theme }

    public init(viewModel: WMFSearchViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(Color(uiColor: theme.paperBackground).edgesIgnoringSafeArea(.all))
        .onAppear { viewModel.fetchData() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isEmpty {
            emptyStateView
        } else {
            ScrollView {
                VStack(spacing: 16) {
                    if !viewModel.recentSearches.isEmpty {
                        recentSearchesView
                    }
                    if !viewModel.searchResults.isEmpty {
                        searchResultsView
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .resizable()
                .frame(width: 64, height: 64)
                .foregroundColor(Color(uiColor: theme.secondaryText))
            Text("No Results")
                .font(.headline)
                .foregroundColor(Color(uiColor: theme.text))
            Text("Try searching for something else.")
                .foregroundColor(Color(uiColor: theme.secondaryText))
        }
        .padding()
    }

    private var recentSearchesView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(viewModel.localizedStrings.recentTitle)
                    .font(.subheadline)
                    .foregroundColor(Color(uiColor: theme.secondaryText))
                Spacer()
                Button(viewModel.localizedStrings.clearAll) {
                    viewModel.clearAllRecentSearches()
                }
                .font(.subheadline)
                .foregroundColor(Color(uiColor: theme.link))
            }

            ForEach(Array(viewModel.recentSearches.enumerated()), id: \.element.id) { index, term in
                HStack {
                    Text(term.text)
                        .foregroundColor(Color(uiColor: theme.text))
                    Spacer()
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onTapGesture { viewModel.selectSearch(term: term.text) }
                .swipeActions {
                    Button {
                        viewModel.deleteRecentSearch(at: index)
                    } label: {
                        Image(systemName: "trash")
                            .accessibilityLabel(viewModel.localizedStrings.deleteActionAccessibilityLabel)
                    }
                    .tint(Color(uiColor: theme.destructive))
                    .labelStyle(.iconOnly)
                }
            }
        }
        .padding(.vertical)
    }

    private var searchResultsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Results")
                .font(.subheadline)
                .foregroundColor(Color(uiColor: theme.secondaryText))

            ForEach(viewModel.searchResults) { result in
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.title)
                        .font(.body)
                        .foregroundColor(Color(uiColor: theme.text))
                    if let description = result.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(Color(uiColor: theme.secondaryText))
                    }
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.didTapSearchResult?(result)
                }
            }
        }
        .padding(.vertical)
    }
}
