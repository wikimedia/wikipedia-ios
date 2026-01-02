import UIKit
import WMF

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
        fetchAndApply(animated: false)
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
                    self.fetchAndApply(animated: true)
                }
            }
        }
    }

    @objc private func contextDidChange(_ note: Notification) {
        
        guard let userInfo = note.userInfo else { return }
            let relevantKeys: [String] = [NSInsertedObjectsKey, NSUpdatedObjectsKey, NSDeletedObjectsKey]

            let changedEntries: Set<ReadingListEntry> = relevantKeys.compactMap { key -> Set<ReadingListEntry>? in
                guard let objects = userInfo[key] as? Set<NSManagedObject> else { return nil }
                return Set(objects.compactMap { $0 as? ReadingListEntry })
            }.reduce(into: Set<ReadingListEntry>()) { $0.formUnion($1) }

            guard !changedEntries.isEmpty else { return }

            fetchAndApply(animated: true)
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
                editController.configureSwipeableCell(savedCell, forItemAt: indexPath, layoutOnly: false)
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
    private func fetchAndApply(animated: Bool) {
        // editController.reset()
        let context = dataStore.viewContext
        let request: NSFetchRequest<ReadingListEntry> = ReadingListEntry.fetchRequest()
        request.predicate = basePredicate
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ReadingListEntry.createdDate, ascending: true)] // simple sort

        do {
            let fetched = try context.fetch(request)
            let deduped = dedupe(fetched)
            
            // Sort entries according to the current sort descriptors
            let sortedEntries = deduped.sorted { entry1, entry2 in
                if let date1 = entry1.createdDate,
                   let date2 = entry2.createdDate {
                    return (date1 as Date) < (date2 as Date)
                }
                return false
            }
            
            for sortedEntry in sortedEntries {
                if let title = sortedEntry.displayTitle {
                    print(title)
                }
                if let date = sortedEntry.createdDate {
                    print(date)
                }
            }
            
            entries = sortedEntries

            print("😡doin stuff")
            var snapshot = NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>()
            snapshot.appendSections([0])
            snapshot.appendItems(sortedEntries.map { $0.objectID }, toSection: 0)
            
            dataSource.apply(snapshot, animatingDifferences: animated) { [weak self] in
                self?.resetSwipeStatesAfterSnapshot()
                self?.updateEmptyState()
            }

//            resetSwipeStatesAfterSnapshot()
//            updateEmptyState()
        } catch {
            assertionFailure("Fetch failed: \(error)")
        }
    }

    private func dedupe(_ items: [ReadingListEntry]) -> [ReadingListEntry] {
        let grouped = Dictionary(grouping: items) { $0.articleKey }
        return grouped.compactMap { _, entries in
            entries.max {
                let lhs = $0.createdDate as Date? ?? .distantPast
                let rhs = $1.createdDate as Date? ?? .distantPast
                return lhs < rhs
            }
        }
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
//        print("🔥 notification received")
//            print("name:", note.name.rawValue)
//            print("object:", note.object as Any)
//        
//        guard let article = note.object as? WMFArticle,
//              article.hasChangedValuesForCurrentEventThatAffectSavedArticlePreviews,
//              let articleKey = article.inMemoryKey else { return }
//
//        let objectIDsToReload = entries
//            .filter { $0.inMemoryKey == articleKey }
//            .map { $0.objectID }
//
//        guard !objectIDsToReload.isEmpty else { return }
//
//        print("🤔doing stuff")
//        var snapshot = dataSource.snapshot()
//        snapshot.reloadItems(objectIDsToReload)
//        dataSource.apply(snapshot, animatingDifferences: true)
    }
}
