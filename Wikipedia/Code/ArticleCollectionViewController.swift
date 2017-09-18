import UIKit

fileprivate let reuseIdentifier = "ArticleCollectionViewControllerCell"

@objc(WMFArticleCollectionViewController)
class ArticleCollectionViewController: ColumnarCollectionViewController {
    @objc var dataStore: MWKDataStore!
    var swipeToEditController: CollectionViewSwipeToEditController!

    override func viewDidLoad() {
        super.viewDidLoad()
        register(ArticleRightAlignedImageCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier, addPlaceholder: true)
        guard let collectionView = collectionView else {
            return
        }
        swipeToEditController = CollectionViewSwipeToEditController(collectionView: collectionView)
        swipeToEditController.delegate = self
    }
    
    open func articleURL(at indexPath: IndexPath) -> URL? {
        assert(false, "Subclassers should override this function")
        return nil
    }
    
    open func article(at indexPath: IndexPath) -> WMFArticle? {
        assert(false, "Subclassers should override this function")
        return nil
    }
    
    open func deleteArticle(with articleURL: URL, at indexPath: IndexPath) {
        assert(false, "Subclassers should override this function")
    }
    
    open func canDeleteArticle(at indexPath: IndexPath) -> Bool {
        return false
    }
}

extension ArticleCollectionViewController: AnalyticsContextProviding, AnalyticsViewNameProviding {
    var analyticsName: String {
        return "ArticleList"
    }
    
    var analyticsContext: String {
        return analyticsName
    }
}

// MARK: - UICollectionViewDataSource
extension ArticleCollectionViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        assert(false, "Subclassers should override this function")
        return 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        assert(false, "Subclassers should override this function")
        return 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        
        guard let articleCell = cell as? ArticleRightAlignedImageCollectionViewCell,
            let article = article(at: indexPath) else {
            return cell
        }
        
        let count = self.collectionView(collectionView, numberOfItemsInSection: indexPath.section)
        articleCell.configure(article: article, displayType: .page, index: indexPath.row, count: count, shouldAdjustMargins: false, shouldShowSeparators: true, theme: theme, layoutOnly: false)
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension ArticleCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let articleURL = articleURL(at: indexPath) else {
            collectionView.deselectItem(at: indexPath, animated: true)
            return
        }
        wmf_pushArticle(with: articleURL, dataStore: dataStore, theme: theme, animated: true)
    }

}

// MARK: - UIViewControllerPreviewingDelegate
extension ArticleCollectionViewController {
    override func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let collectionView = collectionView,
            let indexPath = collectionView.indexPathForItem(at: location),
            let cell = collectionView.cellForItem(at: indexPath) as? ArticleRightAlignedImageCollectionViewCell,
            let url = articleURL(at: indexPath)
        else {
                return nil
        }
        
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
        guard let placeholderCell = placeholder(forCellWithReuseIdentifier: reuseIdentifier) as? ArticleRightAlignedImageCollectionViewCell else {
            return estimate
        }
        let numberOfItems = self.collectionView(collectionView, numberOfItemsInSection: indexPath.section)
        guard indexPath.section < numberOfSections(in: collectionView), indexPath.row < numberOfItems, let article = article(at: indexPath) else {
            return estimate
        }
        placeholderCell.reset()
        placeholderCell.configure(article: article, displayType: .page, index: indexPath.section, count: numberOfItems, shouldAdjustMargins: false, shouldShowSeparators: true, theme: theme, layoutOnly: true)
        estimate.height = placeholderCell.sizeThatFits(CGSize(width: columnWidth, height: UIViewNoIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        return estimate
    }
    
    override func metrics(withBoundsSize size: CGSize) -> WMFCVLMetrics {
        return WMFCVLMetrics.singleColumnMetrics(withBoundsSize: size, collapseSectionSpacing:true)
    }
}


extension ArticleCollectionViewController: CollectionViewSwipeToEditDelegate {
    func didPerformAction(_ action: CollectionViewCellAction, at indexPath: IndexPath) {
        guard let articleURL = articleURL(at: indexPath) else {
            return
        }
        switch action.type {
        case .delete:
            deleteArticle(with: articleURL, at: indexPath)
        case .save:
            dataStore.savedPageList.addSavedPage(with: articleURL)
        case .unsave:
            dataStore.savedPageList.removeEntry(with: articleURL)
        case .share:
            let shareActivityController = ShareActivityController(articleURL: articleURL, userDataStore: dataStore, context: self)
            if UIDevice.current.userInterfaceIdiom == .pad {
                let cell = collectionView?.cellForItem(at: indexPath)
                shareActivityController.modalPresentationStyle = UIModalPresentationStyle.fullScreen
                shareActivityController.popoverPresentationController?.sourceView = cell ?? view
                shareActivityController.popoverPresentationController?.sourceRect = cell?.bounds ?? view.bounds
            }
            present(shareActivityController, animated: true, completion: nil)
            break
        }
        swipeToEditController.performedAction()
    }
    
    func primaryActions(for indexPath: IndexPath) -> [CollectionViewCellAction] {
        guard let article = article(at: indexPath) else {
            return []
        }

        var actions = [CollectionViewCellActionType.share.action]
        
        if canDeleteArticle(at: indexPath) {
            actions.append(CollectionViewCellActionType.delete.action)
        }
        
        if article.savedDate != nil {
            actions.insert(CollectionViewCellActionType.unsave.action, at: 0)
        } else {
            actions.insert(CollectionViewCellActionType.save.action, at: 0)
        }
        
        return actions
    }
    
    func secondaryActions(for indexPath: IndexPath) -> [CollectionViewCellAction] {
        return []
    }
}
