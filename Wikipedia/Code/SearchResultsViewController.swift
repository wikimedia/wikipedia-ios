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

    var delegatesSelection: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        useNavigationBarVisibleHeightForScrollViewInsets = true
        reload()
    }
    
    func reload() {
        collectionView.reloadData()
        updateEmptyState()
    }
    
    var searchSiteURL: URL? = nil
    
    func isDisplaying(resultsFor searchTerm: String, from siteURL: URL) -> Bool {
        guard let searchResults = resultsInfo, let searchSiteURL = searchSiteURL else {
            return false
        }
        return !results.isEmpty && (searchSiteURL as NSURL).wmf_isEqual(toIgnoringScheme: siteURL) && searchResults.searchTerm == searchTerm
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

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let articleURL = articleURL(at: indexPath) else {
            collectionView.deselectItem(at: indexPath, animated: true)
            return
        }
        
        delegate?.articleCollectionViewController(self, didSelectArticleWith: articleURL, at: indexPath)
        guard !delegatesSelection else {
            return
        }
        
        navigate(to: articleURL)
    }

    func redirectMappingForSearchResult(_ result: MWKSearchResult) -> MWKSearchRedirectMapping? {
        return resultsInfo?.redirectMappings?.filter({ (mapping) -> Bool in
            return result.displayTitle == mapping.redirectToTitle
        }).first
    }
    
    func descriptionForSearchResult(_ result: MWKSearchResult) -> String? {
        let capitalizedWikidataDescription = (result.wikidataDescription as NSString?)?.wmf_stringByCapitalizingFirstCharacter(usingWikipediaLanguageCode: searchSiteURL?.wmf_languageCode)
        let mapping = redirectMappingForSearchResult(result)
        guard let redirectFromTitle = mapping?.redirectFromTitle else {
            return capitalizedWikidataDescription
        }
        
        let redirectFormat = WMFLocalizedString("search-result-redirected-from", value: "Redirected from: %1$@", comment: "Text for search result letting user know if a result is a redirect from another article. Parameters: * %1$@ - article title the current search result redirected from")
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
        guard let languageCode = searchSiteURL?.wmf_languageCode,
              let contentLanguageCode = searchSiteURL?.wmf_contentLanguageCode else {
            return
        }
        cell.configureForCompactList(at: indexPath.item)
        cell.setTitleHTML(result.displayTitleHTML, boldedString: resultsInfo?.searchTerm)
        cell.articleSemanticContentAttribute = MWKLanguageLinkController.semanticContentAttribute(forContentLanguageCode: contentLanguageCode)
        cell.titleLabel.accessibilityLanguage = languageCode
        cell.descriptionLabel.text = descriptionForSearchResult(result)
        cell.descriptionLabel.accessibilityLanguage = languageCode
        editController.configureSwipeableCell(cell, forItemAt: indexPath, layoutOnly: layoutOnly)
        if layoutOnly {
            cell.isImageViewHidden = result.thumbnailURL != nil
        } else {
            cell.imageURL = result.thumbnailURL
        } 
        cell.apply(theme: theme)
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        collectionView.backgroundColor = theme.colors.midBackground
    }

}

