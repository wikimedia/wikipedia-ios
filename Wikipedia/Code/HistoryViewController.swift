import UIKit
import WMF

fileprivate let headerReuseIdentifier = "org.wikimedia.history_header"

@objc(WMFHistoryViewController)
class HistoryViewController: ArticleFetchedResultsViewController {
    
    override func setupFetchedResultsController(with dataStore: MWKDataStore) {
        let articleRequest = WMFArticle.fetchRequest()
        articleRequest.predicate = NSPredicate(format: "viewedDate != NULL")
        articleRequest.sortDescriptors = [NSSortDescriptor(key: "viewedDateWithoutTime", ascending: false), NSSortDescriptor(key: "viewedDate", ascending: false)]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: articleRequest, managedObjectContext: dataStore.viewContext, sectionNameKeyPath: "viewedDateWithoutTime", cacheName: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = WMFLocalizedString("history-title", value: "History", comment: "Title of the history screen shown on history tab\n{{Identical|History}}")
        register(UINib(nibName: "CollectionViewHeader", bundle: nil), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier, addPlaceholder: false)
//        let clearTitle = WMFLocalizedString("history-clear-all", value: "Clear", comment: "Text of the button shown at the top of history which deletes all history\n{{Identical|Clear}}")
//        let clearTitle = WMFLocalizedString("history-clear-cancel", value: "Cancel", comment: "Button text for cancelling delete all action\n{{Identical|Cancel}}")
//        let clearTitle = WMFLocalizedString("history-clear-confirmation-heading", value: "Are you sure you want to delete all your recent items?", comment: "Heading text of delete all confirmation dialog")
//        let clearTitle = WMFLocalizedString("history-clear-delete-all", value: "Yes, delete all", comment: "Button text for confirming delete all action")
    }
    
    override var analyticsName: String {
        return "Recent"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        PiwikTracker.sharedInstance()?.wmf_logView(self)
        NSUserActivity.wmf_makeActive(NSUserActivity.wmf_recentView())
    }
    
    override var emptyViewType: WMFEmptyViewType {
        return .noHistory
    }
}
    
// MARK: UICollectionViewDataSource
extension HistoryViewController {
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
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerReuseIdentifier, for: indexPath)
        guard let headerView = view as? CollectionViewHeader else {
            return view
        }
        headerView.text = titleForHeaderInSection(indexPath.section)
        headerView.apply(theme: theme)
        return headerView
    }
}

// MARK: - WMFColumnarCollectionViewLayoutDelegate
extension HistoryViewController {
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForHeaderInSection section: Int, forColumnWidth columnWidth: CGFloat) -> WMFLayoutEstimate {
        var estimate = WMFLayoutEstimate(precalculated: false, height: 67)
        guard let placeholder = placeholder(forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier) as? CollectionViewHeader else {
            return estimate
        }
        let title = titleForHeaderInSection(section)
        placeholder.prepareForReuse()
        placeholder.text = title
        estimate.height = placeholder.sizeThatFits(CGSize(width: columnWidth, height: UIViewNoIntrinsicMetric)).height
        estimate.precalculated = true
        return estimate
    }
}
