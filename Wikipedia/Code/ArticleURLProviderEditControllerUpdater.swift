import UIKit

protocol ArticleURLProvider: class {
    func articleURL(at indexPath: IndexPath) -> URL?
}

class ArticleURLProviderEditControllerUpdater: NSObject {
    weak var articleURLProvider: ArticleURLProvider?
    weak var collectionView: UICollectionView?
    weak var editController: CollectionViewEditController?
    
    init(articleURLProvider: ArticleURLProvider, collectionView: UICollectionView, editController: CollectionViewEditController) {
        self.articleURLProvider = articleURLProvider
        self.collectionView = collectionView
        self.editController = editController
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(articleWasUpdated(_:)), name: NSNotification.Name.WMFArticleUpdated, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func articleWasUpdated(_ notification: Notification) {
        guard
            let collectionView = collectionView,
            let editController = editController,
            let articleURLProvider = articleURLProvider,
            let databaseKey = (notification.object as? WMFArticle)?.key
        else {
            return
        }
        for indexPath in collectionView.indexPathsForVisibleItems {
            guard
                let visibleKey = articleURLProvider.articleURL(at: indexPath)?.wmf_articleDatabaseKey,
                visibleKey == databaseKey
                else {
                    continue
            }
            guard let cell = collectionView.cellForItem(at: indexPath) else {
                continue
            }
            editController.configureSwipeableCell(cell, forItemAt: indexPath, layoutOnly: false)
        }
    }
    
}
