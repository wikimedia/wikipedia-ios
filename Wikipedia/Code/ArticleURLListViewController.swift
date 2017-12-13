import UIKit

@objc(WMFArticleURLListViewController)
class ArticleURLListViewController: ArticleCollectionViewController {
    let articleURLs: [URL]
    
    @objc required init(articleURLs: [URL], dataStore: MWKDataStore) {
        self.articleURLs = articleURLs
        super.init()
        self.dataStore = dataStore
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
    
    override func articleURL(at indexPath: IndexPath) -> URL {
        return articleURLs[indexPath.item]
    }
    
    override func article(at indexPath: IndexPath) -> WMFArticle? {
        return dataStore.fetchArticle(with: articleURL(at: indexPath))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(articleWasUpdated(_:)), name: NSNotification.Name.WMFArticleUpdated, object: nil)
        collectionView.reloadData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func articleWasUpdated(_ notification: Notification) {
        updateVisibleCellActions()
    }
}

// MARK: - UICollectionViewDataSource
extension ArticleURLListViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return articleURLs.count
    }
}
