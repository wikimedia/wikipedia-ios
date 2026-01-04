import Foundation
import SwiftUI
import WMFData

@MainActor
public final class WMFSearchResultsViewModel: ObservableObject {

    // MARK: - Localization

    public struct LocalizedStrings {
        public let emptyText: String
        public let openInNewTab: String
        public let preview: String

        public init(
            emptyText: String,
            openInNewTab: String,
            preview: String
        ) {
            self.emptyText = emptyText
            self.openInNewTab = openInNewTab
            self.preview = preview
        }
    }

    // MARK: - Published State

    @Published public var results: [SearchResult] = []
    @Published public var topPadding: CGFloat = 0
    @Published public var recentSearches: [RecentSearchTerm] = []
    @Published public var searchQuery: String? = nil
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
        topPadding: CGFloat = 0
    ) {
        self.localizedStrings = localizedStrings
        self.results = results
        self.topPadding = topPadding
    }

    // MARK: - Updates (called by SearchViewController)

    public func setResults(_ newResults: [SearchResult]) {
        results = newResults
    }

    public func appendResults(_ additionalResults: [SearchResult]) {
        results.append(contentsOf: additionalResults)
    }

    public func reset() {
        results = []
    }
}
