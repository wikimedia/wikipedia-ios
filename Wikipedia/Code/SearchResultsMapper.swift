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

    func searchResult(from result: MWKSearchResult) -> SearchResult? {
        guard let pageTitle = result.title, let articleURL = result.articleURL(forSiteURL: siteURL) else {
            return nil
        }
        
        let title = result.displayTitle ?? pageTitle
        return SearchResult(
            articleURL: articleURL,
            pageTitle: pageTitle,
            title: title,
            titleHTML: result.displayTitleHTML ?? title,
            description: description(for: result),
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

    func description(for result: MWKSearchResult) -> String? {
        let capitalizedWikidataDescription = (result.wikidataDescription as NSString?)?.wmf_stringByCapitalizingFirstCharacter(usingWikipediaLanguageCode: siteURL.wmf_languageCode)
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
