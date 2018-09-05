import UIKit

@objc(WMFArticleCollectionViewControllerDelegate)
protocol ArticleCollectionViewControllerDelegate: NSObjectProtocol {
    func articleCollectionViewController(_ articleCollectionViewController: ArticleCollectionViewController, didSelectArticleWithURL: URL, at indexPath: IndexPath)
}

@objc(WMFArticleCollectionViewController)
class ArticleCollectionViewController: ColumnarCollectionViewController, ReadingListHintPresenter, EditableCollection, EventLoggingEventValuesProviding {
    @objc var dataStore: MWKDataStore! {
        didSet {
            readingListHintController = ReadingListHintController(dataStore: dataStore, presenter: self)
        }
    }
    var cellLayoutEstimate: ColumnarCollectionViewLayoutHeightEstimate?

    var editController: CollectionViewEditController!
    var readingListHintController: ReadingListHintController?
    
    @objc weak var delegate: ArticleCollectionViewControllerDelegate?

    var feedFunnelContext: FeedFunnelContext?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        layoutManager.register(ArticleRightAlignedImageCollectionViewCell.self, forCellWithReuseIdentifier: ArticleRightAlignedImageCollectionViewCell.identifier, addPlaceholder: true)
        setupEditController()
    }
    
    open func configure(cell: ArticleRightAlignedImageCollectionViewCell, forItemAt indexPath: IndexPath, layoutOnly: Bool) {
        guard let article = article(at: indexPath) else {
            return
        }
        cell.configure(article: article, displayType: .compactList, index: indexPath.item, shouldShowSeparators: true, theme: theme, layoutOnly: layoutOnly)
        cell.topSeparator.isHidden = indexPath.item == 0
        cell.bottomSeparator.isHidden = indexPath.item == self.collectionView(collectionView, numberOfItemsInSection: indexPath.section) - 1
        cell.layoutMargins = layout.itemLayoutMargins
        editController.configureSwipeableCell(cell, forItemAt: indexPath, layoutOnly: layoutOnly)
    }
    
    open func articleURL(at indexPath: IndexPath) -> URL? {
        assert(false, "Subclassers should override this function")
        return nil
    }
    
    open func imageURL(at indexPath: IndexPath) -> URL? {
        guard let article = article(at: indexPath) else {
            return nil
        }
        return article.imageURL(forWidth: traitCollection.wmf_nearbyThumbnailWidth)
    }
    
    override func imageURLsForItemAt(_ indexPath: IndexPath) -> Set<URL>? {
        guard let imageURL = imageURL(at: indexPath) else {
            return nil
        }
        return [imageURL]
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
    
    override func contentSizeCategoryDidChange(_ notification: Notification?) {
        cellLayoutEstimate = nil
        super.contentSizeCategoryDidChange(notification)
    }
    
    // MARK: - EventLoggingEventValuesProviding
    
    var eventLoggingCategory: EventLoggingCategory {
        assertionFailure("Subclassers should override this property")
        return .unknown
    }
    
    var eventLoggingLabel: EventLoggingLabel? {
        return nil
    }

    var eventLoggingIndex: NSNumber? {
        guard let index = previewedIndexPath?.item else {
            return nil
        }
        return NSNumber(value: index)
    }

    var previewedIndexPath: IndexPath?

    // MARK: - Layout
    
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        // The layout estimate can be re-used in this case because both labels are one line, meaning the cell
        // size only varies with font size. The layout estimate is nil'd when the font size changes on trait collection change
        if let estimate = cellLayoutEstimate {
            return estimate
        }
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 60)
        guard let placeholderCell = layoutManager.placeholder(forCellWithReuseIdentifier: ArticleRightAlignedImageCollectionViewCell.identifier) as? ArticleRightAlignedImageCollectionViewCell else {
            return estimate
        }
        configure(cell: placeholderCell, forItemAt: indexPath, layoutOnly: true)
        // intentionally set all text and unhide image view to get largest possible size
        placeholderCell.isImageViewHidden = false
        placeholderCell.titleLabel.text = "any"
        placeholderCell.descriptionLabel.text = "any"
        estimate.height = placeholderCell.sizeThatFits(CGSize(width: columnWidth, height: UIView.noIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        cellLayoutEstimate = estimate
        return estimate
    }
    
    override func metrics(with size: CGSize, readableWidth: CGFloat, layoutMargins: UIEdgeInsets) -> ColumnarCollectionViewLayoutMetrics {
        return ColumnarCollectionViewLayoutMetrics.tableViewMetrics(with: size, readableWidth: readableWidth, layoutMargins: layoutMargins)
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ArticleRightAlignedImageCollectionViewCell.identifier, for: indexPath)
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
        delegate?.articleCollectionViewController(self, didSelectArticleWithURL: articleURL, at: indexPath)
        wmf_pushArticle(with: articleURL, dataStore: dataStore, theme: theme, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        editController.deconfigureSwipeableCell(cell, forItemAt: indexPath)
    }
}

// MARK: - UIViewControllerPreviewingDelegate
extension ArticleCollectionViewController {
    override func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard !editController.isActive else {
            return nil // don't allow 3d touch when swipe actions are active
        }
        
        guard
            let indexPath = collectionViewIndexPathForPreviewingContext(previewingContext, location: location),
            let articleURL = articleURL(at: indexPath)
        else {
            return nil
        }

        previewedIndexPath = indexPath

        let articleViewController = WMFArticleViewController(articleURL: articleURL, dataStore: dataStore, theme: self.theme)
        articleViewController.articlePreviewingActionsDelegate = self
        articleViewController.wmf_addPeekableChildViewController(for: articleURL, dataStore: dataStore, theme: theme)
        return articleViewController
    }
    
    override func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        viewControllerToCommit.wmf_removePeekableChildViewControllers()
        wmf_push(viewControllerToCommit, animated: true)
    }
}

extension ArticleCollectionViewController: ActionDelegate {
    
    func didPerformBatchEditToolbarAction(_ action: BatchEditToolbarAction) -> Bool {
        assert(false, "Subclassers should override this function")
        return false
    }
    
    func willPerformAction(_ action: Action) -> Bool {
        guard let article = article(at: action.indexPath) else {
            return false
        }
        guard action.type == .unsave else {
            return self.editController.didPerformAction(action)
        }
        let alertController = ReadingListsAlertController()
        let cancel = ReadingListsAlertActionType.cancel.action { self.editController.close() }
        let delete = ReadingListsAlertActionType.unsave.action { let _ = self.editController.didPerformAction(action) }
        return alertController.showAlert(presenter: self, for: [article], with: [cancel, delete], completion: nil) {
            return self.editController.didPerformAction(action)
        }
    }
    
    func didPerformAction(_ action: Action) -> Bool {
        let indexPath = action.indexPath
        let sourceView = collectionView.cellForItem(at: indexPath)
        switch action.type {
        case .delete:
            delete(at: indexPath)
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: CommonStrings.articleDeletedNotification(articleCount: 1))
            return true
        case .save:
            if let articleURL = articleURL(at: indexPath) {
                dataStore.savedPageList.addSavedPage(with: articleURL)
                UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: CommonStrings.accessibilitySavedNotification)
                if let article = article(at: indexPath) {
                    readingListHintController?.didSave(true, article: article, theme: theme)
                    ReadingListsFunnel.shared.logSave(category: eventLoggingCategory, label: eventLoggingLabel, articleURL: articleURL, date: feedFunnelContext?.midnightUTCDate, measurePosition: indexPath.item)
                }
                return true
            }
        case .unsave:
            if let articleURL = articleURL(at: indexPath) {
                dataStore.savedPageList.removeEntry(with: articleURL)
                UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: CommonStrings.accessibilityUnsavedNotification)
                if let article = article(at: indexPath) {
                    readingListHintController?.didSave(false, article: article, theme: theme)
                    ReadingListsFunnel.shared.logUnsave(category: eventLoggingCategory, label: eventLoggingLabel, articleURL: articleURL, date: feedFunnelContext?.midnightUTCDate, measurePosition: indexPath.item)
                }
                return true
            }
        case .share:
            return share(article: article(at: indexPath), articleURL: articleURL(at: indexPath), at: indexPath, dataStore: dataStore, theme: theme, eventLoggingCategory: eventLoggingCategory, eventLoggingLabel: eventLoggingLabel, sourceView: sourceView)
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
}

extension ArticleCollectionViewController: ShareableArticlesProvider {}
