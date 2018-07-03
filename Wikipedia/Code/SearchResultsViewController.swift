import UIKit
import WMF

class SearchResultsViewController: ArticleCollectionViewController {
    var resultsInfo: WMFSearchResults? = nil // don't use resultsInfo.results, it mutates
    var results: [MWKSearchResult] = [] {
        didSet {
            assert(Thread.isMainThread)
            reload()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reload()
    }
    
    func reload() {
        collectionView.reloadData()
    }
    
    var searchSiteURL: URL? = nil
    
    func isDisplaying(resultsFor searchTerm: String, from siteURL: URL) -> Bool {
        guard let searchResults = resultsInfo, let searchSiteURL = searchSiteURL else {
            return false
        }
        return results.count > 0 && (searchSiteURL as NSURL).wmf_isEqual(toIgnoringScheme: siteURL) && searchResults.searchTerm == searchTerm
    }
    
    override var analyticsName: String {
        return "Search"
    }
    
    override var eventLoggingCategory: EventLoggingCategory {
        return .search
    }
    
    override func articleURL(at indexPath: IndexPath) -> URL? {
        return results[indexPath.item].articleURL(forSiteURL: searchSiteURL)
    }
    
    override func article(at indexPath: IndexPath) -> WMFArticle? {
        guard let articleURL = articleURL(at: indexPath) else {
            return nil
        }
        let article = dataStore.fetchOrCreateArticle(with: articleURL)
        let result = results[indexPath.item]
        article?.update(with: result)
        return article
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return results.count
    }

    func redirectMappingForSearchResult(_ result: MWKSearchResult) -> MWKSearchRedirectMapping? {
        return resultsInfo?.redirectMappings?.filter({ (mapping) -> Bool in
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
        guard indexPath.item < results.count else {
            return
        }
        let result = results[indexPath.item]
        guard let language = searchSiteURL?.wmf_language else {
            return
        }
        cell.configureForCompactList(at: indexPath.item)
        cell.setTitleHTML(result.displayTitleHTML, boldedString: resultsInfo?.searchTerm)
       
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
    }

}

