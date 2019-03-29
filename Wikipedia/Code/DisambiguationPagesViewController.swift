import UIKit
import WMF

@objc(WMFDisambiguationPagesViewController)
class DisambiguationPagesViewController: ArticleFetchedResultsViewController {
    
    let siteURL: URL
    let articleURLs: [URL]
    @objc var resultLimit: Int = 10
    
    @objc(initWithURLs:siteURL:dataStore:theme:)
    required init(with URLs: [URL], siteURL: URL, dataStore: MWKDataStore, theme: Theme) {
        self.siteURL = siteURL
        self.articleURLs = URLs
        super.init()
        self.dataStore = dataStore
        self.theme = theme
        self.title = WMFLocalizedString("page-similar-titles", value: "Similar pages", comment: "Label for button that shows a list of similar titles (disambiguation) for the current page")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupFetchedResultsController(with dataStore: MWKDataStore) {
        let request = WMFArticle.fetchRequest()
        request.predicate = NSPredicate(format: "key IN %@", articleURLs.compactMap { $0.wmf_articleDatabaseKey })
        request.sortDescriptors = [NSSortDescriptor(key: "key", ascending: true)]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: dataStore.viewContext, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetch()
    }
    
    func fetch() {
        self.dataStore.articleSummaryController.updateOrCreateArticleSummariesForArticles(withURLs: articleURLs) { (_) in // don't care, FRC will update
            
        }
    }
    
    override var eventLoggingLabel: EventLoggingLabel? {
        return .similarPage
    }
    
    override var eventLoggingCategory: EventLoggingCategory {
        return .article
    }
}
