import UIKit

protocol ExploreCardViewControllerDelegate {
    var saveButtonsController: SaveButtonsController { get }
    var readingListHintController: ReadingListHintController { get }
    var layoutCache: ColumnarCollectionViewControllerLayoutCache { get }
}

class ExploreCardViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, CardContent, WMFColumnarCollectionViewLayoutDelegate {
    weak var delegate: (ExploreCardViewControllerDelegate & UIViewController)?
    
    lazy var layoutManager: ColumnarCollectionViewLayoutManager = {
        return ColumnarCollectionViewLayoutManager(view: view, collectionView: collectionView)
    }()
    
    lazy var layout: WMFColumnarCollectionViewLayout = {
        return WMFColumnarCollectionViewLayout()
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
        layoutManager.register(ArticleRightAlignedImageCollectionViewCell.self, forCellWithReuseIdentifier: ArticleRightAlignedImageCollectionViewCell.identifier, addPlaceholder: true)
        layoutManager.register(RankedArticleCollectionViewCell.self, forCellWithReuseIdentifier: RankedArticleCollectionViewCell.identifier, addPlaceholder: true)
        layoutManager.register(ArticleFullWidthImageCollectionViewCell.self, forCellWithReuseIdentifier: ArticleFullWidthImageCollectionViewCell.identifier, addPlaceholder: true)
        layoutManager.register(NewsCollectionViewCell.self, forCellWithReuseIdentifier: NewsCollectionViewCell.identifier, addPlaceholder: true)
        layoutManager.register(OnThisDayExploreCollectionViewCell.self, forCellWithReuseIdentifier: OnThisDayExploreCollectionViewCell.identifier, addPlaceholder: true)
        layoutManager.register(ArticleLocationCollectionViewCell.self, forCellWithReuseIdentifier: ArticleLocationCollectionViewCell.identifier, addPlaceholder: true)
        layoutManager.register(ImageCollectionViewCell.self, forCellWithReuseIdentifier: ImageCollectionViewCell.identifier, addPlaceholder: true)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        for indexPath in collectionView.indexPathsForSelectedItems ?? [] {
            collectionView.deselectItem(at: indexPath, animated: animated)
        }
    }
    
    // MARK - Data
    
    public var contentGroup: WMFContentGroup? {
        didSet {
            collectionView.reloadData()
        }
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
        guard let contentGroup = contentGroup else {
            return 0
        }
        
        guard let preview = contentGroup.contentPreview as? [Any] else {
            return 1
        }
        let countOfFeedContent = preview.count
        switch contentGroup.contentGroupKind {
        case .news:
            return 1
        case .onThisDay:
            return 1
        case .relatedPages:
            return min(countOfFeedContent, Int(contentGroup.maxNumberOfCells()) + 1)
        default:
            return min(countOfFeedContent, Int(contentGroup.maxNumberOfCells()))
        }
    }
    
    private func menuActionSheetForGroup(_ group: WMFContentGroup) -> UIAlertController? {
        switch group.contentGroupKind {
        case .relatedPages:
            guard let url = group.headerContentURL() else {
                return nil
            }
            let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            sheet.addAction(UIAlertAction(title: WMFLocalizedString("home-hide-suggestion-prompt", value: "Hide this suggestion", comment: "Title of button shown for users to confirm the hiding of a suggestion in the explore feed"), style: .destructive, handler: { (action) in
                self.dataStore.setIsExcludedFromFeed(true, withArticleURL: url)
                self.dataStore.viewContext.remove(group)
            }))
            sheet.addAction(UIAlertAction(title: WMFLocalizedString("home-hide-suggestion-cancel", value: "Cancel", comment: "Title of the button for cancelling the hiding of an explore feed suggestion\n{{Identical|Cancel}}"), style: .cancel, handler: nil))
            return sheet
        case .locationPlaceholder:
            let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            sheet.addAction(UIAlertAction(title: WMFLocalizedString("explore-nearby-placeholder-dismiss", value: "Dismiss", comment: "Action button that will dismiss the nearby placeholder\n{{Identical|Dismiss}}"), style: .destructive, handler: { (action) in
                UserDefaults.wmf_userDefaults().wmf_setPlacesDidPromptForLocationAuthorization(true)
                group.wasDismissed = true
                group.updateVisibility()
            }))
            sheet.addAction(UIAlertAction(title: WMFLocalizedString("explore-nearby-placeholder-cancel", value: "Cancel", comment: "Action button that will cancel dismissal of the nearby placeholder\n{{Identical|Cancel}}"), style: .cancel, handler: nil))
            return sheet
        default:
            return nil
        }
    }
    
    private func displayTypeAt(_ indexPath: IndexPath) -> WMFFeedDisplayType {
        return contentGroup?.displayTypeForItem(at: indexPath.row) ?? .page
    }
    
    private func resuseIdentifierFor(_ displayType: WMFFeedDisplayType) -> String {
        switch displayType {
        case .ranked:
            return RankedArticleCollectionViewCell.identifier
        case .story:
            return NewsCollectionViewCell.identifier
        case .event:
            return OnThisDayExploreCollectionViewCell.identifier
        case .continueReading:
            fallthrough
        case .relatedPagesSourceArticle:
            fallthrough
        case .random:
            fallthrough
        case .pageWithPreview:
            return ArticleFullWidthImageCollectionViewCell.identifier
        case .photo:
            return ImageCollectionViewCell.identifier
        case .pageWithLocation:
            return ArticleLocationCollectionViewCell.identifier
        case .page, .relatedPages, .mainPage, .compactList:
            return ArticleRightAlignedImageCollectionViewCell.identifier
        case .announcement, .notification, .theme, .readingList:
            return AnnouncementCollectionViewCell.identifier
        }
    }
    
    private func article(forItemAt indexPath: IndexPath) -> WMFArticle? {
        guard let url = articleURL(forItemAt: indexPath) else {
            return nil
        }
        return dataStore.fetchArticle(with: url)
    }
    
    private func articleURL(forItemAt indexPath: IndexPath) -> URL? {
        guard let contentGroup = contentGroup else {
            return nil
        }
        let displayType = contentGroup.displayTypeForItem(at: indexPath.row)
        var index = indexPath.row
        switch displayType {
        case .relatedPagesSourceArticle:
            return contentGroup.articleURL
        case .relatedPages:
            index = indexPath.row - 1
        case .ranked:
            guard let content = contentGroup.contentPreview as? [WMFFeedTopReadArticlePreview], content.count > indexPath.row else {
                return nil
            }
            return content[indexPath.row].articleURL
        default:
            break
        }
        
        if let contentURL = contentGroup.contentPreview as? URL {
            return contentURL
        }
        
        guard let content = contentGroup.contentPreview as? [URL], content.count > index else {
            return nil
        }
        
        return content[index]
    }
    
    var eventLoggingLabel: EventLoggingLabel? {
        return contentGroup?.eventLoggingLabel
    }
    
    // MARK - cell configuration
    
    private func configureArticleCell(_ cell: UICollectionViewCell, forItemAt indexPath: IndexPath, with displayType: WMFFeedDisplayType, layoutOnly: Bool) {
        guard let cell = cell as? ArticleCollectionViewCell, let articleURL = articleURL(forItemAt: indexPath), let article = dataStore?.fetchArticle(with: articleURL) else {
            return
        }
        cell.configure(article: article, displayType: displayType, index: indexPath.row, count: numberOfItems, shouldAdjustMargins: true, theme: theme, layoutOnly: layoutOnly)
        cell.saveButton.eventLoggingLabel = eventLoggingLabel
    }
    
    private func configureLocationCell(_ cell: UICollectionViewCell, forItemAt indexPath: IndexPath, with displayType: WMFFeedDisplayType, layoutOnly: Bool) {
        guard let cell = cell as? ArticleLocationCollectionViewCell, let articleURL = articleURL(forItemAt: indexPath), let article = dataStore?.fetchArticle(with: articleURL) else {
            return
        }
        cell.configure(article: article, displayType: .pageWithLocation, index: indexPath.row, count: numberOfItems, shouldAdjustMargins: true, theme: theme, layoutOnly: layoutOnly)
        cell.distanceLabel.text = "unknown distance"
    }
    
    private func configureNewsCell(_ cell: UICollectionViewCell, layoutOnly: Bool) {
        guard let cell = cell as? NewsCollectionViewCell, let story = contentGroup?.contentPreview as? WMFFeedNewsStory else {
            return
        }
        cell.configure(with: story, dataStore: dataStore, theme: theme, layoutOnly: layoutOnly)
    }
    
    private func configureOnThisDayCell(_ cell: UICollectionViewCell, layoutOnly: Bool) {
        guard let cell = cell as? OnThisDayExploreCollectionViewCell, let events = contentGroup?.contentPreview as? [WMFFeedOnThisDayEvent], events.count > 0 else {
            return
        }
        let previousEvent: WMFFeedOnThisDayEvent? = events.count > 1 ? events[1] : events[0]
        cell.configure(with: events[0], previousEvent: previousEvent, dataStore: dataStore, theme: theme, layoutOnly: layoutOnly)
    }
    
    private func configurePhotoCell(_ cell: UICollectionViewCell, layoutOnly: Bool) {
        guard let cell = cell as? ImageCollectionViewCell, let imageInfo = contentGroup?.contentPreview as? WMFFeedImage else {
            return
        }
        
        let imageURL: URL? = URL(string: WMFChangeImageSourceURLSizePrefix(imageInfo.imageThumbURL.absoluteString, traitCollection.wmf_articleImageWidth))
        cell.imageView.setImageWith(imageURL ?? imageInfo.imageThumbURL)
        if imageInfo.imageDescription.count > 0 {
            cell.captionLabel.text = imageInfo.imageDescription.wmf_stringByRemovingHTML()
        } else {
            cell.captionLabel.text = imageInfo.canonicalPageTitle
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
        case .pageWithLocation:
            configureLocationCell(cell, forItemAt: indexPath, with: displayType, layoutOnly: layoutOnly)
        case .photo:
            configurePhotoCell(cell, layoutOnly: layoutOnly)
        case .story:
            configureNewsCell(cell, layoutOnly: layoutOnly)
        case .event:
             configureOnThisDayCell(cell, layoutOnly: layoutOnly)
        case .theme, .notification, .announcement, .readingList:
            configureAnnouncementCell(cell, displayType: displayType, layoutOnly: layoutOnly)
        }
    }
    
    // MARK - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let displayType = displayTypeAt(indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: resuseIdentifierFor(displayType), for: indexPath)
        configure(cell: cell, forItemAt: indexPath, with: displayType, layoutOnly: false)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? ArticleCollectionViewCell, let article = article(forItemAt: indexPath) {
            delegate?.saveButtonsController.willDisplay(saveButton: cell.saveButton, for: article)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? ArticleCollectionViewCell, let article = article(forItemAt: indexPath) {
            delegate?.saveButtonsController.didEndDisplaying(saveButton: cell.saveButton, for: article)
        }
    }
    
    // MARK - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let articleURL = articleURL(forItemAt: indexPath) else {
            return
        }
        wmf_pushArticle(with: articleURL, dataStore: dataStore, theme: theme, animated: true)
    }
    
    // MARK - WMFColumnarCollectionViewLayoutDelegate
    
    func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> WMFLayoutEstimate {
        let displayType = displayTypeAt(indexPath)
        let reuseIdentifier = resuseIdentifierFor(displayType)
        let key: String?
        if displayType == .story || displayType == .event {
            key = contentGroup?.key
        } else {
            key = article(forItemAt: indexPath)?.key
        }
        let userInfo = "\(key ?? "")-\(displayType.rawValue)"
        if let height = delegate?.layoutCache.cachedHeightForCellWithIdentifier(reuseIdentifier, columnWidth: columnWidth, userInfo: userInfo) {
            return WMFLayoutEstimate(precalculated: true, height: height)
        }
        var estimate = WMFLayoutEstimate(precalculated: false, height: 100)
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
    
    func collectionView(_ collectionView: UICollectionView, estimatedHeightForHeaderInSection section: Int, forColumnWidth columnWidth: CGFloat) -> WMFLayoutEstimate {
        return WMFLayoutEstimate(precalculated: true, height: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, estimatedHeightForFooterInSection section: Int, forColumnWidth columnWidth: CGFloat) -> WMFLayoutEstimate {
        return WMFLayoutEstimate(precalculated: true, height: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, prefersWiderColumnForSectionAt index: UInt) -> Bool {
        return index % 2 == 0
    }
    
    func metrics(withBoundsSize size: CGSize, readableWidth: CGFloat) -> WMFCVLMetrics {
        return WMFCVLMetrics.singleColumnMetrics(withBoundsSize: size, readableWidth: readableWidth, interItemSpacing: 0, interSectionSpacing: 0)
    }
}

extension ExploreCardViewController: AnnouncementCollectionViewCellDelegate {
    func announcementCellDidTapDismiss(_ cell: AnnouncementCollectionViewCell) {
        
    }
    
    func announcementCellDidTapActionButton(_ cell: AnnouncementCollectionViewCell) {
        
    }
    
    func announcementCell(_ cell: AnnouncementCollectionViewCell, didTapLinkURL: URL) {
        
    }
}

