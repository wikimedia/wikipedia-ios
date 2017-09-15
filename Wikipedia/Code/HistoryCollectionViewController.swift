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
        
        register(ArticleRightAlignedImageCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier, addPlaceholder: true)
        register(UINib(nibName: "CollectionViewHeader", bundle: nil), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier)
    }
    
    var analyticsName: String {
        return "Recent"
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        PiwikTracker.sharedInstance()?.wmf_logView(self)
        NSUserActivity.wmf_makeActive(NSUserActivity.wmf_recentView())
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

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
        articleCell.configure(article: article, displayType: .page, index: indexPath.section, count: count, shouldAdjustMargins: false, shouldShowSeparators: true, theme: theme, layoutOnly: false)
        
        return cell
    }
    
//    - (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
//    id<NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[section];
//    if ([sectionInfo numberOfObjects] == 0) {
//    return @"";
//    }
//
//    NSDate *date = [[[sectionInfo objects] firstObject] viewedDateWithoutTime];
//
//    if (!date) {
//    return @"";
//    }
//
//    //HACK: Table views for some reason aren't adding padding to the left of the default headers. Injecting some manually.
//    NSString *padding = @"    ";
//
//    NSCalendar *calendar = [NSCalendar wmf_gregorianCalendar];
//    if ([calendar isDateInToday:date]) {
//    return [padding stringByAppendingString:[WMFLocalizedStringWithDefaultValue(@"history-section-today", nil, nil, @"Today", @"Subsection label for list of articles browsed today.\n{{Identical|Today}}") uppercaseString]];
//    } else if ([calendar isDateInYesterday:date]) {
//    return [padding stringByAppendingString:[WMFLocalizedStringWithDefaultValue(@"history-section-yesterday", nil, nil, @"Yesterday", @"Subsection label for list of articles browsed yesterday.\n{{Identical|Yesterday}}") uppercaseString]];
//    } else {
//    return [padding stringByAppendingString:[[NSDateFormatter wmf_mediumDateFormatterWithoutTime] stringFromDate:date]];
//    }
//    }
    
    func titleForHeaderInSection(_ section: Int) -> String? {
        guard let sections = fetchedResultsController.sections, sections.count > section else {
            return nil
        }
        let sectionInfo = sections[section]
        guard let article = sectionInfo.objects?.first as? WMFArticle, let date = article.viewedDateWithoutTime else {
            return nil
        }
        
        return (date as NSDate).wmf_localizedRelativeDateStringFromLocalDateToNow()
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
        return headerView
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

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
        return WMFLayoutEstimate(precalculated: false, height: 67)
    }
    
    override func metrics(withBoundsSize size: CGSize) -> WMFCVLMetrics {
        return WMFCVLMetrics.singleColumnMetrics(withBoundsSize: size, collapseSectionSpacing:true)
    }
}
