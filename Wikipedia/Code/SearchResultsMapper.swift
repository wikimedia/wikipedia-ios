import Foundation
import WMF
import WMFComponents
import WMFData
import WMFNativeLocalizations

@MainActor
struct SearchResultsMapper {

    typealias SearchResult = WMFSearchResultsViewModel.SearchResult

    private static let redirectedFromFormat = WMFLocalizedString("search-result-redirected-from", value: "Redirected from: %1$@", comment: "Text for search result letting user know if a result is a redirect from another article. Parameters: * %1$@ - article title the current search result redirected from")

    let siteURL: URL
    let redirectMappings: [MWKSearchRedirectMapping]

    init(siteURL: URL, redirectMappings: [MWKSearchRedirectMapping]) {
        self.siteURL = siteURL
        self.redirectMappings = redirectMappings
    }

    var project: WMFProject? {
        Self.project(for: siteURL)
    }

    static func project(for url: URL) -> WMFProject? {
        guard let languageCode = url.wmf_languageCode else { return nil }
        return .wikipedia(WMFLanguage(languageCode: languageCode, languageVariantCode: url.wmf_languageVariantCode))
    }

    /// - Parameter firstSection: What to show when the lead of the article is empty: the first section with text.
    func searchResult(from result: MWKSearchResult, firstSection: WMFArticleSearchFirstSection? = nil) -> SearchResult? {
        guard let pageTitle = result.title, let articleURL = result.articleURL(forSiteURL: siteURL) else {
            return nil
        }
        
        let title = result.displayTitle ?? pageTitle
        var extract = result.extract
        if (extract ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, let firstSection {
            extract = (WMFSemanticSearchSnippet.plainText(html: firstSection.snippetHTML) as NSString).wmf_summaryFromText()
        }
        return SearchResult(
            articleURL: articleURL,
            pageTitle: pageTitle,
            title: title,
            titleHTML: result.displayTitleHTML ?? title,
            description: description(for: result),
            extract: extract,
            sectionTitle: nil,
            thumbnailURL: result.thumbnailURL,
            isArticle: Self.isArticle(articleURL),
            hasLocation: result.location != nil,
            isSavable: articleURL.namespace == .main)
    }

    static func isArticle(_ articleURL: URL) -> Bool {
        if case .article = LinkCoordinator.destination(for: articleURL) {
            return true
        }
        return false
    }

    /// The Wikidata description the way a lexical row shows it, with a capital first letter.
    func capitalizedDescription(_ description: String?) -> String? {
        (description as NSString?)?.wmf_stringByCapitalizingFirstCharacter(usingWikipediaLanguageCode: siteURL.wmf_languageCode)
    }

    func description(for result: MWKSearchResult) -> String? {
        let capitalizedWikidataDescription = capitalizedDescription(result.wikidataDescription)
        let mapping = redirectMappings.first(where: { $0.redirectToTitle == result.displayTitle })
        guard let redirectFromTitle = mapping?.redirectFromTitle else {
            return capitalizedWikidataDescription
        }
        let redirectMessage = String.localizedStringWithFormat(Self.redirectedFromFormat, redirectFromTitle)
        guard let capitalizedWikidataDescription else {
            return redirectMessage
        }
        return String.localizedStringWithFormat("%@\n%@", redirectMessage, capitalizedWikidataDescription)
    }
}
