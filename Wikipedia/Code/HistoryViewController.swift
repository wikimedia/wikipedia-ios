import UIKit
import WMF

@objc(WMFHistoryViewController)
class HistoryViewController: ArticleFetchedResultsViewController {

    override func setupFetchedResultsController(with dataStore: MWKDataStore) {
        let articleRequest = WMFArticle.fetchRequest()
        articleRequest.predicate = NSPredicate(format: "viewedDate != NULL")
        articleRequest.sortDescriptors = [NSSortDescriptor(keyPath: \WMFArticle.viewedDateWithoutTime, ascending: false), NSSortDescriptor(keyPath: \WMFArticle.viewedDate, ascending: false)]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: articleRequest, managedObjectContext: dataStore.viewContext, sectionNameKeyPath: "viewedDateWithoutTime", cacheName: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.isBarHidingEnabled = false
        navigationBar.isShadowHidingEnabled = true
        navigationBar.displayType = .largeTitle

        emptyViewType = .noHistory
        
        title = CommonStrings.historyTabTitle
        
        deleteAllButtonText = WMFLocalizedString("history-clear-all", value: "Clear", comment: "Text of the button shown at the top of history which deletes all history\n{{Identical|Clear}}")
        deleteAllConfirmationText =  WMFLocalizedString("history-clear-confirmation-heading", value: "Are you sure you want to delete all your recent items?", comment: "Heading text of delete all confirmation dialog")
        deleteAllCancelText = WMFLocalizedString("history-clear-cancel", value: "Cancel", comment: "Button text for cancelling delete all action\n{{Identical|Cancel}}")
        deleteAllText = WMFLocalizedString("history-clear-delete-all", value: "Yes, delete all", comment: "Button text for confirming delete all action")
        isDeleteAllVisible = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionViewUpdater.isGranularUpdatingEnabled = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NSUserActivity.wmf_makeActive(NSUserActivity.wmf_recentView())
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        collectionViewUpdater.isGranularUpdatingEnabled = false
    }
    
    override func deleteAll() {
        dataStore.historyList.removeAllEntries()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
    }

    func titleForHeaderInSection(_ section: Int) -> String? {
        guard let sections = fetchedResultsController.sections, sections.count > section else {
            return nil
        }
        let sectionInfo = sections[section]
        guard let article = sectionInfo.objects?.first as? WMFArticle, let date = article.viewedDateWithoutTime else {
            return nil
        }
        
        return ((date as NSDate).wmf_midnightUTCDateFromLocal as NSDate).wmf_localizedRelativeDateFromMidnightUTCDate()
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionElementKindSectionHeader else {
            return UICollectionReusableView()
        }
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CollectionViewHeader.identifier, for: indexPath)
        guard let headerView = view as? CollectionViewHeader else {
            return view
        }
        headerView.style = .history
        headerView.title = titleForHeaderInSection(indexPath.section)
        headerView.apply(theme: theme)
        headerView.layoutMargins = layout.itemLayoutMargins
        return headerView
    }

    override func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, didUpdate collectionView: UICollectionView) {
        super.collectionViewUpdater(updater, didUpdate: collectionView)
        updateVisibleHeaders()
    }

    func updateVisibleHeaders() {
        for indexPath in collectionView.indexPathsForVisibleSupplementaryElements(ofKind: UICollectionElementKindSectionHeader) {
            guard let headerView = collectionView.supplementaryView(forElementKind: UICollectionElementKindSectionHeader, at: indexPath) as? CollectionViewHeader else {
                continue
            }
            headerView.title = titleForHeaderInSection(indexPath.section)
        }
    }
    
    override var eventLoggingCategory: EventLoggingCategory {
        return .history
    }
    
    // MARK: - ColumnarCollectionViewLayoutDelegate
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForHeaderInSection section: Int, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        let userInfo = "universal"
        let reuseIdentifier = CollectionViewHeader.identifier
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 67)
        if let height = layoutCache.cachedHeightForCellWithIdentifier(reuseIdentifier, columnWidth: columnWidth, userInfo: userInfo) {
            estimate.height = height
            return estimate
        }
        guard let placeholder = layoutManager.placeholder(forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: reuseIdentifier) as? CollectionViewHeader else {
            return estimate
        }
        let title = titleForHeaderInSection(section)
        placeholder.prepareForReuse()
        placeholder.style = .history
        placeholder.title = title
        estimate.height = placeholder.sizeThatFits(CGSize(width: columnWidth, height: UIViewNoIntrinsicMetric)).height
        estimate.precalculated = true
        layoutCache.setHeight(estimate.height, forCellWithIdentifier: reuseIdentifier, columnWidth: columnWidth, userInfo: userInfo)
        return estimate
    }
}

// MARK: WMFSearchButtonProviding

extension HistoryViewController: WMFSearchButtonProviding {

}
