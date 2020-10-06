
import UIKit
import CocoaLumberjackSwift

protocol TalkPageReplyListViewControllerDelegate: class {
    func tappedLink(_ url: URL, viewController: TalkPageReplyListViewController, sourceView: UIView, sourceRect: CGRect?)
    func tappedPublish(topic: TalkPageTopic, composeText: String, viewController: TalkPageReplyListViewController)
    func didTriggerRefresh(viewController: TalkPageReplyListViewController)
}

class TalkPageReplyListViewController: ColumnarCollectionViewController {
    
    weak var delegate: TalkPageReplyListViewControllerDelegate?
    
    let topic: TalkPageTopic
    private let dataStore: MWKDataStore
    private var fetchedResultsController: NSFetchedResultsController<TalkPageReply>
    
    private let reuseIdentifier = "TalkPageReplyCell"
    
    private var collectionViewUpdater: CollectionViewUpdater<TalkPageReply>!

    private lazy var beKindInputAccessoryView: BeKindInputAccessoryView = BeKindInputAccessoryView.wmf_viewFromClassNib()
    
    private lazy var publishButton: UIBarButtonItem = {
        let publishButton = UIBarButtonItem(title: CommonStrings.publishTitle, style: .done, target: self, action: #selector(tappedPublish(_:)))
        publishButton.tintColor = theme.colors.link
        return publishButton
    }()
    
    private var composeText: String?
    private var footerView: TalkPageReplyFooterView?
    private var originalFooterViewFrame: CGRect?
    
    private var backgroundTapGestureRecognizer: UITapGestureRecognizer!
    private var replyBarButtonItem: UIBarButtonItem?
    
    private var shouldFocusVoiceOver = false
    private var headerView: TalkPageHeaderView?
    
    var repliesAreDisabled = true {
        didSet {
            footerView?.composeButtonIsDisabled = repliesAreDisabled
            replyBarButtonItem?.isEnabled = !repliesAreDisabled
        }
    }

    private var showingCompose = false {
        didSet {
            if showingCompose != oldValue {
                
                shouldFocusVoiceOver = true
                footerView?.showingCompose = showingCompose
                
                if let layoutCopy = layout.copy() as? ColumnarCollectionViewLayout {
                    collectionView.setCollectionViewLayout(layoutCopy, animated: true)
                    if showingCompose == true {
                        scrollToBottom()
                    }
                } else {
                    collectionView.reloadData()
                    collectionView.layoutIfNeeded()
                    scrollToBottom()
                }
                
                let nextFocus = showingCompose ? footerView?.composeTextView: nil
                UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: nextFocus)
            }
            
            if showingCompose {
                publishButton.isEnabled = false
                navigationItem.rightBarButtonItem = publishButton
                navigationItem.title = replyString
                if #available(iOS 14.0, *) {
                    navigationItem.backButtonTitle = replyString
                }
                navigationBar.updateNavigationItems()
            } else {
                navigationItem.rightBarButtonItem = replyBarButtonItem
                navigationBar.updateNavigationItems()
            }
            reloadInputViews()
        }
    }
    
    lazy private(set) var fakeProgressController: FakeProgressController = {
        let progressController = FakeProgressController(progress: navigationBar, delegate: navigationBar)
        progressController.delay = 0.0
        return progressController
    }()
    
    private let replyString = WMFLocalizedString("talk-page-reply-title", value: "Reply", comment: "This header label is displayed at the top of a talk page thread once the user taps Reply.")
    
    private let talkPageSemanticContentAttribute: UISemanticContentAttribute
    
    required init(dataStore: MWKDataStore, topic: TalkPageTopic, talkPageSemanticContentAttribute: UISemanticContentAttribute) {
        self.dataStore = dataStore
        self.topic = topic
        self.talkPageSemanticContentAttribute = talkPageSemanticContentAttribute
        
        let request: NSFetchRequest<TalkPageReply> = TalkPageReply.fetchRequest()
        request.predicate = NSPredicate(format: "topic == %@",  topic)
        request.sortDescriptors = [NSSortDescriptor(key: "sort", ascending: true)]
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: dataStore.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        isRefreshControlEnabled = true
        registerCells()
        setupCollectionViewUpdater()
        setupBackgroundTap()
        setupNavigationBar()
        
        collectionView.keyboardDismissMode = .interactive
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override var inputAccessoryView: UIView? {
        return showingCompose ? beKindInputAccessoryView : nil
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !topic.isRead {
            topic.isRead = true
            do {
                try dataStore.viewContext.save()
            } catch let error {
                DDLogError("Error saving after marking topic as read: \(error)")
            }
        }
    }
    
    func postDidBegin() {
        fakeProgressController.start()
        publishButton.isEnabled = false
        footerView?.composeTextView.isUserInteractionEnabled = false
    }
    
    func postDidEnd() {
        fakeProgressController.stop()
        publishButton.isEnabled = true
        showingCompose = false
        footerView?.resetCompose()
    }
    
    func announcePostSuccessful() {
        NotificationCenter.default.addObserver(self, selector: #selector(announcementDidFinish(notification:)), name: UIAccessibility.announcementDidFinishNotification, object: nil)
        UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: CommonStrings.successfullyPublishedReply)
    }
    
    @objc private func announcementDidFinish(notification: NSNotification) {
        postDidEnd()
        UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: headerView?.titleTextView)
        NotificationCenter.default.removeObserver(self, name: UIAccessibility.announcementDidFinishNotification, object: nil)
    }
    
    override func keyboardDidChangeFrame(from oldKeyboardFrame: CGRect?, newKeyboardFrame: CGRect?) {
        super.keyboardDidChangeFrame(from: oldKeyboardFrame, newKeyboardFrame: newKeyboardFrame)
        
        //animate content offset so text view is in window
        guard let composeTextView = footerView?.composeTextView,
        let newKeyboardFrame = newKeyboardFrame,
        newKeyboardFrame.minY < (view.bounds.height - beKindInputAccessoryView.frame.height),
        traitCollection.verticalSizeClass == .compact else {
            return
        }
        
        let convertedRect = view.convert(composeTextView.frame, from: composeTextView.superview)
        let delta = convertedRect.minY - navigationBar.visibleHeight
        
        let contentOffset = collectionView.contentOffset

        collectionView.setContentOffset(CGPoint(x: contentOffset.x, y: contentOffset.y + delta), animated: true)
    }
    
    override func refresh() {
        delegate?.didTriggerRefresh(viewController: self)
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let sectionsCount = fetchedResultsController.sections?.count else {
                return 0
        }
        return sectionsCount
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let sections = fetchedResultsController.sections,
            section < sections.count else {
                return 0
        }
        return sections[section].numberOfObjects
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? TalkPageReplyCell else {
                return UICollectionViewCell()
        }
        
        configure(cell: cell, at: indexPath)
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 54)
        guard let placeholderCell = layoutManager.placeholder(forCellWithReuseIdentifier: reuseIdentifier) as? TalkPageReplyCell else {
            return estimate
        }
        configure(cell: placeholderCell, at: indexPath)
        estimate.height = placeholderCell.sizeThatFits(CGSize(width: columnWidth, height: UIView.noIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        return estimate
    }
    
    override func metrics(with size: CGSize, readableWidth: CGFloat, layoutMargins: UIEdgeInsets) -> ColumnarCollectionViewLayoutMetrics {
        return ColumnarCollectionViewLayoutMetrics.tableViewMetrics(with: size, readableWidth: readableWidth, layoutMargins: layoutMargins)
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionView.elementKindSectionFooter,
            let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: TalkPageReplyFooterView.identifier, for: indexPath) as? TalkPageReplyFooterView {
            self.footerView = footer
            configure(footer: footer)
            self.footerView = footer
            return footer
        }
        
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        
        if elementKind == UICollectionView.elementKindSectionFooter,
            let footer = view as? TalkPageReplyFooterView {
            if shouldFocusVoiceOver {
                UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: footer.composeTextView)
                shouldFocusVoiceOver = false
            }
        }
        
    }

    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForFooterInSection section: Int, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 100)
        guard let footer = layoutManager.placeholder(forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: TalkPageReplyFooterView.identifier) as? TalkPageReplyFooterView else {
            return estimate
        }
        configure(footer: footer)
        footer.composeTextView.inputAccessoryView = beKindInputAccessoryView
        estimate.height = footer.sizeThatFits(CGSize(width: columnWidth, height: UIView.noIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        return estimate
    }

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        
        guard viewIfLoaded != nil else {
            return
        }
        
        view.backgroundColor = theme.colors.paperBackground
        beKindInputAccessoryView.apply(theme: theme)
        headerView?.apply(theme: theme)
    }
}

//MARK: CollectionViewUpdaterDelegate

extension TalkPageReplyListViewController: CollectionViewUpdaterDelegate {
    func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, didUpdate collectionView: UICollectionView) where T : NSFetchRequestResult {
        for indexPath in collectionView.indexPathsForVisibleItems {
            guard let cell = collectionView.cellForItem(at: indexPath) as? TalkPageTopicCell,
                let title = fetchedResultsController.object(at: indexPath).text else {
                    continue
            }
            
            cell.configure(title: title)
        }
    }
    
    func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, updateItemAtIndexPath indexPath: IndexPath, in collectionView: UICollectionView) where T : NSFetchRequestResult {
        //no-op
    }
}

//MARK: Private

private extension TalkPageReplyListViewController {
    
    func registerCells() {
        layoutManager.register(TalkPageReplyCell.self, forCellWithReuseIdentifier: reuseIdentifier, addPlaceholder: true)
        layoutManager.register(TalkPageReplyFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: TalkPageReplyFooterView.identifier, addPlaceholder: true)
    }
    
    func setupCollectionViewUpdater() {
        collectionViewUpdater = CollectionViewUpdater(fetchedResultsController: fetchedResultsController, collectionView: collectionView)
        collectionViewUpdater?.delegate = self
        collectionViewUpdater?.performFetch()
    }
    
    func setupNavigationBar() {
        navigationBar.isBarHidingEnabled = false
        navigationBar.allowsUnderbarHitsFallThrough = true
        let replyImage = UIImage(named: "reply")
        replyBarButtonItem = UIBarButtonItem(image: replyImage, style: .plain, target: self, action: #selector(tappedReplyNavigationItem(_:)))
        replyBarButtonItem?.tintColor = theme.colors.link
        navigationItem.rightBarButtonItem = replyBarButtonItem
        replyBarButtonItem?.isEnabled = !repliesAreDisabled
        navigationBar.updateNavigationItems()
        
        if let headerView = TalkPageHeaderView.wmf_viewFromClassNib(),
            let title = topic.title {
            configure(headerView: headerView)
            navigationBar.isBarHidingEnabled = false
            navigationBar.isUnderBarViewHidingEnabled = true
            useNavigationBarVisibleHeightForScrollViewInsets = false
            navigationBar.addUnderNavigationBarView(headerView)
            navigationBar.underBarViewPercentHiddenForShowingTitle = 0.6

            let titleWithoutHTML = title.removingHTML
            navigationBar.title = titleWithoutHTML
            if #available(iOS 14.0, *), !titleWithoutHTML.isEmpty {
                navigationItem.backButtonDisplayMode = .generic
                navigationItem.backButtonTitle = titleWithoutHTML
            }
            updateScrollViewInsets()
        }
    }
    
    @objc func tappedPublish(_ sender: UIBarButtonItem) {
        
        guard let composeText = composeText,
            composeText.count > 0 else {
                assertionFailure("User should be able to tap Publish if they have not written a reply.")
                return
        }
        view.endEditing(true)
        delegate?.tappedPublish(topic: topic, composeText: composeText, viewController: self)
    }
    
    @objc func tappedReplyNavigationItem(_ sender: UIBarButtonItem) {
        
        showingCompose = true
    }
    
    func setupBackgroundTap() {
        backgroundTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tappedBackground(_:)))
        view.addGestureRecognizer(backgroundTapGestureRecognizer)
    }
    
    @objc func tappedBackground(_ tapGestureRecognizer: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    func configure(headerView: TalkPageHeaderView) {
        
        guard let title = topic.title else {
                return
        }
        
        let headerText = WMFLocalizedString("talk-page-topic-title", value: "Discussion", comment: "This header label is displayed at the top of a talk page topic thread.").localizedUppercase
        
        let viewModel = TalkPageHeaderView.ViewModel(header: headerText, title: title, info: nil, intro: nil)
        
        headerView.delegate = self
        headerView.configure(viewModel: viewModel)
        headerView.layoutMargins = layout.itemLayoutMargins
        headerView.semanticContentAttributeOverride = talkPageSemanticContentAttribute
        headerView.apply(theme: theme)
        self.headerView = headerView
    }
    
    func configure(footer: TalkPageReplyFooterView) {
        footer.delegate = self
        footer.showingCompose = showingCompose
        footer.layoutMargins = layout.itemLayoutMargins
        footer.apply(theme: theme)
        footer.composeButtonIsDisabled = repliesAreDisabled
    }
    
    func configure(cell: TalkPageReplyCell, at indexPath: IndexPath) {
        let item = fetchedResultsController.object(at: indexPath)
        guard let title = item.text,
        item.depth >= 0 else {
            assertionFailure("Invalid depth")
            return
        }
        
        cell.delegate = self
        cell.configure(title: title, depth: UInt(item.depth))
        cell.layoutMargins = layout.itemLayoutMargins
        cell.semanticContentAttributeOverride = talkPageSemanticContentAttribute
        cell.apply(theme: theme)
    }
    
    func scrollToBottom() {
        let bottomOffset = CGPoint(x: 0, y: (collectionView.contentSize.height - collectionView.frame.size.height) + collectionView.adjustedContentInset.bottom)
        scrollView?.setContentOffset(bottomOffset, animated: true)
    }
}

//MARK: TalkPageReplyCellDelegate

extension TalkPageReplyListViewController: TalkPageReplyCellDelegate {
    func tappedLink(_ url: URL, cell: TalkPageReplyCell, sourceView: UIView, sourceRect: CGRect?) {
        
        delegate?.tappedLink(url, viewController: self, sourceView: sourceView, sourceRect: sourceRect)
    }
}

//MARK: ReplyButtonFooterViewDelegate

extension TalkPageReplyListViewController: ReplyButtonFooterViewDelegate {
    func composeTextDidChange(text: String?) {
        publishButton.isEnabled = text?.count ?? 0 > 0
        composeText = text
    }
    
    func tappedReply(from view: TalkPageReplyFooterView) {

        showingCompose = !showingCompose
        originalFooterViewFrame = footerView?.frame
    }
    
    var collectionViewFrame: CGRect {
        return collectionView.frame
    }
}

//MARK: TalkPageHeaderViewDelegate

extension TalkPageReplyListViewController: TalkPageHeaderViewDelegate {
    func tappedLink(_ url: URL, headerView: TalkPageHeaderView, sourceView: UIView, sourceRect: CGRect?) {
        delegate?.tappedLink(url, viewController: self, sourceView: sourceView, sourceRect: sourceRect)
    }
    
    func tappedIntro(headerView: TalkPageHeaderView) {
        assertionFailure("Should not be able to tap intro text view from replies screen")
    }
}

//MARK: FakeProgressLoading

extension TalkPageReplyListViewController: FakeProgressLoading {
}
