import Foundation
import WMF
import WMFData

/// The maximum number of results that one search request returns.
let WMFMaxSearchResultLimit: UInt = 24

/// A redirect that a search result came from.
struct MWKSearchRedirectMapping: Hashable {
    let redirectFromTitle: String
    let redirectToTitle: String

    init(redirect: WMFArticleSearchRedirect) {
        redirectFromTitle = redirect.from
        redirectToTitle = redirect.to
    }
}

/// The results of one or more search requests for the same term.
///
/// A prefix search can append the results of a full text search. The object keeps the order of the results
/// and removes results with a display title that is already present.
final class WMFSearchResults {
    let searchTerm: String
    private(set) var results: [MWKSearchResult]
    private(set) var redirectMappings: [MWKSearchRedirectMapping]
    private(set) var searchSuggestion: String?

    init(searchTerm: String, results: [MWKSearchResult] = [], searchSuggestion: String? = nil, redirectMappings: [MWKSearchRedirectMapping] = []) {
        self.searchTerm = searchTerm
        self.results = results
        self.searchSuggestion = searchSuggestion
        self.redirectMappings = redirectMappings
    }

    /// Create the results from the WMFData response.
    /// - Parameter languageVariantCode: The language variant of the site. The initializer sets it on the thumbnail URLs.
    convenience init(searchTerm: String, response: WMFArticleSearchResponse, languageVariantCode: String?) {
        self.init(
            searchTerm: searchTerm,
            results: response.results.map { MWKSearchResult(result: $0, languageVariantCode: languageVariantCode) },
            searchSuggestion: response.suggestion,
            redirectMappings: response.redirects.map { MWKSearchRedirectMapping(redirect: $0) }
        )
    }

    /// Append the results of another request. Results with a known display title are not added.
    func merge(_ other: WMFSearchResults) {
        let knownDisplayTitles = Set(results.compactMap(\.displayTitle))
        let newResults = other.results.filter { result in
            guard let displayTitle = result.displayTitle else {
                return false
            }
            return !knownDisplayTitles.contains(displayTitle)
        }
        results.append(contentsOf: newResults)

        let newMappings = other.redirectMappings.filter { !redirectMappings.contains($0) }
        redirectMappings.append(contentsOf: newMappings)

        if searchSuggestion?.isEmpty ?? true {
            searchSuggestion = other.searchSuggestion
        }
    }
}
