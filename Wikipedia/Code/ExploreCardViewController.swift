import UIKit
import CocoaLumberjackSwift
import WMF

protocol ExploreCardViewControllerDelegate: NestedCollectionViewContextMenuDelegate {
    var saveButtonsController: SaveButtonsController { get }
    var layoutCache: ColumnarCollectionViewControllerLayoutCache { get }
    func exploreCardViewController(_ exploreCardViewController: ExploreCardViewController, didSelectItemAtIndexPath: IndexPath)
}

struct ExploreSaveButtonUserInfo {
    let indexPath: IndexPath
    let kind: WMFContentGroupKind?
    let midnightUTCDate: Date?
}

class ExploreCardViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, CardContent, ColumnarCollectionViewLayoutDelegate {
    
    weak var delegate: (ExploreCardViewControllerDelegate & UIViewController)?
    
    lazy var layoutManager: ColumnarCollectionViewLayoutManager = {
        return ColumnarCollectionViewLayoutManager(view: view, collectionView: collectionView)
    }()
    
    lazy var layout: ColumnarCollectionViewLayout = {
        return ColumnarCollectionViewLayout()
    }()
    
    lazy var locationManager: LocationManagerProtocol = {
        let locationManager = LocationManager()
        locationManager.delegate = self
        return locationManager
    }()
    
    deinit {
        if visibleLocationCellCount > 0 {
            locationManager.stopMonitoringLocation()
        }
    }
    
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
    
    // MARK: - View Lifecycle
    
    override func loadView() {
        super.loadView()
        self.view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
    }
    
    public func savedStateDidChangeForArticleWithKey(_ changedArticleKey: WMFInMemoryURLKey) {
        for i in 0..<numberOfItems {
            let indexPath = IndexPath(item: i, section: 0)
            guard
                let articleURL = articleURL(at: indexPath),
                let articleKey = articleURL.wmf_inMemoryKey,
                changedArticleKey == articleKey,
                let cell = collectionView.cellForItem(at: indexPath)
            else {
                continue
            }
            editController.configureSwipeableCell(cell, forItemAt: indexPath, layoutOnly: false)
        }
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
        layoutManager.register(SuggestedEditsExploreCell.self, forCellWithReuseIdentifier: SuggestedEditsExploreCell.identifier, addPlaceholder: true)
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
    
    // MARK: - Data
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
        contentHeightByWidth.removeAll()
        if visibleLocationCellCount > 0 {
            locationManager.stopMonitoringLocation()
        }
        visibleLocationCellCount = 0
        collectionView.reloadData()
    }
    
    var contentHeightByWidth: [Int: CGFloat] = [:]
    
    public func contentHeight(forWidth width: CGFloat) -> CGFloat {
        let widthInt = Int(round(width))
        if let cachedHeight = contentHeightByWidth[widthInt] {
            return cachedHeight
        }
        let height = layout.layoutHeight(forWidth: width)
        contentHeightByWidth[widthInt] = height
        return height
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
        case .suggestedEdits:
            return SuggestedEditsExploreCell.identifier
        default:
            return ArticleFullWidthImageExploreCollectionViewCell.identifier
        }
    }
    
    func articleURL(at indexPath: IndexPath) -> URL? {
        return contentGroup?.previewArticleURLForItemAtIndex(indexPath.row)
    }
    
    private func article(at indexPath: IndexPath) -> WMFArticle? {
        guard let url = articleURL(at: indexPath) else {
            return nil
        }
        return dataStore.fetchArticle(with: url)
    }
    
    // MARK: - cell configuration
    
    private func configureArticleCell(_ cell: UICollectionViewCell, forItemAt indexPath: IndexPath, with displayType: WMFFeedDisplayType, layoutOnly: Bool) {
        guard let cell = cell as? ArticleCollectionViewCell, let articleURL = articleURL(at: indexPath), let article = dataStore?.fetchArticle(with: articleURL) else {
            return
        }
        cell.configure(article: article, displayType: displayType, index: indexPath.row, theme: theme, layoutOnly: layoutOnly)
        if let fullWidthCell = cell as? ArticleFullWidthImageCollectionViewCell {
            fullWidthCell.saveButton.eventLoggingLabel = eventLoggingLabel
        }
        editController.configureSwipeableCell(cell, forItemAt: indexPath, layoutOnly: layoutOnly)
    }
    
    private func configureLocationCell(_ cell: UICollectionViewCell, forItemAt indexPath: IndexPath, with displayType: WMFFeedDisplayType, layoutOnly: Bool) {
        guard let cell = cell as? ArticleLocationExploreCollectionViewCell, let articleURL = articleURL(at: indexPath), let article = dataStore?.fetchArticle(with: articleURL) else {
            return
        }
        cell.configure(article: article, displayType: displayType, index: indexPath.row, theme: theme, layoutOnly: layoutOnly)
        if let authCell = cell as? ArticleLocationAuthorizationCollectionViewCell {
            if locationManager.isAuthorized {
                authCell.updateForLocationEnabled()
            } else {
                authCell.authorizeButton.setTitle(CommonStrings.localizedEnableLocationButtonTitle, for: .normal)
                authCell.authorizationDelegate = self
            }
            authCell.authorizeDescriptionLabel.text = CommonStrings.localizedEnableLocationDescription
        }
        guard !layoutOnly else {
            cell.configureForUnknownDistance()
            return
        }
        cell.articleLocation = article.location
        if locationManager.isAuthorized {
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
        guard let cell = cell as? OnThisDayExploreCollectionViewCell, let events = contentGroup?.contentPreview as? [WMFFeedOnThisDayEvent], !events.isEmpty, events.indices.contains(index) else {
            return
        }
        let event = events[index]
        cell.configure(with: event, isFirst: events.indices.first == index, isLast: events.indices.last == index, dataStore: dataStore, theme: theme, layoutOnly: layoutOnly)
        cell.selectionDelegate = self
    }

    var footerText: String? {
        if contentGroup?.contentGroupKind == .onThisDay,
            collectionView.numberOfSections == 1,
            let eventsCount = contentGroup?.countOfFullContent?.intValue {
            let otherEventsCount = eventsCount - collectionView.numberOfItems(inSection: 0)
            if otherEventsCount > 0 {
                return CommonStrings.onThisDayFooterWith(with: otherEventsCount)
            } else {
                return contentGroup?.footerText
            }
        } else {
            return contentGroup?.footerText
        }
    }
    
    private func configurePhotoCell(_ cell: UICollectionViewCell, layoutOnly: Bool) {
        guard let cell = cell as? ImageCollectionViewCell, let imageInfo = contentGroup?.contentPreview as? WMFFeedImage else {
            return
        }
        if !layoutOnly, let imageURL = contentGroup?.imageURLsCompatibleWithTraitCollection(traitCollection, dataStore: dataStore, viewSize: view.bounds.size)?.first {
            cell.imageView.wmf_setImage(with: imageURL, detectFaces: true, onGPU: true, failure: WMFIgnoreErrorHandler, success: WMFIgnoreSuccessHandler)
        }
        if !imageInfo.imageDescription.isEmpty {
            cell.captionIsRTL = imageInfo.imageDescriptionIsRTL
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
            guard
                let contentGroup = contentGroup,
                let announcement = contentGroup.contentPreview as? WMFAnnouncement
            else {
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
            cell.isUrgent = announcement.announcementType == .fundraising
            cell.messageHTML = announcement.text
            cell.actionButton.setTitle(announcement.actionTitle, for: .normal)
            cell.captionHTML = announcement.captionHTML
            cell.dismissButtonTitle = announcement.negativeText
            if let imageViewHeight = announcement.imageHeight?.doubleValue, imageViewHeight > 0 {
                cell.imageViewDimension = CGFloat(imageViewHeight)
            }
        case .notification:
            cell.isImageViewHidden = false
            cell.imageView.image = UIImage(named: "feed-card-notification")
            cell.imageViewDimension = cell.imageView.image?.size.height ?? 0
            cell.messageHTML = WMFLocalizedString("notifications-center-feed-news-notification-text", value: "Editing notifications for all Wikimedia projects are now available through the app. Opt in to push notifications to keep up to date with your messages on Wikipedia while on the go.", comment: "Text shown to users to notify them that it is now possible to get push notifications for all Wikimedia projects through the app")
            cell.actionButton.setTitle(WMFLocalizedString("notifications-center-feed-news-notification-button-text", value: "Turn on push notifications", comment: "Text for button to turn on push notifications"), for:.normal)
            cell.dismissButton.setTitle(WMFLocalizedString("notifications-center-feed-news-notification-dismiss-button-text", value: "Not now", comment: "Text for the dismiss button on the explore feed notifications card"), for: .normal)
        case .theme:
            cell.isImageViewHidden = false
            cell.imageView.image = UIImage(named: "feed-card-themes")
            cell.imageViewDimension = cell.imageView.image?.size.height ?? 0
            cell.messageHTML = WMFLocalizedString("home-themes-prompt", value: "Adjust your Reading preferences including text size and theme from the article tool bar or in your user settings for a more comfortable reading experience.", comment: "Description on feed card that describes how to adjust reading preferences.")
            cell.actionButton.setTitle(WMFLocalizedString("home-themes-action-title", value: "Manage preferences", comment: "Action on the feed card that describes the theme feature. Takes the user to manage theme preferences."), for:.normal)
        case .readingList:
            cell.isImageViewHidden = false
            cell.imageView.image = UIImage(named: "feed-card-reading-list")
            cell.imageViewDimension = cell.imageView.image?.size.height ?? 0
            cell.messageHTML = WMFLocalizedString("home-reading-list-prompt", value: "Your saved articles can now be organized into reading lists and synced across devices. Log in to allow your reading lists to be saved to your user preferences.", comment: "Description on feed card that describes reading lists.")
            cell.actionButton.setTitle(CommonStrings.readingListLoginButtonTitle, for:.normal)
        default:
            break
        }
        cell.apply(theme: theme)
        cell.delegate = self
    }
    
    private func configure(cell: UICollectionViewCell, forItemAt indexPath: IndexPath, with displayType: WMFFeedDisplayType, layoutOnly: Bool) {
        switch displayType {
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
        case .suggestedEdits:
            configureSuggestedEditsCell(cell, layoutOnly: layoutOnly)
        default:
            configureArticleCell(cell, forItemAt: indexPath, with: displayType, layoutOnly: layoutOnly)
        }
        cell.layoutMargins = layout.itemLayoutMargins
    }
    
    private func configureSuggestedEditsCell(_ cell: UICollectionViewCell, layoutOnly: Bool) {
        guard let cell = cell as? SuggestedEditsExploreCell else {
            return
        }
        
        let languageCode = dataStore.languageLinkController.appLanguage?.languageCode
        
        cell.title = WMFLocalizedString("explore-suggested-edits-image-recs-title", languageCode: languageCode, value: "Add an image", comment: "Title text shown in the image recommendations explore feed card.")
        cell.body = WMFLocalizedString("explore-suggested-edits-image-recs-body", languageCode: languageCode, value: "Add suggested images to Wikipedia articles to enhance understanding.", comment: "Body text shown in the image recommendations explore feed card.")
        cell.apply(theme: theme)
    }

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

    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let displayType = displayTypeAt(indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: resuseIdentifierFor(displayType), for: indexPath)
        configure(cell: cell, forItemAt: indexPath, with: displayType, layoutOnly: false)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? ArticleFullWidthImageCollectionViewCell, let article = article(at: indexPath) {
            delegate?.saveButtonsController.willDisplay(saveButton: cell.saveButton, for: article, with: ExploreSaveButtonUserInfo(indexPath: indexPath, kind: contentGroup?.contentGroupKind, midnightUTCDate: contentGroup?.midnightUTCDate))
        }
        if cell is ArticleLocationExploreCollectionViewCell {
            visibleLocationCellCount += 1
            if locationManager.isAuthorized {
                locationManager.startMonitoringLocation()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? ArticleFullWidthImageCollectionViewCell, let article = article(at: indexPath) {
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
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return contentGroup?.isSelectable ?? false
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.exploreCardViewController(self, didSelectItemAtIndexPath: indexPath)
    }
    
    // MARK: - ColumnarCollectionViewLayoutDelegate
    
    func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        let displayType = displayTypeAt(indexPath)
        let reuseIdentifier = resuseIdentifierFor(displayType)
        let key: String?
        let articleKey: WMFInMemoryURLKey? = self.article(at: indexPath)?.inMemoryKey
        let groupKey: WMFInMemoryURLKey? = contentGroup?.inMemoryKey
        if displayType == .story || displayType == .event, let contentGroupKey = contentGroup?.inMemoryKey {
            key = "\(contentGroupKey.userInfoString)-\(indexPath.row)"
        } else {
            key = articleKey?.userInfoString ?? groupKey?.userInfoString
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
        let height = placeholderCell.sizeThatFits(CGSize(width: columnWidth, height: UIView.noIntrinsicMetric), apply: false).height
        delegate?.layoutCache.setHeight(height, forCellWithIdentifier: reuseIdentifier, columnWidth: columnWidth, groupKey: groupKey, articleKey: articleKey, userInfo: userInfo)
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

    func collectionView(_ collectionView: UICollectionView, shouldShowFooterForSection section: Int) -> Bool {
        return false
    }
    
    func metrics(with size: CGSize, readableWidth: CGFloat, layoutMargins: UIEdgeInsets) -> ColumnarCollectionViewLayoutMetrics {
        let kind = contentGroup?.contentGroupKind ?? .unknown
        let itemLayoutMargins = ColumnarCollectionViewLayoutMetrics.defaultItemLayoutMargins
        let layoutMargins: UIEdgeInsets
        
        // add additional spacing around the section
        switch kind {
        case .location:
            layoutMargins = UIEdgeInsets(top: 18 - itemLayoutMargins.top, left: 0, bottom: 18 - itemLayoutMargins.bottom, right: 0)
        case .locationPlaceholder:
            layoutMargins = UIEdgeInsets(top: 22 - itemLayoutMargins.top, left: 0, bottom: 10 - itemLayoutMargins.bottom, right: 0)
        case .topRead:
            layoutMargins = UIEdgeInsets(top: 22 - itemLayoutMargins.top, left: 0, bottom: 22 - itemLayoutMargins.bottom, right: 0)
        case .onThisDay:
            layoutMargins = UIEdgeInsets(top: 22 - itemLayoutMargins.top, left: 0, bottom: 20 - itemLayoutMargins.bottom, right: 0)
        case .relatedPages:
            layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 25 - itemLayoutMargins.bottom, right: 0)
        default:
            layoutMargins = .zero
        }
        
        return ColumnarCollectionViewLayoutMetrics.exploreCardMetrics(with: size, readableWidth: size.width, layoutMargins: layoutMargins)
    }
    
    func userDidTapTurnOnNotifications() {
        let pushSettingsVC = PushNotificationsSettingsViewController.init(authenticationManager: self.dataStore.authenticationManager, notificationsController: self.dataStore.notificationsController)
        pushSettingsVC.apply(theme: self.theme)
        self.navigationController?.pushViewController(pushSettingsVC, animated: true)
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
        let cancel = ReadingListsAlertActionType.cancel.action()
        let delete = ReadingListsAlertActionType.unsave.action { _ = self.editController.didPerformAction(action) }
        let actions = [cancel, delete]
        alertController.showAlertIfNeeded(presenter: self, for: [article], with: actions) { showed in
            if !showed {
                _ = self.editController.didPerformAction(action)
            }
        }
        return true
    }

    func availableActions(at indexPath: IndexPath) -> [Action] {
        guard let article = article(at: indexPath) else {
            return []
        }
        
        var actions: [Action] = []
        
        if article.isAnyVariantSaved {
            actions.append(ActionType.unsave.action(with: self, indexPath: indexPath))
        } else {
            actions.append(ActionType.save.action(with: self, indexPath: indexPath))
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
                UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: CommonStrings.accessibilitySavedNotification)
                if let date = contentGroup?.midnightUTCDate {
                    ReadingListsFunnel.shared.logSaveInFeed(label: contentGroup?.getAnalyticsLabel(), measureAge: date, articleURL: articleURL, index: action.indexPath.item)
                }
                return true
            }
        case .unsave:
            if let articleURL = articleURL(at: indexPath) {
                dataStore.savedPageList.removeEntry(with: articleURL)
                UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: CommonStrings.accessibilityUnsavedNotification)
                if let date = contentGroup?.midnightUTCDate {
                    ReadingListsFunnel.shared.logUnsaveInFeed(label: contentGroup?.getAnalyticsLabel(), measureAge: date, articleURL: articleURL, index: action.indexPath.item)
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
    func sideScrollingCollectionViewCell(_ sideScrollingCollectionViewCell: SideScrollingCollectionViewCell, didSelectArticleWithURL articleURL: URL, at indexPath: IndexPath) {
        navigate(to: articleURL)
    }
}

extension ExploreCardViewController: AnnouncementCollectionViewCellDelegate {
    func dismissAnnouncementCell(_ cell: AnnouncementCollectionViewCell) {
        contentGroup?.markDismissed()
        let isLoggedIn = dataStore.authenticationManager.authStateIsPermanent
        contentGroup?.updateVisibilityForUserIsLogged(in: isLoggedIn)
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
            userDidTapTurnOnNotifications()
            dismissAnnouncementCell(cell)
        default:
            guard let announcement = contentGroup?.contentPreview as? WMFAnnouncement,
                let url = announcement.actionURL else {
                return
            }
            navigate(to: url, useSafari: true)
            dismissAnnouncementCell(cell)
        }
    }
    
    func announcementCell(_ cell: AnnouncementCollectionViewCell, didTapLinkURL linkURL: URL) {
        navigate(to: linkURL, useSafari: true)
    }
}

extension ExploreCardViewController: ArticlePreviewingDelegate {
    func readMoreArticlePreviewActionSelected(with articleController: ArticleViewController) {
        articleController.wmf_removePeekableChildViewControllers()
        push(articleController, animated: true)
    }
    
    func saveArticlePreviewActionSelected(with articleController: ArticleViewController, didSave: Bool, articleURL: URL) {
        
    }
    
    func shareArticlePreviewActionSelected(with articleController: ArticleViewController, shareActivityController: UIActivityViewController) {
        articleController.wmf_removePeekableChildViewControllers()
        present(shareActivityController, animated: true, completion: nil)
    }
    
    func viewOnMapArticlePreviewActionSelected(with articleController: ArticleViewController) {
        articleController.wmf_removePeekableChildViewControllers()
        let placesURL = NSUserActivity.wmf_URLForActivity(of: .places, withArticleURL: articleController.articleURL)
        UIApplication.shared.open(placesURL)
    }
}

extension ExploreCardViewController: ArticleLocationAuthorizationCollectionViewCellDelegate {
    func articleLocationAuthorizationCollectionViewCellDidTapAuthorize(_ cell: ArticleLocationAuthorizationCollectionViewCell) {
        UserDefaults.standard.wmf_setExploreDidPromptForLocationAuthorization(true)
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.startMonitoringLocation()
            return
        }
        UIApplication.shared.wmf_openAppSpecificSystemSettings()
    }
}

extension ExploreCardViewController: LocationManagerDelegate {
    func locationManager(_ locationManager: LocationManagerProtocol, didUpdate location: CLLocation) {
        updateLocationCells()
    }

    func locationManager(_ locationManager: LocationManagerProtocol, didUpdate heading: CLHeading) {
        updateLocationCells()
    }

    func locationManager(_ locationManager: LocationManagerProtocol, didUpdateAuthorized authorized: Bool) {
        UserDefaults.standard.wmf_setLocationAuthorized(authorized)

        for cell in collectionView.visibleCells {
            guard let cell = cell as? ArticleLocationAuthorizationCollectionViewCell, locationManager.isAuthorized else {
                return
            }
            cell.updateForLocationEnabled()
        }
        dataStore.feedContentController.updateContentSource(WMFNearbyContentSource.self, force: false, completion: nil)
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

extension ExploreCardViewController: MEPEventsProviding {
    var eventLoggingLabel: EventLabelMEP? {
        return contentGroup?.getAnalyticsLabel()
    }
    
    var eventLoggingCategory: EventCategoryMEP {
        return .feed
    }

}

// MARK: - Context Menu
extension ExploreCardViewController {
    public func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard indexPath.item < numberOfItems else {
            return nil
        }

        return delegate?.contextMenu(with: contentGroup, for: nil, at: indexPath.item)
    }

    public func collectionView(_ collectionView: UICollectionView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        delegate?.willCommitPreview(with: animator)
    }
}
