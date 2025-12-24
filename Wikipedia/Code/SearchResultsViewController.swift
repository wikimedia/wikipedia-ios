import UIKit
import WMF
import WMFData

final class SearchResultsViewController: ArticleCollectionViewController {

    var resultsInfo: WMFSearchDataController.SearchResults?
    var results: [WMFSearchDataController.SearchResult] = [] {
        didSet {
            assert(Thread.isMainThread)
            reload()
        }
    }

    var tappedSearchResultAction: ((URL, IndexPath) -> Void)?
    var longPressSearchResultAndCommitAction: ((URL) -> Void)?
    var longPressOpenInNewTabAction: ((URL) -> Void)?

    var searchSiteURL: URL?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        reload()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateArticleCell(_:)),
            name: NSNotification.Name.WMFArticleUpdated,
            object: nil
        )
    }

    // MARK: - Helpers

    private func reload() {
        collectionView.reloadData()
        updateEmptyState()
    }

    func isDisplaying(resultsFor searchTerm: String, from siteURL: URL) -> Bool {
        guard
            let info = resultsInfo,
            let searchSiteURL
        else {
            return false
        }

        return !results.isEmpty
            && (searchSiteURL as NSURL).wmf_isEqual(toIgnoringScheme: siteURL)
            && info.term == searchTerm
    }

    override var eventLoggingCategory: EventCategoryMEP {
        .search
    }

    // MARK: - Article plumbing

    override func articleURL(at indexPath: IndexPath) -> URL? {
        results[safeIndex: indexPath.item]?.articleURL
    }

    override func article(at indexPath: IndexPath) -> WMFArticle? {
        guard
            indexPath.item < results.count,
            let articleURL = articleURL(at: indexPath),
            let article = dataStore.fetchOrCreateArticle(with: articleURL)
        else {
            return nil
        }

        let result = results[indexPath.item]

        article.displayTitleHTML = result.displayTitleHTML ?? result.title
        article.wikidataDescription = descriptionForSearchResult(result)
        article.thumbnailURL = result.thumbnailURL

        return article
    }

    // MARK: - Collection view

    override func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        results.count
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard let url = articleURL(at: indexPath) else {
            collectionView.deselectItem(at: indexPath, animated: true)
            return
        }

        tappedSearchResultAction?(url, indexPath)
    }

    // MARK: - Description handling (HTML FIX)

    private func descriptionForSearchResult(
        _ result: WMFSearchDataController.SearchResult
    ) -> String? {

        guard let html = result.description else {
            return nil
        }

        let plainText: String = {
            guard let data = html.data(using: .utf8),
                  let attributed = try? NSAttributedString(
                      data: data,
                      options: [
                          .documentType: NSAttributedString.DocumentType.html,
                          .characterEncoding: String.Encoding.utf8.rawValue
                      ],
                      documentAttributes: nil
                  )
            else {
                return html
            }

            return attributed.string
        }()

        return (plainText as NSString)
            .wmf_stringByCapitalizingFirstCharacter(
                usingWikipediaLanguageCode: searchSiteURL?.wmf_languageCode
            )
    }

    // MARK: - Cell configuration

    override func configure(
        cell: ArticleRightAlignedImageCollectionViewCell,
        forItemAt indexPath: IndexPath,
        layoutOnly: Bool
    ) {
        configure(
            cell: cell,
            forItemAt: indexPath,
            layoutOnly: layoutOnly,
            configureForCompact: true
        )
    }

    private func configure(
        cell: ArticleRightAlignedImageCollectionViewCell,
        forItemAt indexPath: IndexPath,
        layoutOnly: Bool,
        configureForCompact: Bool
    ) {
        guard
            let result = results[safeIndex: indexPath.item],
            let siteURL = searchSiteURL
        else {
            return
        }

        if configureForCompact {
            cell.configureForCompactList(at: indexPath.item)
        }

        let languageCode = siteURL.wmf_languageCode
        let contentLanguageCode = siteURL.wmf_contentLanguageCode

        cell.setTitleHTML(
            result.displayTitleHTML ?? result.title,
            boldedString: resultsInfo?.term
        )

        cell.articleSemanticContentAttribute =
            MWKLanguageLinkController.semanticContentAttribute(
                forContentLanguageCode: contentLanguageCode
            )

        cell.titleLabel.accessibilityLanguage = languageCode
        cell.descriptionLabel.text = descriptionForSearchResult(result)
        cell.descriptionLabel.accessibilityLanguage = languageCode

        editController.configureSwipeableCell(
            cell,
            forItemAt: indexPath,
            layoutOnly: layoutOnly
        )

        if layoutOnly {
            cell.isImageViewHidden = result.thumbnailURL != nil
        } else {
            cell.imageURL = result.thumbnailURL
        }

        cell.apply(theme: theme)
    }

    // MARK: - Theme

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        collectionView.backgroundColor = theme.colors.midBackground
    }

    // MARK: - Updates

    @objc
    private func updateArticleCell(_ notification: NSNotification) {
        guard
            let article = notification.object as? WMFArticle,
            article.hasChangedValuesForCurrentEventThatAffectSavedState,
            let key = article.inMemoryKey
        else {
            return
        }

        for indexPath in collectionView.indexPathsForVisibleItems {
            guard
                articleURL(at: indexPath)?.wmf_inMemoryKey == key,
                let cell = collectionView.cellForItem(at: indexPath)
                    as? ArticleRightAlignedImageCollectionViewCell
            else {
                continue
            }

            configure(
                cell: cell,
                forItemAt: indexPath,
                layoutOnly: false,
                configureForCompact: false
            )
        }
    }
}
