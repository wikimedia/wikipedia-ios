import UIKit

class ArticleURLListViewController: ArticleCollectionViewController, ArticleURLProvider {
    let articleURLs: [URL]
    private var updater: ArticleURLProviderEditControllerUpdater?

    required init(articleURLs: [URL], dataStore: MWKDataStore, contentGroup: WMFContentGroup? = nil, theme: Theme) {
        self.articleURLs = articleURLs
        super.init()
        feedFunnelContext = FeedFunnelContext(contentGroup)
        self.theme = theme
        self.dataStore = dataStore
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
        updater = ArticleURLProviderEditControllerUpdater(articleURLProvider: self, collectionView: collectionView, editController: editController)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            FeedFunnel.shared.logFeedCardClosed(for: feedFunnelContext, maxViewed: maxViewed)
        }
    }
    
    override var eventLoggingCategory: EventLoggingCategory {
        return .feed
    }
    
    override var eventLoggingLabel: EventLoggingLabel? {
        return feedFunnelContext?.label
    }

    override func collectionViewFooterButtonWasPressed(_ collectionViewFooter: CollectionViewFooter) {
        navigationController?.popViewController(animated: true)
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
        FeedFunnel.shared.logArticleInFeedDetailReadingStarted(for: feedFunnelContext, index: indexPath.item, maxViewed: maxViewed)
    }
}

// MARK: - UIViewControllerPreviewingDelegate
extension ArticleURLListViewController {
    override func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        let vc = super.previewingContext(previewingContext, viewControllerForLocation: location)
        FeedFunnel.shared.logArticleInFeedDetailPreviewed(for: feedFunnelContext, index: previewedIndexPath?.item)
        return vc
    }

    override func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        super.previewingContext(previewingContext, commit: viewControllerToCommit)
        FeedFunnel.shared.logArticleInFeedDetailReadingStarted(for: feedFunnelContext, index: previewedIndexPath?.item, maxViewed: maxViewed)
    }
}

// MARK: - WMFArticlePreviewingActionsDelegate
extension ArticleURLListViewController {
    override func shareArticlePreviewActionSelected(withArticleController articleController: WMFArticleViewController, shareActivityController: UIActivityViewController) {
        FeedFunnel.shared.logFeedDetailShareTapped(for: feedFunnelContext, index: previewedIndexPath?.item)
        super.shareArticlePreviewActionSelected(withArticleController: articleController, shareActivityController: shareActivityController)
    }

    override func readMoreArticlePreviewActionSelected(withArticleController articleController: WMFArticleViewController) {
        articleController.wmf_removePeekableChildViewControllers()
        wmf_push(articleController, context: feedFunnelContext, index: previewedIndexPath?.item, animated: true)
    }
}

extension ArticleURLListViewController {
    override func didPerformAction(_ action: Action) -> Bool {
        if action.type == .share {
            FeedFunnel.shared.logFeedDetailShareTapped(for: feedFunnelContext, index: action.indexPath.item)
        }
        return super.didPerformAction(action)
    }
}
