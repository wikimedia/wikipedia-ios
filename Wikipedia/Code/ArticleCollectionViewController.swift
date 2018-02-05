import UIKit

fileprivate let reuseIdentifier = "ArticleCollectionViewControllerCell"

@objc(WMFArticleCollectionViewControllerDelegate)
protocol ArticleCollectionViewControllerDelegate: NSObjectProtocol {
    func articleCollectionViewController(_ articleCollectionViewController: ArticleCollectionViewController, didSelectArticleWithURL: URL)
}

@objc(WMFArticleCollectionViewController)
class ArticleCollectionViewController: ColumnarCollectionViewController, ReadingListHintPresenter {
    
    @objc var dataStore: MWKDataStore! {
        didSet {
            readingListHintController = ReadingListHintController(dataStore: dataStore, presenter: self)
        }
    }
    var cellLayoutEstimate: WMFLayoutEstimate?
    var editController: CollectionViewEditController!
    var readingListHintController: ReadingListHintController?
    
    @objc weak var delegate: ArticleCollectionViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        register(ArticleRightAlignedImageCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier, addPlaceholder: true)

        editController = CollectionViewEditController(collectionView: collectionView)
        editController.delegate = self
    }
    
    open func configure(cell: ArticleRightAlignedImageCollectionViewCell, forItemAt indexPath: IndexPath, layoutOnly: Bool) {
        guard let article = article(at: indexPath) else {
            return
        }
        let numberOfItems = self.collectionView(collectionView, numberOfItemsInSection: indexPath.section)
        cell.configure(article: article, displayType: .compactList, index: indexPath.item, count: numberOfItems, shouldAdjustMargins: false, shouldShowSeparators: true, theme: theme, layoutOnly: layoutOnly)
        cell.actions = availableActions(at: indexPath)
        cell.layoutMargins = layout.readableMargins
    }
    
    open func articleURL(at indexPath: IndexPath) -> URL? {
        assert(false, "Subclassers should override this function")
        return nil
    }
    
    open func article(at indexPath: IndexPath) -> WMFArticle? {
        assert(false, "Subclassers should override this function")
        return nil
    }
    
    open func delete(at indexPath: IndexPath) {
        assert(false, "Subclassers should override this function")
    }
    
    open func canDelete(at indexPath: IndexPath) -> Bool {
        return false
    }
    
    open func canSave(at indexPath: IndexPath) -> Bool {
        guard let articleURL = articleURL(at: indexPath) else {
            return false
        }
        return !dataStore.savedPageList.isSaved(articleURL)
    }
    
    open func canUnsave(at indexPath: IndexPath) -> Bool {
        guard let articleURL = articleURL(at: indexPath) else {
            return false
        }
        return dataStore.savedPageList.isSaved(articleURL)
    }
    
    open func canShare(at indexPath: IndexPath) -> Bool {
        return articleURL(at: indexPath) != nil
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        cellLayoutEstimate = nil
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
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        assert(false, "Subclassers should override this function")
        return 0
    }
    
    // Override configure(cell: instead to ensure height calculations are accurate
    override open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        guard let articleCell = cell as? ArticleRightAlignedImageCollectionViewCell else {
            return cell
        }
        configure(cell: articleCell, forItemAt: indexPath, layoutOnly: false)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension ArticleCollectionViewController {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let articleURL = articleURL(at: indexPath) else {
            collectionView.deselectItem(at: indexPath, animated: true)
            return
        }
        delegate?.articleCollectionViewController(self, didSelectArticleWithURL: articleURL)
        wmf_pushArticle(with: articleURL, dataStore: dataStore, theme: theme, animated: true)
    }
}

// MARK: - UIViewControllerPreviewingDelegate
extension ArticleCollectionViewController {
    override func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard !editController.isActive else {
            return nil // don't allow 3d touch when swipe actions are active
        }
        guard let indexPath = collectionView.indexPathForItem(at: location),
            let cell = collectionView.cellForItem(at: indexPath) as? ArticleRightAlignedImageCollectionViewCell,
            let url = articleURL(at: indexPath)
        else {
                return nil
        }
        previewingContext.sourceRect = cell.convert(cell.bounds, to: collectionView)
        
        let articleViewController = WMFArticleViewController(articleURL: url, dataStore: dataStore, theme: self.theme)
        articleViewController.articlePreviewingActionsDelegate = self
        articleViewController.wmf_addPeekableChildViewController(for: url, dataStore: dataStore, theme: theme)
        return articleViewController
    }
    
    override func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        viewControllerToCommit.wmf_removePeekableChildViewControllers()
        wmf_push(viewControllerToCommit, animated: true)
    }
}

// MARK: - WMFColumnarCollectionViewLayoutDelegate
extension ArticleCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> WMFLayoutEstimate {
        // The layout estimate can be re-used in this case becuause both labels are one line, meaning the cell
        // size only varies with font size. The layout estimate is nil'd when the font size changes on trait collection change
        if let estimate = cellLayoutEstimate {
            return estimate
        }
        var estimate = WMFLayoutEstimate(precalculated: false, height: 60)
        guard let placeholderCell = placeholder(forCellWithReuseIdentifier: reuseIdentifier) as? ArticleRightAlignedImageCollectionViewCell else {
            return estimate
        }
        placeholderCell.prepareForReuse()
        configure(cell: placeholderCell, forItemAt: indexPath, layoutOnly: true)
        estimate.height = placeholderCell.sizeThatFits(CGSize(width: columnWidth, height: UIViewNoIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        cellLayoutEstimate = estimate
        return estimate
    }
    
    override func metrics(withBoundsSize size: CGSize, readableWidth: CGFloat) -> WMFCVLMetrics {
        return WMFCVLMetrics.singleColumnMetrics(withBoundsSize: size, readableWidth: readableWidth)
    }
}


extension ArticleCollectionViewController: ActionDelegate {
    
    func didPerformBatchEditToolbarAction(_ action: BatchEditToolbarAction) -> Bool {
        assert(false, "Subclassers should override this function")
        return false
    }
    
    func didPerformAction(_ action: Action) -> Bool {
        let indexPath = action.indexPath
        defer {
            if let cell = collectionView.cellForItem(at: indexPath) as? ArticleRightAlignedImageCollectionViewCell {
                cell.actions = availableActions(at: indexPath)
            }
        }
        switch action.type {
        case .delete:
            delete(at: indexPath)
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, WMFLocalizedString("article-deleted-accessibility-notification", value: "Article deleted", comment: "Notification spoken after user deletes an article from the list."))
            return true
        case .save:
            if let articleURL = articleURL(at: indexPath) {
                dataStore.savedPageList.addSavedPage(with: articleURL)
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, CommonStrings.accessibilitySavedNotification)
                if let article = article(at: indexPath) {
                    readingListHintController?.didSave(true, article: article, theme: theme)
                }
                return true
            }
        case .unsave:
            if let articleURL = articleURL(at: indexPath) {
                dataStore.savedPageList.removeEntry(with: articleURL)
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, CommonStrings.accessibilityUnsavedNotification)
                if let article = article(at: indexPath) {
                    readingListHintController?.didSave(false, article: article, theme: theme)
                }
                return true
            }
        case .share:
            return share(article: article(at: indexPath), articleURL: articleURL(at: indexPath), at: indexPath, dataStore: dataStore, theme: theme)
        }
        return false
    }
    
    func availableActions(at indexPath: IndexPath) -> [Action] {
        var actions: [Action] = []
        
        if canSave(at: indexPath) {
            actions.append(ActionType.save.action(with: self, indexPath: indexPath))
        } else if canUnsave(at: indexPath) {
            actions.append(ActionType.unsave.action(with: self, indexPath: indexPath))
        }
        
        if canShare(at: indexPath) {
            actions.append(ActionType.share.action(with: self, indexPath: indexPath))
        }
        
        if canDelete(at: indexPath) {
            actions.append(ActionType.delete.action(with: self, indexPath: indexPath))
        }

        return actions
    }
    
    func updateVisibleCellActions() {
        for indexPath in collectionView.indexPathsForVisibleItems {
            guard let cell = collectionView.cellForItem(at: indexPath) as? ArticleRightAlignedImageCollectionViewCell else {
                continue
            }
            cell.actions = availableActions(at: indexPath)
        }
    }
}

extension ArticleCollectionViewController: ShareableArticlesProvider {}
