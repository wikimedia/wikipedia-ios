import UIKit
import WMF

@objc(WMFSearchResultsViewController)
class SearchResultsViewController: ArticleCollectionViewController {
    @objc var searchResults: WMFSearchResults? = nil {
        didSet {
            collectionView?.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateVisibleCellActions()
    }
    
    @objc var searchSiteURL: URL? = nil
    
    @objc(isDisplayingResultsForSearchTerm:fromSiteURL:)
    func isDisplaying(resultsFor searchTerm: String, from siteURL: URL) -> Bool {
        guard let searchResults = searchResults, let results = searchResults.results, let searchSiteURL = searchSiteURL else {
            return false
        }
        return results.count > 0 && (searchSiteURL as NSURL).wmf_isEqual(toIgnoringScheme: siteURL) && searchResults.searchTerm == searchTerm
    }
    
    override var analyticsName: String {
        return "Search"
    }
    
    override func articleURL(at indexPath: IndexPath) -> URL? {
        return searchResults?.results?[indexPath.item].articleURL(forSiteURL: searchSiteURL)
    }
    
    override func article(at indexPath: IndexPath) -> WMFArticle? {
        guard let articleURL = articleURL(at: indexPath) else {
            return nil
        }
        return dataStore.fetchArticle(with: articleURL)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searchResults?.results?.count ?? 0
    }
    func redirectMappingForSearchResult(_ result: MWKSearchResult) -> MWKSearchRedirectMapping? {
        return searchResults?.redirectMappings?.filter({ (mapping) -> Bool in
            return result.displayTitle == mapping.redirectToTitle
        }).first
    }
    func descriptionForSearchResult(_ result: MWKSearchResult) -> String? {
        let capitalizedWikidataDescription = (result.wikidataDescription as NSString?)?.wmf_stringByCapitalizingFirstCharacter(usingWikipediaLanguage: searchSiteURL?.wmf_language)
        let mapping = redirectMappingForSearchResult(result)
        guard let redirectFromTitle = mapping?.redirectFromTitle else {
            return capitalizedWikidataDescription
        }
        
        let redirectFormat = WMFLocalizedString("search-result-redirected-from", value: "Redirected from: %1$@", comment: "Text for search result letting user know if a result is a redirect from another article. Parameters:\n* %1$@ - article title the current search result redirected from")
        let redirectMessage = String.localizedStringWithFormat(redirectFormat, redirectFromTitle)
        
        guard let description = capitalizedWikidataDescription else {
            return redirectMessage
        }
        
        return String.localizedStringWithFormat("%@\n%@", redirectMessage, description)
    }
    
    override func configure(cell: ArticleRightAlignedImageCollectionViewCell, forItemAt indexPath: IndexPath, layoutOnly: Bool) {
        guard let result = searchResults?.results?[indexPath.item],
            let articleURL = articleURL(at: indexPath),
            let language = searchSiteURL?.wmf_language else {
            return
        }
        let locale = NSLocale.wmf_locale(for: language)
        cell.configureForCompactList(at: indexPath.item)
        cell.set(titleTextToAttribute: articleURL.wmf_title, highlightingText: searchResults?.searchTerm, locale: locale)
        cell.articleSemanticContentAttribute = MWLanguageInfo.semanticContentAttribute(forWMFLanguage: language)
        cell.titleLabel.accessibilityLanguage = language
        cell.descriptionLabel.text = descriptionForSearchResult(result)
        cell.descriptionLabel.accessibilityLanguage = language
        if layoutOnly {
            cell.isImageViewHidden = result.thumbnailURL != nil
        } else {
            cell.imageURL = result.thumbnailURL
        } 
        cell.apply(theme: theme)
        cell.actions = availableActions(at: indexPath)
    }
}

