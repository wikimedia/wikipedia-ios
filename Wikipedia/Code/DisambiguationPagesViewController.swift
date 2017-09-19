import UIKit
import WMF

@objc(WMFDisambiguationPagesViewController)
class DisambiguationPagesViewController: ArticleURLListViewController {
    
    let titlesSearchFetcher = WMFArticlePreviewFetcher()
    let siteURL: URL
    
    @objc var resultLimit: Int = 10
    
    @objc(initWithURLs:siteURL:dataStore:)
    required init(with URLs: [URL], siteURL: URL, dataStore: MWKDataStore) {
        self.siteURL = siteURL
        super.init(articleURLs: URLs, dataStore: dataStore)
    }
    
    @objc required init(articleURLs: [URL], dataStore: MWKDataStore) {
        fatalError("init(articleURLs:dataStore:) is not allowed")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not allowed")
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
                for result in results {
                    self.dataStore.viewContext.fetchOrCreateArticle(with: result.articleURL(forSiteURL: self.siteURL), updatedWith: result)
                }
                self.didFetch = true
                self.collectionView?.reloadData()
            }
        }) { (error) in
            DispatchQueue.main.async {
                self.wmf_showAlertWithError(error as NSError)
            }
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return didFetch ? super.collectionView(collectionView, numberOfItemsInSection: section) : 0
    }
    
    override var analyticsName: String {
        return "Disambiguation"
    }
}
