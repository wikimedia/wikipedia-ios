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
        collectionView?.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
