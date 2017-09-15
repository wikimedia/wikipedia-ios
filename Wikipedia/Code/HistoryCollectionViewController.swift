import UIKit

private let reuseIdentifier = "Cell"

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
