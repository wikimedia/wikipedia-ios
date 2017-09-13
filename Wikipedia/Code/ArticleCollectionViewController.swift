import UIKit

@objc(WMFArticleCollectionViewController)
class ArticleCollectionViewController: ColumnarCollectionViewController, SwipeableDelegate, AnalyticsContextProviding {
    
    fileprivate static let cellReuseIdentifier = "ArticleCollectionViewControllerCell"
    
    let articleURLs: [URL]
    let dataStore: MWKDataStore
    
    @objc required init(articleURLs: [URL], dataStore: MWKDataStore) {
        self.articleURLs = articleURLs
        self.dataStore = dataStore
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let collectionView = self.collectionView {
            swipeToEditController = CollectionViewSwipeToEditController(collectionView: collectionView, theme: theme)
        }
        
        swipeToEditController?.primaryActions = [CollectionViewCellActionType.save.action, CollectionViewCellActionType.share.action]
        
        register(ArticleRightAlignedImageCollectionViewCell.self, forCellWithReuseIdentifier: ArticleCollectionViewController.cellReuseIdentifier, addPlaceholder: true)
    }
    
    func articleURL(at indexPath: IndexPath) -> URL {
        return articleURLs[indexPath.section]
    }
    
    // MARK: - SwipeableDelegate
    var swipeToEditController: CollectionViewSwipeToEditController?
    
    var indexPathForSwipeableCell: IndexPath?
    var isActionPaneOpen = false
    
    func didOpenActionPane(_ didOpen: Bool, at indexPath: IndexPath) {
        indexPathForSwipeableCell = indexPath
        isActionPaneOpen = didOpen
        if isActionPaneOpen {
            let cell = collectionView?.cellForItem(at: indexPath) as? ArticleCollectionViewCell
            swipeToEditController?.cellWithActionPaneOpen = cell
        }
        swipeToEditController?.isActionPanOpenInCollectionView = didOpen
    }
    
    var analyticsContext: String {
        return "ArticleList"
    }
    
    func didPerformAction(_ sender: UIButton) {
        guard let indexPath = indexPathForSwipeableCell, let cell = collectionView?.cellForItem(at: indexPath) as? ArticleCollectionViewCell else { return }
        
        let action = cell.actions[sender.tag]
        let url = articleURL(at: indexPath)
        
        switch (action.type) {
        case .save:
            if !savedPageList.isSaved(url) {
                savedPageList.addSavedPage(with: url)
            }
        case .unsave:
            savedPageList.removeEntry(with: url)
        case .share:
            share(url, cell: cell)
        default:
            break
        }
        
        swipeToEditController?.performedAction()

    }
    
    func share(_ url: URL, cell: ArticleCollectionViewCell) {
        let shareActivityController = ShareActivityController(articleURL: url, userDataStore: dataStore, context: self)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            shareActivityController.modalPresentationStyle = UIModalPresentationStyle.fullScreen
                shareActivityController.popoverPresentationController?.sourceView = cell
                shareActivityController.popoverPresentationController?.sourceRect = cell.bounds
        }
        
        present(shareActivityController, animated: true, completion: nil)
    }
    
    func isArticleSaved(at indexPath: IndexPath) -> Bool {
        let url = articleURL(at: indexPath)
        return savedPageList.isSaved(url)
    }
    
    var savedPageList: MWKSavedPageList {
        return dataStore.savedPageList
    }
}

// MARK: - UICollectionViewDataSource
extension ArticleCollectionViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return articleURLs.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ArticleCollectionViewController.cellReuseIdentifier, for: indexPath)
        guard let articleCell = cell as? ArticleRightAlignedImageCollectionViewCell else {
            return cell
        }
        let url = articleURL(at: indexPath)
        guard let article = dataStore.fetchArticle(with: url) else {
            return articleCell
        }
        articleCell.delegate = self
        articleCell.actionsView?.delegate = self
        
        articleCell.configure(article: article, displayType: .page, index: indexPath.section, count: articleURLs.count, shouldAdjustMargins: false, shouldShowSeparators: true, theme: theme, layoutOnly: false)
        

        return articleCell
    }
}

// MARK: - UICollectionViewDelegate
extension ArticleCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isActionPaneOpen { return }
        wmf_pushArticle(with: articleURLs[indexPath.section], dataStore: dataStore, theme: self.theme, animated: true)
    }
    
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return !isActionPaneOpen
    }
}

// MARK: - UIViewControllerPreviewingDelegate
extension ArticleCollectionViewController {
    override func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let collectionView = collectionView,
            let indexPath = collectionView.indexPathForItem(at: location),
            let cell = collectionView.cellForItem(at: indexPath) as? ArticleRightAlignedImageCollectionViewCell
        else {
                return nil
        }
        let url = articleURL(at: indexPath)
        previewingContext.sourceRect = cell.convert(cell.bounds, to: collectionView)
        return WMFArticleViewController(articleURL: url, dataStore: dataStore, theme: self.theme)
    }
    
    override func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        wmf_push(viewControllerToCommit, animated: true)
    }
}

// MARK: - WMFColumnarCollectionViewLayoutDelegate
extension ArticleCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> WMFLayoutEstimate {
        var estimate = WMFLayoutEstimate(precalculated: false, height: 60)
        guard let placeholderCell = placeholder(forCellWithReuseIdentifier: ArticleCollectionViewController.cellReuseIdentifier) as? ArticleRightAlignedImageCollectionViewCell else {
            return estimate
        }
        let url = articleURL(at: indexPath)
        guard let article = dataStore.fetchArticle(with: url) else {
            return estimate
        }
        placeholderCell.reset()
        placeholderCell.configure(article: article, displayType: .page, index: indexPath.section, count: articleURLs.count, shouldAdjustMargins: false, shouldShowSeparators: true, theme: theme, layoutOnly: true)
        estimate.height = placeholderCell.sizeThatFits(CGSize(width: columnWidth, height: UIViewNoIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        return estimate
    }
    
    override func metrics(withBoundsSize size: CGSize) -> WMFCVLMetrics {
        return WMFCVLMetrics.singleColumnMetrics(withBoundsSize: size, collapseSectionSpacing:true)
    }
}
