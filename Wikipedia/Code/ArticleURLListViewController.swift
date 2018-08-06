import UIKit

class ArticleURLListViewController: ArticleCollectionViewController, ArticleURLProvider {
    let articleURLs: [URL]
    private var updater: ArticleURLProviderEditControllerUpdater?
    
    required init(articleURLs: [URL], dataStore: MWKDataStore, contentGroup: WMFContentGroup? = nil, theme: Theme) {
        self.articleURLs = articleURLs
        super.init()
        self.theme = theme
        self.dataStore = dataStore
        self.contentGroup = contentGroup
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
    
    override func articleURL(at indexPath: IndexPath) -> URL? {
        guard indexPath.item < articleURLs.count else {
            return nil
        }
        return articleURLs[indexPath.item]
    }
    
    override func article(at indexPath: IndexPath) -> WMFArticle? {
        guard let articleURL = articleURL(at: indexPath) else {
            return nil
        }
        return dataStore.fetchOrCreateArticle(with: articleURL)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.reloadData()
        updater = ArticleURLProviderEditControllerUpdater(articleURLProvider: self, collectionView: collectionView, editController: editController)
    }
    
    override var eventLoggingCategory: EventLoggingCategory {
        return .feed
    }
    
    override var eventLoggingLabel: EventLoggingLabel? {
        return contentGroup?.eventLoggingLabel
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
