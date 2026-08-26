import XCTest
import CoreData
import UIKit
@testable import Wikipedia
@testable import WMF

// Reproduces the Explore feed crash:
// NSInternalInconsistencyException in UICollectionView batch update validation,
// triggered from CollectionViewUpdater.controllerDidChangeContent.
// See the TestFlight reports from 2026-08-24/25 (version 2026.08.21).
//
// Mechanism under test: two NSFetchedResultsController change cycles occur in
// the same main-queue drain, with no collection view layout pass between them.
// Cycle 1 takes the reloadData path in CollectionViewUpdater. Cycle 2 takes the
// performBatchUpdates path. The updater validates section counts only. The
// collection view lazily re-reads the data source after reloadData, so its
// "before" state is already the post-cycle-2 state. The batch update then
// deletes an item that the collection view no longer has.
final class CollectionViewUpdaterCrashTests: XCTestCase, CollectionViewUpdaterDelegate {

    private var dataStore: MWKDataStore!
    private var window: UIWindow!
    private var collectionView: UICollectionView!
    private var fetchedResultsControllerDataSource: FetchedResultsCollectionViewDataSource!
    private var fetchedResultsController: NSFetchedResultsController<WMFContentGroup>!
    private var updater: CollectionViewUpdater<WMFContentGroup>!

    private let siteURLs = [
        URL(string: "https://en.wikipedia.org")!,
        URL(string: "https://es.wikipedia.org")!,
        URL(string: "https://fr.wikipedia.org")!
    ]

    override func setUp(completion: @escaping (Error?) -> Void) {
        MWKDataStore.createTemporaryDataStore(completion: { dataStore in
            self.dataStore = dataStore
            completion(nil)
        })
    }

    override func tearDown() {
        super.tearDown()
        dataStore.removeFolderAtBasePath()
    }

    // MARK: - Harness

    private func date(daysAgo: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
    }

    @discardableResult
    private func makeContentGroup(daysAgo: Int, siteURL: URL) -> WMFContentGroup? {
        let group = dataStore.viewContext.createGroup(of: .random, for: date(daysAgo: daysAgo), withSiteURL: siteURL, associatedContent: nil)
        group?.isVisible = true
        return group
    }

    private func setupCollectionViewAndUpdater() {
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 390, height: 100)
        collectionView = UICollectionView(frame: window.bounds, collectionViewLayout: layout)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        window.addSubview(collectionView)
        window.makeKeyAndVisible()

        let fetchRequest: NSFetchRequest<WMFContentGroup> = WMFContentGroup.fetchRequest()
        let oldestDate = Calendar.current.date(byAdding: .day, value: -WMFExploreFeedMaximumNumberOfDays, to: (NSDate().wmf_midnightUTCDateFromLocal as Date))!
        // Same predicate and sort descriptors as ExploreViewController.setupFetchedResultsController()
        fetchRequest.predicate = NSPredicate(format: "isVisible == YES && (placement == NULL || placement == %@) && midnightUTCDate >= %@", "feed", oldestDate as NSDate)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "midnightUTCDate", ascending: false),
            NSSortDescriptor(key: "dailySortPriority", ascending: true),
            NSSortDescriptor(key: "date", ascending: false)
        ]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataStore.viewContext, sectionNameKeyPath: "midnightUTCDate", cacheName: nil)
        fetchedResultsControllerDataSource = FetchedResultsCollectionViewDataSource(fetchedResultsController: fetchedResultsController)
        collectionView.dataSource = fetchedResultsControllerDataSource

        updater = CollectionViewUpdater(fetchedResultsController: fetchedResultsController, collectionView: collectionView)
        updater.delegate = self
        updater.performFetch()
        collectionView.layoutIfNeeded()
    }

    private func sectionCountsDescription() -> String {
        let sections = fetchedResultsController.sections ?? []
        return sections.map { "\($0.numberOfObjects)" }.joined(separator: ",")
    }

    private func assertCollectionViewMatchesFetchedResults(file: StaticString = #filePath, line: UInt = #line) {
        collectionView.layoutIfNeeded()
        let sections = fetchedResultsController.sections ?? []
        XCTAssertEqual(collectionView.numberOfSections, sections.count, file: file, line: line)
        for (sectionIndex, section) in sections.enumerated() {
            XCTAssertEqual(collectionView.numberOfItems(inSection: sectionIndex), section.numberOfObjects, "item count mismatch in section \(sectionIndex)", file: file, line: line)
        }
    }

    // MARK: - CollectionViewUpdaterDelegate

    func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, didUpdate collectionView: UICollectionView) {
    }

    func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, updateItemAtIndexPath indexPath: IndexPath, in collectionView: UICollectionView) {
    }

    // MARK: - Tests

    // Scenario A: two FRC change cycles in the same run loop pass, no layout between them.
    // Cycle 1 inserts 10 new sections. The updater's guard (sectionChanges.count < 10)
    // fails, so it calls reloadData(). No layout pass happens.
    // Cycle 2 deletes one item. The updater's guards compare section counts only,
    // and they match, so it calls performBatchUpdates with a delete the collection
    // view has already absorbed through the pending reload.
    func testTwoChangeCyclesInSameRunLoopPassMustNotThrow() throws {
        // Seed: 2 day-sections with 3 groups each.
        for daysAgo in 1...2 {
            for siteURL in siteURLs {
                makeContentGroup(daysAgo: daysAgo, siteURL: siteURL)
            }
        }
        dataStore.viewContext.processPendingChanges()
        setupCollectionViewAndUpdater()
        XCTAssertEqual(collectionView.numberOfSections, 2)

        // Cycle 1: backfill 10 older day-sections (like a launch-time feed import).
        for daysAgo in 3...12 {
            makeContentGroup(daysAgo: daysAgo, siteURL: siteURLs[0])
        }
        dataStore.viewContext.processPendingChanges()
        print("REPRO after cycle 1: frc sections = [\(sectionCountsDescription())], collectionView.numberOfSections not queried yet")

        // Cycle 2, same run loop pass: delete the last item of section 1.
        let sections = fetchedResultsController.sections!
        let lastItemOfSection1 = sections[1].objects!.last as! WMFContentGroup
        dataStore.viewContext.delete(lastItemOfSection1)
        dataStore.viewContext.processPendingChanges()

        print("REPRO after cycle 2: frc sections = [\(sectionCountsDescription())], collectionView sections = \(collectionView.numberOfSections)")
        assertCollectionViewMatchesFetchedResults()
    }

    // Scenario B (control): a single change cycle with the daily-rollover shape:
    // new day section inserted at the top, an item deleted elsewhere, an item updated.
    // The FRC change set is internally consistent, so this must not throw.
    func testSingleRolloverChangeCycleMustNotThrow() throws {
        for daysAgo in 1...3 {
            for siteURL in siteURLs {
                makeContentGroup(daysAgo: daysAgo, siteURL: siteURL)
            }
        }
        dataStore.viewContext.processPendingChanges()
        setupCollectionViewAndUpdater()
        XCTAssertEqual(collectionView.numberOfSections, 3)

        // One cycle: insert today's section at the top, delete the last item of
        // the oldest section, update an item in the middle section.
        makeContentGroup(daysAgo: 0, siteURL: siteURLs[0])
        let sections = fetchedResultsController.sections!
        let lastItemOfOldestSection = sections[2].objects!.last as! WMFContentGroup
        dataStore.viewContext.delete(lastItemOfOldestSection)
        let itemInMiddleSection = sections[1].objects!.first as! WMFContentGroup
        itemInMiddleSection.wasDismissed = false
        dataStore.viewContext.processPendingChanges()

        print("REPRO control: frc sections = [\(sectionCountsDescription())], collectionView sections = \(collectionView.numberOfSections)")
        assertCollectionViewMatchesFetchedResults()
    }
}

private final class FetchedResultsCollectionViewDataSource: NSObject, UICollectionViewDataSource {
    private let fetchedResultsController: NSFetchedResultsController<WMFContentGroup>

    init(fetchedResultsController: NSFetchedResultsController<WMFContentGroup>) {
        self.fetchedResultsController = fetchedResultsController
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let sections = fetchedResultsController.sections, sections.count > section else {
            return 0
        }
        return sections[section].numberOfObjects
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
    }
}
