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
            collectionViewUpdater = CollectionViewUpdater(fetchedResultsController: fetchedResultsController, collectionView: collectionView)
            collectionViewUpdater?.delegate = self
        }
    }
    
    override func article(at indexPath: IndexPath) -> WMFArticle? {
        guard fetchedResultsController.isValidIndexPath(indexPath) else {
                return nil
        }
        return fetchedResultsController.object(at: indexPath)
    }
    
    override func articleURL(at indexPath: IndexPath) -> URL? {
        return article(at: indexPath)?.url
    }
    
    override func delete(at indexPath: IndexPath) {
        guard let article = article(at: indexPath) else {
            return
        }
        do {
            try article.removeFromReadHistory()
        } catch let error {
            showError(error)
        }
    }
    
    override func canDelete(at indexPath: IndexPath) -> Bool {
        return true
    }
    
    var deleteAllButtonText: String? = nil
    var deleteAllConfirmationText: String? = nil
    var deleteAllCancelText: String? = nil
    var deleteAllText: String? = nil
    var isDeleteAllVisible: Bool = false
    
    open func deleteAll() {
        
    }
    
    fileprivate final func updateDeleteButton() {
        guard isDeleteAllVisible else {
            navigationItem.rightBarButtonItem = nil
            return
        }
        
        if navigationItem.rightBarButtonItem == nil {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: deleteAllButtonText, style: .plain, target: self, action: #selector(deleteButtonPressed(_:)))
        }

        navigationItem.rightBarButtonItem?.isEnabled = !isEmpty
        navigationBar.updateNavigationItems()
    }
    
    @objc fileprivate final func deleteButtonPressed(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: deleteAllConfirmationText, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: deleteAllText, style: .destructive, handler: { (action) in
            self.deleteAll()
        }))
        alertController.addAction(UIAlertAction(title: deleteAllCancelText, style: .cancel, handler: nil))
        alertController.popoverPresentationController?.barButtonItem = sender
        alertController.popoverPresentationController?.permittedArrowDirections = .any
        present(alertController, animated: true, completion: nil)
    }
    
    open func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, didUpdate collectionView: UICollectionView) {
        for indexPath in collectionView.indexPathsForVisibleItems {
            guard let cell = collectionView.cellForItem(at: indexPath) as? ArticleRightAlignedImageCollectionViewCell else {
                continue
            }
            configure(cell: cell, forItemAt: indexPath, layoutOnly: false)
        }
        updateEmptyState()
    }
    
    func collectionViewUpdater<T: NSFetchRequestResult>(_ updater: CollectionViewUpdater<T>, updateItemAtIndexPath indexPath: IndexPath, in collectionView: UICollectionView) {
        
    }
    
    override func isEmptyDidChange() {
        super.isEmptyDidChange()
        updateDeleteButton()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        editController.close()
    }
    
    override func viewWillHaveFirstAppearance(_ animated: Bool) {
        collectionViewUpdater.performFetch()
        super.viewWillHaveFirstAppearance(animated)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        guard let translation = editController.swipeTranslationForItem(at: indexPath) else {
            return true
        }
        return translation == 0
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
