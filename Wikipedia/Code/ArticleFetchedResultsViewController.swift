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
        guard let sections = fetchedResultsController.sections,
            indexPath.section < sections.count,
            indexPath.item < sections[indexPath.section].numberOfObjects else {
                return nil
        }
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
    
    var emptyViewType: WMFEmptyViewType {
        return .none
    }
    
    var isEmpty = true
    
    fileprivate final func updateEmptyState() {
        let sectionCount = numberOfSections(in: collectionView)

        isEmpty = true
        for sectionIndex in 0..<sectionCount {
            if self.collectionView(collectionView, numberOfItemsInSection: sectionIndex) > 0 {
                isEmpty = false
                break
            }
        }
        if isEmpty {
            wmf_showEmptyView(of: emptyViewType, theme: theme)
        } else {
            wmf_hideEmptyView()
        }
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
            navigationItem.leftBarButtonItem = nil
            return
        }
        
        if navigationItem.leftBarButtonItem == nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: deleteAllButtonText, style: .plain, target: self, action: #selector(deleteButtonPressed(_:)))
        }

        navigationItem.leftBarButtonItem?.isEnabled = !isEmpty
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
    
    func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, didUpdate collectionView: UICollectionView) {
        for indexPath in collectionView.indexPathsForVisibleItems {
            guard let cell = collectionView.cellForItem(at: indexPath) as? ArticleRightAlignedImageCollectionViewCell else {
                continue
            }
            cell.configureSeparators(for: indexPath.item)
            cell.actions = availableActions(at: indexPath)
        }
        updateEmptyState()
        updateDeleteButton()
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
        collectionView.reloadData()
        updateEmptyState()
        updateDeleteButton()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        swipeToEditController.closeActionPane()
    }
    
    override func configure(cell: ArticleRightAlignedImageCollectionViewCell, forItemAt indexPath: IndexPath, layoutOnly: Bool) {
        super.configure(cell: cell, forItemAt: indexPath, layoutOnly: layoutOnly)
        guard !layoutOnly, let translation = swipeToEditController.swipeTranslationForItem(at: indexPath) else {
            return
        }
        cell.swipeTranslation = translation
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        guard let translation = swipeToEditController.swipeTranslationForItem(at: indexPath) else {
            return true
        }
        return translation == 0
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        if wmf_isShowingEmptyView() {
            updateEmptyState()
        }
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
