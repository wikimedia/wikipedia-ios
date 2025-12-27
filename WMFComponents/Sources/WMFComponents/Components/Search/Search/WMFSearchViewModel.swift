import SwiftUI
import WMFData
import Combine

@MainActor
public final class WMFSearchViewModel: ObservableObject {

    // MARK: - Published State
    @Published public var searchQuery: String = ""
    @Published public var searchResults: [SearchResult] = []
    @Published public var recentSearches: [RecentSearchTerm] = []
    @Published public var trendingSearches: [String] = []
    @Published public var isEmpty: Bool = true

    // MARK: - Dependencies
    private let dataController: WMFSearchDataController
    private let recentSearchesDataController: WMFRecentSearchesDataController
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Callbacks
    public var didTapSearchResult: ((SearchResult) -> Void)?

    // MARK: - Models
    public struct RecentSearchTerm: Identifiable, Equatable {
        public let text: String
        public var id: Int { text.hash }
        
        public init(text: String) {
            self.text = text
        }
    }

    public struct LocalizedStrings {
        public let recentTitle: String
        public let noSearches: String
        public let clearAll: String
        public let deleteActionAccessibilityLabel: String
        
        public init(recentTitle: String, noSearches: String, clearAll: String, deleteActionAccessibilityLabel: String) {
            self.recentTitle = recentTitle
            self.noSearches = noSearches
            self.clearAll = clearAll
            self.deleteActionAccessibilityLabel = deleteActionAccessibilityLabel
        }
    }

    public let localizedStrings: LocalizedStrings

    // MARK: - Init
    public init(
        dataController: WMFSearchDataController = WMFSearchDataController(),
        recentSearchesDataController: WMFRecentSearchesDataController = WMFRecentSearchesDataController(),
        localizedStrings: LocalizedStrings
    ) {
        self.dataController = dataController
        self.recentSearchesDataController = recentSearchesDataController
        self.localizedStrings = localizedStrings

        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                Task { await self?.performSearch(query: query) }
            }
            .store(in: &cancellables)
    }

    // MARK: - Loading
    public func fetchData() {
        Task {
            await fetchRecentSearches()
           // await fetchTrendingSearches()
            await updateEmptyState()
        }
    }

    private func fetchRecentSearches() async {
        do {
            let terms = try await recentSearchesDataController.fetchRecentSearches()
            recentSearches = terms.map { RecentSearchTerm(text: $0) }
        } catch {
            debugPrint("Failed to fetch recent searches: \(error)")
            recentSearches = []
        }
    }

//    private func fetchTrendingSearches() async {
//        trendingSearches = await recentSearchesDataController.getTrendingSearches()
//    }

    private func updateEmptyState() async {
        isEmpty = searchResults.isEmpty && recentSearches.isEmpty && trendingSearches.isEmpty && searchQuery.isEmpty
    }

    // MARK: - Search
    public func performSearch(query: String) async {
        guard !query.isEmpty else { searchResults = []; return }
        do {
            let results = try await dataController.searchArticles(term: query, siteURL: URL(string: "https://en.wikipedia.org")!)
            searchResults = results.results
            await updateEmptyState()
        } catch {
            debugPrint("Search failed: \(error)")
            searchResults = []
            await updateEmptyState()
        }
    }

    public func selectSearch(term: String) {
        searchQuery = term
        Task {
            try? await recentSearchesDataController.saveRecentSearch(term: term, siteURL: URL(string: "https://en.wikipedia.org")!)
            await fetchRecentSearches()
        }
    }

    public func deleteRecentSearch(at index: Int) {
        Task {
            try? await recentSearchesDataController.deleteRecentSearch(at: index)
            await fetchRecentSearches()
        }
    }

    public func clearAllRecentSearches() {
        Task {
            try? await recentSearchesDataController.deleteAll()
            await fetchRecentSearches()
        }
    }
}
