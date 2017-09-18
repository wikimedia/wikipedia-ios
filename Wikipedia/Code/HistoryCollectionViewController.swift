import UIKit
import WMF

private let reuseIdentifier = "org.wikimedia.history_cell"
private let headerReuseIdentifier = "org.wikimedia.history_header"

@objc(WMFHistoryCollectionViewController)
class HistoryCollectionViewController: ColumnarCollectionViewController, AnalyticsViewNameProviding {
    
    @objc var dataStore: MWKDataStore! {
        didSet {
            let articleRequest = WMFArticle.fetchRequest()
            articleRequest.predicate = NSPredicate(format: "viewedDate != NULL")
            articleRequest.sortDescriptors = [NSSortDescriptor(key: "viewedDateWithoutTime", ascending: false), NSSortDescriptor(key: "viewedDate", ascending: false)]
            fetchedResultsController = NSFetchedResultsController(fetchRequest: articleRequest, managedObjectContext: dataStore.viewContext, sectionNameKeyPath: "viewedDateWithoutTime", cacheName: nil)
            
            do {
                try fetchedResultsController.performFetch()
            } catch let error {
                print(error)
            }
            
            collectionViewUpdater = CollectionViewUpdater(fetchedResultsController: fetchedResultsController, collectionView: collectionView!)
            collectionViewUpdater?.delegate = self
            
            collectionView?.reloadData()
        }
    }
    var fetchedResultsController: NSFetchedResultsController<WMFArticle>!
    var collectionViewUpdater: CollectionViewUpdater<WMFArticle>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = WMFLocalizedString("history-title", value: "History", comment: "Title of the history screen shown on history tab\n{{Identical|History}}")
        register(ArticleRightAlignedImageCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier, addPlaceholder: true)
        register(UINib(nibName: "CollectionViewHeader", bundle: nil), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier, addPlaceholder: false)
    }
    
    var analyticsName: String {
        return "Recent"
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        PiwikTracker.sharedInstance()?.wmf_logView(self)
        NSUserActivity.wmf_makeActive(NSUserActivity.wmf_recentView())
    }
    
    // MARK: UICollectionViewDataSource

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

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        
        guard let articleCell = cell as? ArticleRightAlignedImageCollectionViewCell else {
            return cell
        }
        
        let article = fetchedResultsController.object(at: indexPath)
        let count = self.collectionView(collectionView, numberOfItemsInSection: indexPath.section)
        articleCell.configure(article: article, displayType: .page, index: indexPath.row, count: count, shouldAdjustMargins: false, shouldShowSeparators: true, theme: theme, layoutOnly: false)
        
        return cell
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
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerReuseIdentifier, for: indexPath)
        guard let headerView = view as? CollectionViewHeader else {
            return view
        }
        headerView.text = titleForHeaderInSection(indexPath.section)
        headerView.apply(theme: theme)
        return headerView
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let articleURL = fetchedResultsController.object(at: indexPath).url else {
            collectionView.deselectItem(at: indexPath, animated: true)
            return
        }
        wmf_pushArticle(with: articleURL, dataStore: dataStore, theme: theme, animated: true)
    }
}

extension HistoryCollectionViewController: CollectionViewUpdaterDelegate {
    func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, didUpdate collectionView: UICollectionView) {
        //TODO
    }
}

// MARK: - WMFColumnarCollectionViewLayoutDelegate
extension HistoryCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> WMFLayoutEstimate {
        var estimate = WMFLayoutEstimate(precalculated: false, height: 60)
        guard let placeholderCell = placeholder(forCellWithReuseIdentifier: reuseIdentifier) as? ArticleRightAlignedImageCollectionViewCell else {
            return estimate
        }
        let numberOfItems = self.collectionView(collectionView, numberOfItemsInSection: indexPath.section)
        guard indexPath.section < numberOfSections(in: collectionView), indexPath.row < numberOfItems else {
            return estimate
        }
        let article = fetchedResultsController.object(at: indexPath)
        placeholderCell.reset()
        placeholderCell.configure(article: article, displayType: .page, index: indexPath.section, count: numberOfItems, shouldAdjustMargins: false, shouldShowSeparators: true, theme: theme, layoutOnly: true)
        estimate.height = placeholderCell.sizeThatFits(CGSize(width: columnWidth, height: UIViewNoIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        return estimate
    }
    
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
    
    override func metrics(withBoundsSize size: CGSize) -> WMFCVLMetrics {
        return WMFCVLMetrics.singleColumnMetrics(withBoundsSize: size, collapseSectionSpacing:true)
    }
}
