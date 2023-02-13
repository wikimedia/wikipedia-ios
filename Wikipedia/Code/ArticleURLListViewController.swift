import UIKit

class ArticleURLListViewController: ArticleCollectionViewController, DetailPresentingFromContentGroup {
    let articleURLs: [URL]
    private let articleKeys: Set<String>
    let contentGroupIDURIString: String?
    private let contentGroup: WMFContentGroup?

    required init(articleURLs: [URL], dataStore: MWKDataStore, contentGroup: WMFContentGroup? = nil, theme: Theme) {
        self.articleURLs = articleURLs
        self.articleKeys = Set<String>(articleURLs.compactMap { $0.wmf_databaseKey })
        self.contentGroup = contentGroup
        self.contentGroupIDURIString = contentGroup?.objectID.uriRepresentation().absoluteString
        super.init()
        self.theme = theme
        self.dataStore = dataStore
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

    override var eventLoggingCategory: EventCategoryMEP {
        return .feed
    }
    
    override var eventLoggingLabel: EventLabelMEP? {
        return getLabelfor(contentGroup)
    }

    override func collectionViewFooterButtonWasPressed(_ collectionViewFooter: CollectionViewFooter) {
        navigationController?.popViewController(animated: true)
    }
    
    
    override func shareArticlePreviewActionSelected(with articleController: ArticleViewController, shareActivityController: UIActivityViewController) {
        super.shareArticlePreviewActionSelected(with: articleController, shareActivityController: shareActivityController)
    }

    override func readMoreArticlePreviewActionSelected(with articleController: ArticleViewController) {
        articleController.wmf_removePeekableChildViewControllers()
        push(articleController, animated: true)
    }

    // MARK: - CollectionViewContextMenuShowing
    override func previewingViewController(for indexPath: IndexPath, at location: CGPoint) -> UIViewController? {
        let vc = super.previewingViewController(for: indexPath, at: location)
        return vc
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
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        super.collectionView(collectionView, didSelectItemAt: indexPath)

    }
}

extension ArticleURLListViewController {
    override func didPerformAction(_ action: Action) -> Bool {
        return super.didPerformAction(action)
    }
}

// MARK: - MEP Analytics extension

extension ArticleURLListViewController {
    func getLabelfor(_ contentGroup: WMFContentGroup?) -> EventLabelMEP? {
        if let contentGroup {
            switch contentGroup.contentGroupKind {
            case .featuredArticle:
                return .featuredArticle
            case .topRead:
                return .topRead
            case .onThisDay:
                return .onThisDay
            case .random:
                return .random
            case .news:
                return .news
            case .relatedPages:
                return .relatedPages
            case .continueReading:
                return .continueReading
            case .locationPlaceholder:
                fallthrough
            case .location:
                return .location
            case .mainPage:
                return .mainPage
            case .pictureOfTheDay:
                return .pictureOfTheDay
            case .announcement:
                guard let announcement = contentGroup.contentPreview as? WMFAnnouncement else {
                    return .announcement
                }
                return announcement.placement == "article" ? .articleAnnouncement : .announcement
            default:
                return nil
            }
        }
        return nil
    }
}
