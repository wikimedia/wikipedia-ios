import UIKit

protocol ExploreCardViewControllerDelegate {
    var saveButtonsController: SaveButtonsController { get }
    var readingListHintController: ReadingListHintController { get }
    var layoutCache: ColumnarCollectionViewControllerLayoutCache { get }
}

class ExploreCardViewController: PreviewingViewController, UICollectionViewDataSource, UICollectionViewDelegate, CardContent, ColumnarCollectionViewLayoutDelegate {
    weak var delegate: (ExploreCardViewControllerDelegate & UIViewController)?
    
    lazy var layoutManager: ColumnarCollectionViewLayoutManager = {
        return ColumnarCollectionViewLayoutManager(view: view, collectionView: collectionView)
    }()
    
    lazy var layout: ColumnarCollectionViewLayout = {
        return ColumnarCollectionViewLayout()
    }()
    
    lazy var locationManager: WMFLocationManager = {
        let lm = WMFLocationManager.fine()
        lm.delegate = self
        return lm
    }()
    
    lazy var editController: CollectionViewEditController = {
        let editController = CollectionViewEditController(collectionView: collectionView)
        editController.delegate = self
        return editController
    }()
    
    var collectionView: UICollectionView {
        return view as! UICollectionView
    }
    
    var theme: Theme = Theme.standard
    
    var dataStore: MWKDataStore!
    
    // MARK - View Lifecycle
    
    override func loadView() {
        super.loadView()
        self.view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.isScrollEnabled = false
        layoutManager.register(AnnouncementCollectionViewCell.self, forCellWithReuseIdentifier: AnnouncementCollectionViewCell.identifier, addPlaceholder: true)
        layoutManager.register(ArticleRightAlignedImageExploreCollectionViewCell.self, forCellWithReuseIdentifier: ArticleRightAlignedImageExploreCollectionViewCell.identifier, addPlaceholder: true)
        layoutManager.register(RankedArticleExploreCollectionViewCell.self, forCellWithReuseIdentifier: RankedArticleExploreCollectionViewCell.identifier, addPlaceholder: true)
        layoutManager.register(ArticleFullWidthImageExploreCollectionViewCell.self, forCellWithReuseIdentifier: ArticleFullWidthImageExploreCollectionViewCell.identifier, addPlaceholder: true)
        layoutManager.register(NewsExploreCollectionViewCell.self, forCellWithReuseIdentifier: NewsExploreCollectionViewCell.identifier, addPlaceholder: true)
        layoutManager.register(OnThisDayExploreCollectionViewCell.self, forCellWithReuseIdentifier: OnThisDayExploreCollectionViewCell.identifier, addPlaceholder: true)
        layoutManager.register(ArticleLocationExploreCollectionViewCell.self, forCellWithReuseIdentifier: ArticleLocationExploreCollectionViewCell.identifier, addPlaceholder: true)
        layoutManager.register(ArticleLocationAuthorizationCollectionViewCell.self, forCellWithReuseIdentifier: ArticleLocationAuthorizationCollectionViewCell.identifier, addPlaceholder: true)
        layoutManager.register(ImageCollectionViewCell.self, forCellWithReuseIdentifier: ImageCollectionViewCell.identifier, addPlaceholder: true)
        collectionView.isOpaque = true
        view.isOpaque = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        for indexPath in collectionView.indexPathsForSelectedItems ?? [] {
            collectionView.deselectItem(at: indexPath, animated: animated)
        }
        for cell in collectionView.visibleCells {
            guard let subCell = cell as? SubCellProtocol else {
                continue
            }
            subCell.deselectSelectedSubItems(animated: animated)
        }
    }
    
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        guard let delegateVC = delegate else {
            super.present(viewControllerToPresent, animated: flag, completion: completion)
            return
        }
        delegateVC.present(viewControllerToPresent, animated: flag, completion: completion)
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        guard let delegateVC = delegate else {
            super.dismiss(animated: flag, completion: completion)
            return
        }
        delegateVC.dismiss(animated: flag, completion: completion)
    }
    
    // MARK - Data
    private var visibleLocationCellCount: Int = 0
    
    public var contentGroup: WMFContentGroup? {
        willSet {
            for indexPath in collectionView.indexPathsForVisibleItems {
                guard let cell = collectionView.cellForItem(at: indexPath) else {
                    return
                }
                self.collectionView(collectionView, didEndDisplaying: cell, forItemAt: indexPath)
            }
        }
        didSet {
            reloadData()
        }
    }
    
    private func reloadData() {
        if visibleLocationCellCount > 0 {
            locationManager.stopMonitoringLocation()
        }
        visibleLocationCellCount = 0
        collectionView.reloadData()
    }
    
    public func contentHeight(forWidth width: CGFloat) -> CGFloat {
        return layout.layoutHeight(forWidth: width)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard contentGroup != nil else {
            return 0
        }
        return 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfItems
    }
    
    var numberOfItems: Int {
        return contentGroup?.countOfPreviewItems ?? 0
    }
    
    private func displayTypeAt(_ indexPath: IndexPath) -> WMFFeedDisplayType {
        return contentGroup?.displayTypeForItem(at: indexPath.row) ?? .page
    }
    
    private func resuseIdentifierFor(_ displayType: WMFFeedDisplayType) -> String {
        switch displayType {
        case .ranked:
            return RankedArticleExploreCollectionViewCell.identifier
        case .story:
            return NewsExploreCollectionViewCell.identifier
        case .event:
            return OnThisDayExploreCollectionViewCell.identifier
        case .continueReading:
            fallthrough
        case .relatedPagesSourceArticle:
            fallthrough
        case .random:
            fallthrough
        case .pageWithPreview:
            return ArticleFullWidthImageExploreCollectionViewCell.identifier
        case .photo:
            return ImageCollectionViewCell.identifier
        case .pageWithLocation:
            return ArticleLocationExploreCollectionViewCell.identifier
        case .pageWithLocationPlaceholder:
            return ArticleLocationAuthorizationCollectionViewCell.identifier
        case .page, .relatedPages, .mainPage, .compactList:
            return ArticleRightAlignedImageExploreCollectionViewCell.identifier
        case .announcement, .notification, .theme, .readingList:
            return AnnouncementCollectionViewCell.identifier
        }
    }
    
    private func articleURL(at indexPath: IndexPath) -> URL? {
        return contentGroup?.previewArticleURLForItemAtIndex(indexPath.row)
    }
    
    private func article(at indexPath: IndexPath) -> WMFArticle? {
        guard let url = articleURL(at: indexPath) else {
            return nil
        }
        return dataStore.fetchArticle(with: url)
    }
    
    // MARK - cell configuration
    
    private func configureArticleCell(_ cell: UICollectionViewCell, forItemAt indexPath: IndexPath, with displayType: WMFFeedDisplayType, layoutOnly: Bool) {
        guard let cell = cell as? ArticleCollectionViewCell, let articleURL = articleURL(at: indexPath), let article = dataStore?.fetchArticle(with: articleURL) else {
            return
        }
        cell.configure(article: article, displayType: displayType, index: indexPath.row, theme: theme, layoutOnly: layoutOnly)
        cell.saveButton.eventLoggingLabel = eventLoggingLabel
        editController.configureSwipeableCell(cell, forItemAt: indexPath, layoutOnly: layoutOnly)
    }
    
    private func configureLocationCell(_ cell: UICollectionViewCell, forItemAt indexPath: IndexPath, with displayType: WMFFeedDisplayType, layoutOnly: Bool) {
        guard let cell = cell as? ArticleLocationExploreCollectionViewCell, let articleURL = articleURL(at: indexPath), let article = dataStore?.fetchArticle(with: articleURL) else {
            return
        }
        cell.configure(article: article, displayType: displayType, index: indexPath.row, theme: theme, layoutOnly: layoutOnly)
        if let authCell = cell as? ArticleLocationAuthorizationCollectionViewCell {
            authCell.authorizeTitleLabel.text = CommonStrings.localizedEnableLocationExploreTitle
            authCell.authorizeButton.setTitle(CommonStrings.localizedEnableLocationButtonTitle, for: .normal)
            authCell.authorizeDescriptionLabel.text = CommonStrings.localizedEnableLocationDescription
            authCell.authorizationDelegate = self
        }
        guard !layoutOnly else {
            cell.configureForUnknownDistance()
            return
        }
        cell.articleLocation = article.location
        if WMFLocationManager.isAuthorized() {
            locationManager.startMonitoringLocation()
            cell.update(userLocation: locationManager.location, heading: locationManager.heading)
        } else {
            cell.configureForUnknownDistance()
        }
        editController.configureSwipeableCell(cell, forItemAt: indexPath, layoutOnly: layoutOnly)
    }
    
    private func configureNewsCell(_ cell: UICollectionViewCell, layoutOnly: Bool) {
        guard let cell = cell as? NewsExploreCollectionViewCell, let story = contentGroup?.contentPreview as? WMFFeedNewsStory else {
            return
        }
        cell.configure(with: story, dataStore: dataStore, showArticles: false, theme: theme, layoutOnly: layoutOnly)
        cell.selectionDelegate = self
    }
    
    private func configureOnThisDayCell(_ cell: UICollectionViewCell, forItemAt indexPath: IndexPath, layoutOnly: Bool) {
        let index = indexPath.row
        guard let cell = cell as? OnThisDayExploreCollectionViewCell, let events = contentGroup?.contentPreview as? [WMFFeedOnThisDayEvent], events.count > 0, events.indices.contains(index) else {
            return
        }
        let event = events[index]
        cell.configure(with: event, isFirst: events.indices.first == index, isLast: events.indices.last == index, dataStore: dataStore, theme: theme, layoutOnly: layoutOnly)
        cell.selectionDelegate = self
    }
    
    private func configurePhotoCell(_ cell: UICollectionViewCell, layoutOnly: Bool) {
        guard let cell = cell as? ImageCollectionViewCell, let imageInfo = contentGroup?.contentPreview as? WMFFeedImage else {
            return
        }
        if !layoutOnly, let imageURL = contentGroup?.imageURLsCompatibleWithTraitCollection(traitCollection, dataStore: dataStore)?.first {
            cell.imageView.wmf_setImage(with: imageURL, detectFaces: true, onGPU: true, failure: WMFIgnoreErrorHandler, success: WMFIgnoreSuccessHandler)
        }
        if imageInfo.imageDescription.count > 0 {
            cell.caption = imageInfo.imageDescription.wmf_stringByRemovingHTML()
        } else {
            cell.caption = imageInfo.canonicalPageTitle
        }
        cell.apply(theme: theme)
    }
    
    private func configureAnnouncementCell(_ cell: UICollectionViewCell, displayType: WMFFeedDisplayType, layoutOnly: Bool) {
        guard let cell = cell as? AnnouncementCollectionViewCell else {
            return
        }
        switch displayType {
        case .announcement:
            guard let announcement = contentGroup?.contentPreview as? WMFAnnouncement else {
                return
            }
            if let imageURL = announcement.imageURL {
                cell.isImageViewHidden = false
                if !layoutOnly {
                    cell.imageView.wmf_setImage(with: imageURL, detectFaces: false, onGPU: false, failure: WMFIgnoreErrorHandler, success: WMFIgnoreSuccessHandler)
                }
            } else {
                cell.isImageViewHidden = true
            }
            cell.messageLabel.text = announcement.text
            cell.actionButton.setTitle(announcement.actionTitle, for: .normal)
            cell.caption = announcement.caption
        case .notification:
            cell.isImageViewHidden = false
            cell.imageView.image = UIImage(named: "feed-card-notification")
            cell.imageViewDimension = cell.imageView.image?.size.height ?? 0
            cell.messageLabel.text = WMFLocalizedString("feed-news-notification-text", value: "Enable notifications to be notified by Wikipedia when articles are trending in the news.", comment: "Text shown to users to notify them that it is now possible to get notifications for articles related to trending news")
            cell.actionButton.setTitle(WMFLocalizedString("feed-news-notification-button-text", value: "Turn on notifications", comment: "Text for button to turn on trending news notifications"), for:.normal)
        case .theme:
            cell.isImageViewHidden = false
            cell.imageView.image = UIImage(named: "feed-card-themes")
            cell.imageViewDimension = cell.imageView.image?.size.height ?? 0
            cell.messageLabel.text = WMFLocalizedString("home-themes-prompt", value: "Adjust your Reading preferences including text size and theme from the article tool bar or in your user settings for a more comfortable reading experience.", comment: "Description on feed card that describes how to adjust reading preferences.");
            cell.actionButton.setTitle(WMFLocalizedString("home-themes-action-title", value: "Manage preferences", comment: "Action on the feed card that describes the theme feature. Takes the user to manage theme preferences."), for:.normal)
        case .readingList:
            cell.isImageViewHidden = false
            cell.imageView.image = UIImage(named: "feed-card-reading-list")
            cell.imageViewDimension = cell.imageView.image?.size.height ?? 0
            cell.messageLabel.text = WMFLocalizedString("home-reading-list-prompt", value: "Your saved articles can now be organized into reading lists and synced across devices. Log in to allow your reading lists to be saved to your user preferences.", comment: "Description on feed card that describes reading lists.");
            cell.actionButton.setTitle(CommonStrings.readingListLoginButtonTitle, for:.normal)
        default:
            break
        }
        cell.apply(theme: theme)
        cell.delegate = self
    }
    
    private func configure(cell: UICollectionViewCell, forItemAt indexPath: IndexPath, with displayType: WMFFeedDisplayType, layoutOnly: Bool) {
        switch displayType {
        case .ranked, .page, .continueReading, .mainPage, .random, .pageWithPreview, .relatedPagesSourceArticle, .relatedPages, .compactList:
            configureArticleCell(cell, forItemAt: indexPath, with: displayType, layoutOnly: layoutOnly)
        case .pageWithLocation, .pageWithLocationPlaceholder:
            configureLocationCell(cell, forItemAt: indexPath, with: displayType, layoutOnly: layoutOnly)
        case .photo:
            configurePhotoCell(cell, layoutOnly: layoutOnly)
        case .story:
            configureNewsCell(cell, layoutOnly: layoutOnly)
        case .event:
            configureOnThisDayCell(cell, forItemAt: indexPath, layoutOnly: layoutOnly)
        case .theme, .notification, .announcement, .readingList:
            configureAnnouncementCell(cell, displayType: displayType, layoutOnly: layoutOnly)
        }
        cell.layoutMargins = layout.itemLayoutMargins
    }
    
    // MARK - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let displayType = displayTypeAt(indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: resuseIdentifierFor(displayType), for: indexPath)
        configure(cell: cell, forItemAt: indexPath, with: displayType, layoutOnly: false)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? ArticleCollectionViewCell, let article = article(at: indexPath) {
            delegate?.saveButtonsController.willDisplay(saveButton: cell.saveButton, for: article)
        }
        if cell is ArticleLocationExploreCollectionViewCell {
            visibleLocationCellCount += 1
            if WMFLocationManager.isAuthorized() {
                locationManager.startMonitoringLocation()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? ArticleCollectionViewCell, let article = article(at: indexPath) {
            delegate?.saveButtonsController.didEndDisplaying(saveButton: cell.saveButton, for: article)
        }
        if cell is ArticleLocationExploreCollectionViewCell {
            visibleLocationCellCount -= 1
            if visibleLocationCellCount == 0 {
                locationManager.stopMonitoringLocation()
            }
        }
        editController.deconfigureSwipeableCell(cell, forItemAt: indexPath)
    }
    
    // MARK - Detail views
    
    private func presentDetailViewControllerForItemAtIndexPath(_ indexPath: IndexPath, animated: Bool) {
        guard let detailType = contentGroup?.detailType, let vc = contentGroup?.detailViewControllerForPreviewItemAtIndex(indexPath.row, dataStore: dataStore, theme: theme) else {
            return
        }
        
        switch detailType {
        case .gallery:
            present(vc, animated: animated)
        default:
            wmf_push(vc, animated: animated)
        }
        
    }
    
    // MARK - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return contentGroup?.isSelectable ?? false
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        presentDetailViewControllerForItemAtIndexPath(indexPath, animated: true)
    }
    
    // MARK - ColumnarCollectionViewLayoutDelegate
    
    func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        let displayType = displayTypeAt(indexPath)
        let reuseIdentifier = resuseIdentifierFor(displayType)
        let key: String?
        if displayType == .story || displayType == .event, let contentGroupKey = contentGroup?.key {
            key = "\(contentGroupKey)-\(indexPath.row)"
        } else {
            key = article(at: indexPath)?.key
        }
        let userInfo = "\(key ?? "")-\(displayType.rawValue)"
        if let height = delegate?.layoutCache.cachedHeightForCellWithIdentifier(reuseIdentifier, columnWidth: columnWidth, userInfo: userInfo) {
            return ColumnarCollectionViewLayoutHeightEstimate(precalculated: true, height: height)
        }
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 100)
        guard let placeholderCell = layoutManager.placeholder(forCellWithReuseIdentifier: reuseIdentifier) as? CollectionViewCell else {
            return estimate
        }
        configure(cell: placeholderCell, forItemAt: indexPath, with: displayType, layoutOnly: true)
        let height = placeholderCell.sizeThatFits(CGSize(width: columnWidth, height: UIViewNoIntrinsicMetric), apply: false).height
        delegate?.layoutCache.setHeight(height, forCellWithIdentifier: reuseIdentifier, columnWidth: columnWidth, userInfo: userInfo)
        estimate.height = height
        estimate.precalculated = true
        return estimate
    }
    
    func collectionView(_ collectionView: UICollectionView, estimatedHeightForHeaderInSection section: Int, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        return ColumnarCollectionViewLayoutHeightEstimate(precalculated: true, height: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, estimatedHeightForFooterInSection section: Int, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        return ColumnarCollectionViewLayoutHeightEstimate(precalculated: true, height: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, prefersWiderColumnForSectionAt index: UInt) -> Bool {
        return true
    }
    
    func metrics(with size: CGSize, readableWidth: CGFloat, layoutMargins: UIEdgeInsets) -> ColumnarCollectionViewLayoutMetrics {
        let kind = contentGroup?.contentGroupKind ?? .unknown
        let itemLayoutMargins = ColumnarCollectionViewLayoutMetrics.defaultItemLayoutMargins
        let layoutMargins: UIEdgeInsets
        switch kind {
        case .topRead, .location, .locationPlaceholder, .onThisDay:
            layoutMargins = UIEdgeInsets(top: 25 - itemLayoutMargins.top, left: 0, bottom: 25 - itemLayoutMargins.bottom, right: 0) // add additional spacing around the section
        case .relatedPages:
            layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 25 - itemLayoutMargins.bottom, right: 0) // add additional spacing around the section
        default:
            layoutMargins = .zero
        }
        return ColumnarCollectionViewLayoutMetrics.exploreCardMetrics(with: size, readableWidth: size.width, layoutMargins: layoutMargins)

    }
}

extension ExploreCardViewController: ActionDelegate, ShareableArticlesProvider {
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

    func availableActions(at indexPath: IndexPath) -> [Action] {
        guard let article = article(at: indexPath) else {
            return []
        }
        
        var actions: [Action] = []
        
        if article.savedDate == nil {
            actions.append(ActionType.save.action(with: self, indexPath: indexPath))
        } else {
            actions.append(ActionType.unsave.action(with: self, indexPath: indexPath))
        }
        
        actions.append(ActionType.share.action(with: self, indexPath: indexPath))
        return actions
    }
    
    func didPerformAction(_ action: Action) -> Bool {
        let indexPath = action.indexPath
        let sourceView = collectionView.cellForItem(at: indexPath)
        switch action.type {
        case .save:
            if let articleURL = articleURL(at: indexPath) {
                dataStore.savedPageList.addSavedPage(with: articleURL)
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, CommonStrings.accessibilitySavedNotification)
                if let article = article(at: indexPath) {
                    delegate?.readingListHintController.didSave(true, article: article, theme: theme)
                    ReadingListsFunnel.shared.logSave(category: eventLoggingCategory, label: eventLoggingLabel, articleURL: articleURL)
                }
                return true
            }
        case .unsave:
            if let articleURL = articleURL(at: indexPath) {
                dataStore.savedPageList.removeEntry(with: articleURL)
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, CommonStrings.accessibilityUnsavedNotification)
                if let article = article(at: indexPath) {
                    delegate?.readingListHintController.didSave(false, article: article, theme: theme)
                    ReadingListsFunnel.shared.logUnsave(category: eventLoggingCategory, label: eventLoggingLabel, articleURL: articleURL)
                }
                return true
            }
        case .share:
            return share(article: article(at: indexPath), articleURL: articleURL(at: indexPath), at: indexPath, dataStore: dataStore, theme: theme, eventLoggingCategory: eventLoggingCategory, eventLoggingLabel: eventLoggingLabel, sourceView: sourceView)
        default:
            return false
        }
        return false
    }
}

extension ExploreCardViewController: SideScrollingCollectionViewCellDelegate {
    func sideScrollingCollectionViewCell(_ sideScrollingCollectionViewCell: SideScrollingCollectionViewCell, didSelectArticleWithURL articleURL: URL) {
        wmf_pushArticle(with: articleURL, dataStore: dataStore, theme: theme, animated: true)
    }
}

extension ExploreCardViewController: AnnouncementCollectionViewCellDelegate {
    func dismissAnnouncementCell(_ cell: AnnouncementCollectionViewCell) {
        contentGroup?.markDismissed()
        contentGroup?.updateVisibility()
        do {
            try dataStore.save()
        } catch let error {
            DDLogError("Error saving after cell dismissal: \(error)")
        }
    }
    
    func announcementCellDidTapDismiss(_ cell: AnnouncementCollectionViewCell) {
        dismissAnnouncementCell(cell)
    }
    
    func announcementCellDidTapActionButton(_ cell: AnnouncementCollectionViewCell) {
        guard let kind = contentGroup?.contentGroupKind else {
            return
        }
        switch kind {
        case .theme:
            NotificationCenter.default.post(name: .WMFNavigateToActivity, object: NSUserActivity.wmf_appearanceSettings())
            dismissAnnouncementCell(cell)
        case .readingList:
            wmf_showLoginViewController(theme: theme)
            LoginFunnel.shared.logLoginStartInFeed()
            dismissAnnouncementCell(cell)
        case .notification:
            WMFNotificationsController.shared().requestAuthenticationIfNecessary { (granted, error) in
                if let error = error {
                    self.wmf_showAlertWithError(error as NSError)
                }
            }
            UserDefaults.wmf_userDefaults().wmf_setInTheNewsNotificationsEnabled(true)
            dismissAnnouncementCell(cell)
        default:
            guard let announcement = contentGroup?.contentPreview as? WMFAnnouncement,
                let url = announcement.actionURL else {
                return
            }
            wmf_openExternalUrl(url)
            dismissAnnouncementCell(cell)
        }
    }
    
    func announcementCell(_ cell: AnnouncementCollectionViewCell, didTapLinkURL linkURL: URL) {
        wmf_openExternalUrl(linkURL)
    }
}

extension ExploreCardViewController: WMFArticlePreviewingActionsDelegate {
    func readMoreArticlePreviewActionSelected(withArticleController articleController: WMFArticleViewController) {
        
    }
    
    func saveArticlePreviewActionSelected(withArticleController articleController: WMFArticleViewController, didSave: Bool, articleURL: URL) {
        
    }
    
    func shareArticlePreviewActionSelected(withArticleController articleController: WMFArticleViewController, shareActivityController: UIActivityViewController) {
        
    }
    
    func viewOnMapArticlePreviewActionSelected(withArticleController articleController: WMFArticleViewController) {
        
    }
}

extension ExploreCardViewController {

    open override func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = collectionView.indexPathForItem(at: location),
            let cell = collectionView.cellForItem(at: indexPath) else {
            return nil
        }
        previewingContext.sourceRect = cell.frame
        guard let viewControllerToCommit = contentGroup?.detailViewControllerForPreviewItemAtIndex(indexPath.row, dataStore: dataStore, theme: theme) else {
            return nil
        }
        if let potd = viewControllerToCommit as? WMFImageGalleryViewController {
            potd.setOverlayViewTopBarHidden(true)
        } else if let avc = viewControllerToCommit as? WMFArticleViewController {
            avc.articlePreviewingActionsDelegate = self
            avc.wmf_addPeekableChildViewController(for: avc.articleURL, dataStore: dataStore, theme: theme)
        }
        return viewControllerToCommit
    }
    
    open override func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        if let potd = viewControllerToCommit as? WMFImageGalleryViewController {
            potd.setOverlayViewTopBarHidden(false)
            present(potd, animated: false)
        } else if let avc = viewControllerToCommit as? WMFArticleViewController {
            avc.wmf_removePeekableChildViewControllers()
            wmf_push(avc, animated: false)
        } else {
            wmf_push(viewControllerToCommit, animated: true)
        }
    }
}

extension ExploreCardViewController: ArticleLocationAuthorizationCollectionViewCellDelegate {
    func articleLocationAuthorizationCollectionViewCellDidTapAuthorize(_ cell: ArticleLocationAuthorizationCollectionViewCell) {
        UserDefaults.wmf_userDefaults().wmf_setExploreDidPromptForLocationAuthorization(true)
        if WMFLocationManager.isAuthorizationNotDetermined() {
            locationManager.startMonitoringLocation()
            return
        }
        UIApplication.shared.wmf_openAppSpecificSystemSettings()
    }
}

extension ExploreCardViewController: WMFLocationManagerDelegate {
    func updateLocationCells() {
        let userLocation = locationManager.location
        let heading = locationManager.heading
        for cell in collectionView.visibleCells {
            guard let cell = cell as? ArticleLocationExploreCollectionViewCell else {
                return
            }
            cell.update(userLocation: userLocation, heading: heading)
        }
    }
    
    func locationManager(_ controller: WMFLocationManager, didUpdate location: CLLocation) {
        updateLocationCells()
    }
    
    func locationManager(_ controller: WMFLocationManager, didUpdate heading: CLHeading) {
        updateLocationCells()
    }
    
    func locationManager(_ controller: WMFLocationManager, didChangeEnabledState enabled: Bool) {
        UserDefaults.wmf_userDefaults().wmf_setLocationAuthorized(enabled)
        dataStore.feedContentController.updateNearbyForce(false, completion: nil)
    }
}

extension ExploreCardViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        collectionView.backgroundColor = theme.colors.cardBackground
        view.backgroundColor = theme.colors.cardBackground
    }
}

extension ExploreCardViewController: AnalyticsContextProviding {
    var analyticsContext: String {
        return "explore"
    }
}

extension ExploreCardViewController: AnalyticsContentTypeProviding {
    var analyticsContentType: String {
        return contentGroup?.analyticsContentType ?? "unknown"
    }
}

extension ExploreCardViewController: EventLoggingEventValuesProviding {
    var eventLoggingLabel: EventLoggingLabel? {
        return contentGroup?.eventLoggingLabel
    }
    
    var eventLoggingCategory: EventLoggingCategory {
        return EventLoggingCategory.feed
    }
}
