import UIKit
import WMF
import CocoaLumberjackSwift

class SavedArticlesCollectionViewController: ReadingListEntryCollectionViewController {

    // MARK: - Data
    private var entries: [ReadingListEntry] = []
    private var dataSource: UICollectionViewDiffableDataSource<Int, NSManagedObjectID>!

    // MARK: - Init
    init?(with dataStore: MWKDataStore) {
        super.init(for: nil, with: dataStore)
        emptyViewType = .noSavedPages
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        bypassLegacyCollectionViewUpdates = true
        super.viewDidLoad()
        setupDataSource()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchAndApply(animated: false, fromPullToRefresh: false)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contextDidChange),
            name: .NSManagedObjectContextObjectsDidChange,
            object: dataStore.viewContext
        )
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func refresh() {
        dataStore.readingListsController.fullSync {
            assert(Thread.isMainThread)
            self.retryFailedArticleDownloads {
                DispatchQueue.main.async {
                    self.endRefreshing()
                    self.fetchAndApply(animated: true, fromPullToRefresh: true)
                }
            }
        }
    }

    @objc private func contextDidChange(_ note: Notification) {
        
        guard let userInfo = note.userInfo else { return }
        
        print("🔥 notification received")
            print("name:", note.name.rawValue)
            print("object:", note.object as Any)

        // WMFArticle changes
        
        let updatedKeys: [String] = [NSUpdatedObjectsKey]
        let changedArticles: Set<WMFArticle> = updatedKeys.compactMap { key -> Set<WMFArticle>? in
            guard let objects = userInfo[key] as? Set<NSManagedObject> else { return nil }
            return Set(objects.compactMap { object in
                if let article = object as? WMFArticle {
                    if article.hasChangedValuesForCurrentEventThatAffectSavedArticlePreviews && article.isSaved == true {
                        return article
                    }
                }
                return nil
            })
        }.reduce(into: Set<WMFArticle>()) { $0.formUnion($1) }
        let changedArticleKeys = changedArticles.map { $0.inMemoryKey }

        let entriesToReload = entries
            .filter { changedArticleKeys.contains($0.inMemoryKey) }
        
        // ReadingListEntry changes

//        let insertedKeys: [String] = [NSInsertedObjectsKey]
//        let insertedEntries: Set<ReadingListEntry> = insertedKeys.compactMap { key -> Set<ReadingListEntry>? in
//            guard let objects = userInfo[key] as? Set<NSManagedObject> else { return nil }
//            return Set(objects.compactMap { $0 as? ReadingListEntry })
//        }.reduce(into: Set<ReadingListEntry>()) { $0.formUnion($1) }
//
//        let deletedKeys: [String] = [NSDeletedObjectsKey]
//        let deletedEntries: Set<ReadingListEntry> = deletedKeys.compactMap { key -> Set<ReadingListEntry>? in
//            guard let objects = userInfo[key] as? Set<NSManagedObject> else { return nil }
//            return Set(objects.compactMap { $0 as? ReadingListEntry })
//        }.reduce(into: Set<ReadingListEntry>()) { $0.formUnion($1) }

        applyChanges(deleted: [], inserted: [], updated: entriesToReload)
    }

    // MARK: - Setup Diffable DataSource
    private func setupDataSource() {
        collectionView.register(SavedArticlesCollectionViewCell.self, forCellWithReuseIdentifier: "SavedArticlesCollectionViewCell")

        dataSource = UICollectionViewDiffableDataSource<Int, NSManagedObjectID>(collectionView: collectionView) { [weak self] collectionView, indexPath, objectID in
            guard let self = self else { return UICollectionViewCell() }
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SavedArticlesCollectionViewCell", for: indexPath)
            guard let savedCell = cell as? SavedArticlesCollectionViewCell,
                  let entry = try? self.dataStore.viewContext.existingObject(with: objectID) as? ReadingListEntry else {
                return cell
            }
            
            // Configure swipe drawer state fresh
            // savedCell.swipeState = .closed
            self.configure(cell: savedCell, for: entry, at: indexPath, layoutOnly: false)
            
            return savedCell
        }
    }
    
    func resetSwipeStatesAfterSnapshot() {
        guard let editController = self.editController else { return }

        // Loop over visible cells
        for cell in collectionView.visibleCells {
            guard let indexPath = collectionView.indexPath(for: cell),
                  let savedCell = cell as? SavedArticlesCollectionViewCell else { continue }

            // Remove old swipe state keyed by index path
            editController.deconfigureSwipeableCell(savedCell, forItemAt: indexPath)

            // Re-configure fresh for the new index path
            if let entry = entry(at: indexPath) {
                configure(cell: savedCell, for: entry, at: indexPath, layoutOnly: false)
                // editController.configureSwipeableCell(savedCell, forItemAt: indexPath, layoutOnly: false)
            }
        }
    }
    
    override func article(at indexPath: IndexPath) -> WMFArticle? {
        guard indexPath.item < entries.count else {
            return nil
        }
        let entry = entries[indexPath.item]
        return article(for: entry)
    }

    // MARK: - Fetch and Apply
    private func fetchAndApply(animated: Bool, fromPullToRefresh: Bool) {
        // editController.reset()
        let context = dataStore.viewContext
        let request: NSFetchRequest<ReadingListEntry> = ReadingListEntry.fetchRequest()
        request.predicate = basePredicate
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ReadingListEntry.createdDate, ascending: true)] // simple sort

        do {
            let fetched = try context.fetch(request)
            let deduped = dedupe(fetched)
            
            entries = deduped

            print("😅fresh fetch")
            var snapshot = NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>()
            snapshot.appendSections([0])
            snapshot.appendItems(deduped.map { $0.objectID }, toSection: 0)
            
            let offsetBefore = collectionView.contentOffset
            dataSource.apply(snapshot, animatingDifferences: animated) { [weak self] in
                self?.resetSwipeStatesAfterSnapshot()
                self?.updateEmptyState()
                if !fromPullToRefresh {
                    self?.collectionView.setContentOffset(offsetBefore, animated: false)
                }
            }
        } catch {
            assertionFailure("Fetch failed: \(error)")
        }
    }
    
    override func snapshotDelete(articles: [WMFArticle]) {
        // First update UI
        for article in articles {
            for entry in entries {
                if article.inMemoryKey == entry.inMemoryKey {
                    // entriesToDelete.append(entry)
                    entries.removeAll { $0.inMemoryKey == entry.inMemoryKey }
                }
            }
        }
        
        let anchorIndexPath = collectionView.indexPathsForVisibleItems.min()
        collectionView.reloadData() // optional but brutal
        if let indexPath = anchorIndexPath {
            collectionView.scrollToItem(
                    at: indexPath,
                    at: .top,
                    animated: false
                )
        }
        updateEmptyState()
        
        
        // Then update data store
        let url: URL? = articles.first?.url
        let articlesCount = articles.count
        do {
            try dataStore.readingListsController.remove(articles: articles, readingList: readingList)
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: CommonStrings.articleDeletedNotification(articleCount: articlesCount))
        } catch {
            DDLogError("Error removing entries from a reading list: \(error)")
        }
        guard let articleURL = url, dataStore.savedPageList.entry(for: articleURL) == nil else {
            return
        }
        ReadingListsFunnel.shared.logUnsaveInReadingList(articlesCount: articlesCount, language: articleURL.wmf_languageCode)
    }
    
    func applyChanges(deleted: [ReadingListEntry], inserted: [ReadingListEntry], updated: [ReadingListEntry]) {
        
        guard deleted.count > 0 ||
        inserted.count > 0 ||
                updated.count > 0 else {
            return
        }
        
        print("😅applying changes")
        
        var snapshot = dataSource.snapshot()
        
        var needsOffsetRetention: Bool = false
        if deleted.count > 0 {
            snapshot.deleteItems(deleted.map { $0.objectID })
        }
        
        if inserted.count > 0 {
            snapshot.appendItems(inserted.map { $0.objectID }, toSection: 0)
        }
        
        if updated.count > 0 {
            snapshot.reloadItems(updated.map { $0.objectID })
        }
        
        var offsetBefore = CGPoint.zero
        if deleted.count > 0 {
            offsetBefore = collectionView.contentOffset
            needsOffsetRetention = true
        }
        dataSource.apply(snapshot, animatingDifferences: false) { [weak self] in
            self?.resetSwipeStatesAfterSnapshot()
            self?.updateEmptyState()
            if needsOffsetRetention {
                self?.collectionView.setContentOffset(offsetBefore, animated: false)
            }
        }
    }

    private func dedupe(_ items: [ReadingListEntry]) -> [ReadingListEntry] {
        var grouped: [String: ReadingListEntry] = [:]
        var deduped: [ReadingListEntry] = []
        for item in items {
            guard let articleKey = item.articleKey else {
                continue
            }
            
            if grouped[articleKey] == nil {
                deduped.append(item)
                grouped[articleKey] = item
            }
        }
        
        return deduped
    }

    // MARK: - Override superclass accessors
    override func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        entries.count
    }

    override func entry(at indexPath: IndexPath) -> ReadingListEntry? {
        guard indexPath.item < entries.count else { return nil }
        return entries[indexPath.item]
    }

    // MARK: - Article Updates
    override func articleDidChange(_ note: Notification) {
//        no-op, should handle in contextDidChange
    }
}
