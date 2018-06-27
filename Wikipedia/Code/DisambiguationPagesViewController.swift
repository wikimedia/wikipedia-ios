import UIKit
import WMF

@objc(WMFDisambiguationPagesViewController)
class DisambiguationPagesViewController: ArticleURLListViewController {
    
    let titlesSearchFetcher = WMFArticlePreviewFetcher()
    let siteURL: URL
    var results: [MWKSearchResult] = []
    
    @objc var resultLimit: Int = 10
    
    @objc(initWithURLs:siteURL:dataStore:theme:)
    required init(with URLs: [URL], siteURL: URL, dataStore: MWKDataStore, theme: Theme) {
        self.siteURL = siteURL
        super.init(articleURLs: URLs, dataStore: dataStore, theme: theme)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not allowed")
    }
    
    required init(articleURLs: [URL], dataStore: MWKDataStore, contentGroup: WMFContentGroup?, theme: Theme) {
        fatalError("init(articleURLs:dataStore:contentGroup:theme:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = WMFLocalizedString("page-similar-titles", value: "Similar pages", comment: "Label for button that shows a list of similar titles (disambiguation) for the current page")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetch()
    }
    
    var didFetch = false
    func fetch() {
        titlesSearchFetcher.fetchArticlePreviewResults(forArticleURLs: articleURLs, siteURL: siteURL, completion: { (results) in
            DispatchQueue.main.async {
                self.results = results
                self.collectionView.reloadData()
            }
        }) { (error) in
            DispatchQueue.main.async {
                self.wmf_showAlertWithError(error as NSError)
            }
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return results.count
    }
    
    override func configure(cell: ArticleRightAlignedImageCollectionViewCell, forItemAt indexPath: IndexPath, layoutOnly: Bool) {
        cell.configureForCompactList(at: indexPath.item)
        let articleURL = self.articleURL(at: indexPath)
        let searchResult = results[indexPath.item]
        cell.titleLabel.text = articleURL.wmf_title
        cell.descriptionLabel.text = (searchResult.wikidataDescription as NSString?)?.wmf_stringByCapitalizingFirstCharacter(usingWikipediaLanguage: siteURL.wmf_language)
        if layoutOnly {
            cell.isImageViewHidden = searchResult.thumbnailURL != nil
        } else {
            cell.imageURL = searchResult.thumbnailURL
        }
        cell.apply(theme: theme)
    }
    
    
    override var analyticsName: String {
        return "Disambiguation"
    }
    
    override var eventLoggingLabel: EventLoggingLabel? {
        return .similarPage
    }
    
    override var eventLoggingCategory: EventLoggingCategory {
        return .article
    }
}
