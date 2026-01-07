import Foundation
import SwiftUI
import WMFData

@MainActor
public final class WMFSearchResultsViewModel: ObservableObject {

    // MARK: - Localization

    public struct LocalizedStrings {
        public let emptyText: String
        public let openInNewTab: String
        public let openInBackgroundTab: String
        public let saveForLater: (String?) -> String
        public let preview: String

        public init(emptyText: String, openInNewTab: String, openInBackgroundTab: String, saveForLater: @escaping (String?) -> String, preview: String) {
            self.emptyText = emptyText
            self.openInNewTab = openInNewTab
            self.openInBackgroundTab = openInBackgroundTab
            self.saveForLater = saveForLater
            self.preview = preview
        }
    }
    
    public enum DisplayState {
        case recentSearches
        case results
        case noResults
    }
    
    public var displayState: DisplayState {
        let trimmedQuery = searchQuery?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if trimmedQuery.isEmpty {
            return .recentSearches
        }

        if !results.isEmpty {
            return .results
        }

        return .noResults
    }

    // MARK: - Published State

    @Published public var results: [SearchResult] = []
    @Published public var topPadding: CGFloat = 0
    @Published public var searchQuery: String? = nil
    @Published public var recentSearchesViewModel: WMFRecentlySearchedViewModel
    
    public var searchSiteURL: URL? = nil

    // MARK: - Configuration

    public let localizedStrings: LocalizedStrings
    public var siteURL: URL?

    // MARK: - Actions

    public var tappedSearchResultAction: ((URL) -> Void)?
    public var longPressSearchResultAction: ((URL) -> Void)?
    public var longPressOpenInNewTabAction: ((URL) -> Void)?

    // MARK: - Init

    public init(
        localizedStrings: LocalizedStrings,
        results: [SearchResult] = [],
        topPadding: CGFloat = 0,
        recentSearchesViewModel: WMFRecentlySearchedViewModel
    ) {
        self.localizedStrings = localizedStrings
        self.results = results
        self.topPadding = topPadding
        self.recentSearchesViewModel = recentSearchesViewModel
    }
    
    func description(for result: SearchResult) -> String {
        guard let html = result.description else { return "" }

        if let data = html.data(using: .utf8) {
            if let attributed = try? AttributedString(
                markdown: data
            ) {
                return String(attributed.characters).capitalized
            }
        }

        return html
    }

    // MARK: - Updates (called by SearchViewController)

    public func setResults(_ newResults: [SearchResult]) {
        results = newResults
    }

    public func appendResults(_ additionalResults: [SearchResult]) {
        results.append(contentsOf: additionalResults)
    }

    public func reset(clearQuery: Bool = false) {
        results = []
        if clearQuery {
            searchQuery = nil
        }
    }
}
