import UIKit
import WMFComponents

class ArticleURLListViewController: ArticleCollectionViewController, WMFNavigationBarConfiguring {
    let articleURLs: [URL]
    private let articleKeys: Set<String>
    var contentGroupIDURIString: String?

    required init(articleURLs: [URL], dataStore: MWKDataStore, contentGroup: WMFContentGroup? = nil, theme: Theme) {
        self.articleURLs = articleURLs
        self.articleKeys = Set<String>(articleURLs.compactMap { $0.wmf_databaseKey })
        super.init(nibName: nil, bundle: nil)
        self.contentGroup = contentGroup
        self.contentGroupIDURIString = contentGroup?.objectID.uriRepresentation().absoluteString
        self.theme = theme
        self.dataStore = dataStore
        hidesBottomBarWhenPushed = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func articleDidChange(_ note: Notification) {
        guard
            let article = note.object as? WMFArticle,
            article.hasChangedValuesForCurrentEventThatAffectPreviews,
            let articleKey = article.key,
            articleKeys.contains(articleKey)
            else {
                return
        }
        collectionView.reloadData()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
    
    override func articleURL(at indexPath: IndexPath) -> URL? {
        guard indexPath.item < articleURLs.count else {
            return nil
        }
        return articleURLs[indexPath.item]
    }
    
    override func article(at indexPath: IndexPath) -> WMFArticle? {
        guard let articleURL = articleURL(at: indexPath) else {
            return nil
        }
        return dataStore.fetchOrCreateArticle(with: articleURL)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.reloadData()
        NotificationCenter.default.addObserver(self, selector: #selector(articleDidChange(_:)), name: NSNotification.Name.WMFArticleUpdated, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureNavigationBar()
    }
    
    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: title ?? "", customView: nil, alignment: .hidden)
        
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: nil, profileButtonConfig: nil, tabsButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }

    override var eventLoggingCategory: EventCategoryMEP {
        return .feed
    }
    
    override var eventLoggingLabel: EventLabelMEP? {
        if let contentGroup {
            return contentGroup.getAnalyticsLabel()
        }
        return nil
    }

    override func collectionViewFooterButtonWasPressed(_ collectionViewFooter: CollectionViewFooter) {
        navigationController?.popViewController(animated: true)
    }

    override func readMoreArticlePreviewActionSelected(with peekController: ArticlePeekPreviewViewController) {
        
        guard let navVC = navigationController else { return }
        let coordinator = ArticleCoordinator(navigationController: navVC, articleURL: peekController.articleURL, dataStore: dataStore, theme: theme, source: .undefined)
        coordinator.start()
    }
}

// MARK: - UICollectionViewDataSource
extension ArticleURLListViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return articleURLs.count
    }
}

// MARK: - UICollectionViewDelegate
extension ArticleURLListViewController {
}

extension ArticleURLListViewController {
}
