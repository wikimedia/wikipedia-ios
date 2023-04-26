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
    var doesShowArticlePreviews = true

    override func viewDidLoad() {
        super.viewDidLoad()
        useNavigationBarVisibleHeightForScrollViewInsets = true
        reload()
        NotificationCenter.default.addObserver(self, selector: #selector(updateArticleCell(_:)), name: NSNotification.Name.WMFArticleUpdated, object: nil)
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
    
    override var eventLoggingCategory: EventCategoryMEP {
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
        
        let userInfo: [AnyHashable : Any] = [RoutingUserInfoKeys.source: RoutingUserInfoSourceValue.search.rawValue]
        navigate(to: articleURL, userInfo: userInfo)
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
        configure(cell: cell, forItemAt: indexPath, layoutOnly: layoutOnly, configureForCompact: true)
    }
    
    private func configure(cell: ArticleRightAlignedImageCollectionViewCell, forItemAt indexPath: IndexPath, layoutOnly: Bool, configureForCompact: Bool) {
        guard indexPath.item < results.count else {
            return
        }
        let result = results[indexPath.item]
        guard let languageCode = searchSiteURL?.wmf_languageCode,
              let contentLanguageCode = searchSiteURL?.wmf_contentLanguageCode else {
            return
        }
        
        if configureForCompact {
            cell.configureForCompactList(at: indexPath.item)
        }
        
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

    @objc func updateArticleCell(_ notification: NSNotification) {
        guard let updatedArticle = notification.object as? WMFArticle,
              updatedArticle.hasChangedValuesForCurrentEventThatAffectSavedState,
              let updatedArticleKey = updatedArticle.inMemoryKey else {
            return
        }

        for indexPath in collectionView.indexPathsForVisibleItems {
            guard articleURL(at: indexPath)?.wmf_inMemoryKey == updatedArticleKey,
                  let cell = collectionView.cellForItem(at: indexPath) as? ArticleRightAlignedImageCollectionViewCell else {
                continue
            }

            configure(cell: cell, forItemAt: indexPath, layoutOnly: false, configureForCompact: false)
        }
    }

    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard doesShowArticlePreviews else {
            return nil
        }
        return super.collectionView(collectionView, contextMenuConfigurationForItemAt: indexPath, point: point)
    }
}
