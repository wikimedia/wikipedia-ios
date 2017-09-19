import UIKit
import WMF

@objc(WMFArticleFetchedResultsViewController)
class ArticleFetchedResultsViewController: ArticleCollectionViewController, CollectionViewUpdaterDelegate {
    var fetchedResultsController: NSFetchedResultsController<WMFArticle>!
    var collectionViewUpdater: CollectionViewUpdater<WMFArticle>!

    open func setupFetchedResultsController(with dataStore: MWKDataStore) {
        assert(false, "Subclassers should override this method")
    }
    
    @objc override var dataStore: MWKDataStore! {
        didSet {
            setupFetchedResultsController(with: dataStore)
            collectionViewUpdater = CollectionViewUpdater(fetchedResultsController: fetchedResultsController, collectionView: collectionView!)
            collectionViewUpdater?.delegate = self
        }
    }
    
    override func article(at indexPath: IndexPath) -> WMFArticle? {
        return fetchedResultsController.object(at: indexPath)
    }
    
    override func articleURL(at indexPath: IndexPath) -> URL? {
        return article(at: indexPath)?.url
    }
    
    override func delete(at indexPath: IndexPath) {
        guard let articleURL = articleURL(at: indexPath) else {
            return
        }
        dataStore.historyList.removeEntry(with: articleURL)
    }
    
    override func canDelete(at indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, didUpdate collectionView: UICollectionView) {
        
    }
    
    var isFirstAppearance = true
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard isFirstAppearance else {
            return
        }
        isFirstAppearance = false
        do {
            try fetchedResultsController.performFetch()
        } catch let error {
            DDLogError("Error fetching articles for \(self): \(error)")
        }
        collectionView?.reloadData()
    }
}

// MARK: UICollectionViewDataSource
extension ArticleFetchedResultsViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let sectionsCount = self.fetchedResultsController.sections?.count else {
            return 0
        }
        return sectionsCount
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let sections = self.fetchedResultsController.sections, section < sections.count else {
            return 0
        }
        return sections[section].numberOfObjects
    }
}
