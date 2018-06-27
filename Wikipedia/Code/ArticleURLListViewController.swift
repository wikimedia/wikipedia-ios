import UIKit

class ArticleURLListViewController: ArticleCollectionViewController {
    let articleURLs: [URL]
    private let contentGroup: WMFContentGroup?
    
    required init(articleURLs: [URL], dataStore: MWKDataStore, contentGroup: WMFContentGroup? = nil, theme: Theme) {
        self.articleURLs = articleURLs
        self.contentGroup = contentGroup
        super.init()
        self.theme = theme
        self.dataStore = dataStore
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
    
    override func articleURL(at indexPath: IndexPath) -> URL {
        return articleURLs[indexPath.item]
    }
    
    override func article(at indexPath: IndexPath) -> WMFArticle? {
        return dataStore.fetchOrCreateArticle(with: articleURL(at: indexPath))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.reloadData()
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
