import UIKit
import WMF
import CocoaLumberjackSwift

class TalkPageViewController: ViewController {

    // MARK: - Properties

    fileprivate let viewModel: TalkPageViewModel
    fileprivate var headerView: TalkPageHeaderView?
    
    fileprivate lazy var shareButton: IconBarButtonItem = IconBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(userDidTapShareButton))
    
    fileprivate lazy var findButton: IconBarButtonItem = IconBarButtonItem(image: UIImage(systemName: "doc.text.magnifyingglass"), style: .plain, target: self, action: #selector(userDidTapFindButton))
    
    fileprivate lazy var revisionButton: IconBarButtonItem = IconBarButtonItem(image: UIImage(systemName: "clock.arrow.circlepath"), style: .plain, target: self, action: #selector(userDidTapRevisionButton))
    
    fileprivate lazy var addTopicButton: IconBarButtonItem = IconBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(userDidTapAddTopicButton))
    
    var talkPageView: TalkPageView {
        return view as! TalkPageView
    }
    
    lazy private(set) var fakeProgressController: FakeProgressController = {
        let progressController = FakeProgressController(progress: navigationBar, delegate: navigationBar)
        progressController.delay = 0.0
        return progressController
    }()
    
    // MARK: - Overflow menu properties
    
    fileprivate var userTalkOverflowSubmenuActions: [UIAction] {
        let contributionsAction = UIAction(title: TalkPageLocalizedStrings.contributions, image: UIImage(named: "user-contributions"), handler: { _ in
        })

        let userGroupsAction = UIAction(title: TalkPageLocalizedStrings.userGroups, image: UIImage(systemName: "person.2"), handler: { _ in
        })

        let logsAction = UIAction(title: TalkPageLocalizedStrings.logs, image: UIImage(systemName: "list.bullet"), handler: { _ in
        })

        return [contributionsAction, userGroupsAction, logsAction]
    }

    fileprivate var overflowSubmenuActions: [UIAction] {

        let goToArchivesAction = UIAction(title: TalkPageLocalizedStrings.archives, image: UIImage(systemName: "archivebox"), handler: { _ in
        })

        let pageInfoAction = UIAction(title: TalkPageLocalizedStrings.pageInfo, image: UIImage(systemName: "info.circle"), handler: { _ in
        })

        let goToPermalinkAction = UIAction(title: TalkPageLocalizedStrings.permaLink, image: UIImage(systemName: "link"), handler: { _ in
        })

        let relatedLinksAction = UIAction(title: TalkPageLocalizedStrings.relatedLinks, image: UIImage(systemName: "arrowshape.turn.up.forward"), handler: { _ in
        })

        var actions = [goToArchivesAction, pageInfoAction, goToPermalinkAction, relatedLinksAction]

        if viewModel.pageType == .user {
            let aboutTalkUserPagesAction = UIAction(title: TalkPageLocalizedStrings.aboutUserTalk, image: UIImage(systemName: "doc.plaintext"), handler: { _ in

            })
            actions.insert(contentsOf: userTalkOverflowSubmenuActions, at: 1)
            actions.append(aboutTalkUserPagesAction)
        } else {
            let changeLanguageAction = UIAction(title: TalkPageLocalizedStrings.changeLanguage, image: UIImage(named: "language-talk-page"), handler: { _ in
            })
            let aboutTalkPagesAction = UIAction(title: TalkPageLocalizedStrings.aboutArticleTalk, image: UIImage(systemName: "doc.plaintext"), handler: { _ in

            })
            actions.insert(changeLanguageAction, at: 3)
            actions.append(aboutTalkPagesAction)
        }
        return actions
    }

    var overflowMenu: UIMenu {
        
        let openAllAction = UIAction(title: TalkPageLocalizedStrings.openAllThreads, image: UIImage(systemName: "square.stack"), handler: { _ in
            
            for topic in self.viewModel.topics {
                topic.isThreadExpanded = true
            }

            self.talkPageView.collectionView.reloadData()
        })
        
        let revisionHistoryAction = UIAction(title: CommonStrings.revisionHistory, image: UIImage(systemName: "clock.arrow.circlepath"), handler: { _ in
            
        })
        
        let openInWebAction = UIAction(title: TalkPageLocalizedStrings.readInWeb, image: UIImage(systemName: "display"), handler: { _ in
            
        })
        
        let submenu = UIMenu(title: String(), options: .displayInline, children: overflowSubmenuActions)
        let mainMenu = UIMenu(title: String(), children: [openAllAction, revisionHistoryAction, openInWebAction, submenu])

        return mainMenu
    }

    // MARK: - Lifecycle

    init(theme: Theme, viewModel: TalkPageViewModel) {
        self.viewModel = viewModel
        super.init(theme: theme)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let talkPageView = TalkPageView(frame: UIScreen.main.bounds)
        view = talkPageView
        scrollView = talkPageView.collectionView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = TalkPageLocalizedStrings.title

        // Not adding fallback for other versions since we're dropping iOS 13 on the next release
        // TODO: this version check should be removed
        if #available(iOS 14.0, *) {
            let rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), primaryAction: nil, menu: overflowMenu)
            navigationItem.rightBarButtonItem = rightBarButtonItem
            rightBarButtonItem.tintColor = theme.colors.link
        }
 
        talkPageView.collectionView.dataSource = self
        talkPageView.collectionView.delegate = self

        // Needed for reply compose views to display on top of navigation bar.
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationMode = .forceBar

        fakeProgressController.start()
        viewModel.fetchTalkPage { [weak self] result in
            
            guard let self = self else {
                return
            }
            
            self.fakeProgressController.stop()
            switch result {
            case .success:
                self.setupHeaderView()
                self.talkPageView.collectionView.reloadData()
            case .failure:
                break
            }
        }
        
        setupToolbar()
    }

    private func setupHeaderView() {
        
        guard self.headerView == nil else {
            return
        }
        
        let headerView = TalkPageHeaderView()
        self.headerView = headerView
        
        headerView.configure(viewModel: viewModel)
        navigationBar.isBarHidingEnabled = false
        navigationBar.isUnderBarViewHidingEnabled = true
        navigationBar.allowsUnderbarHitsFallThrough = true
        
        navigationBar.addUnderNavigationBarView(headerView, shouldIgnoreSafeArea: true)
        useNavigationBarVisibleHeightForScrollViewInsets = false
        updateScrollViewInsets()
        
        headerView.apply(theme: theme)
    }

    // MARK: - Public

    // MARK: - Themeable

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        
        viewModel.theme = theme
        headerView?.apply(theme: theme)
        talkPageView.apply(theme: theme)
        talkPageView.collectionView.reloadData()
        replyComposeController.apply(theme: theme)
    }
    
    // MARK: Reply Compose Management
    
    let replyComposeController = TalkPageReplyComposeController()
    
    override var additionalBottomContentInset: CGFloat {
        return replyComposeController.additionalBottomContentInset
    }
    
    override func keyboardDidChangeFrame(from oldKeyboardFrame: CGRect?, newKeyboardFrame: CGRect?) {
        super.keyboardDidChangeFrame(from: oldKeyboardFrame, newKeyboardFrame: newKeyboardFrame)
        
        guard oldKeyboardFrame != newKeyboardFrame else {
            return
        }
        
        replyComposeController.calculateLayout(in: self, newKeyboardFrame: newKeyboardFrame)
        
        view.setNeedsLayout()
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        headerView?.updateLabelFonts()
        replyComposeController.calculateLayout(in: self)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        replyComposeController.calculateLayout(in: self, newViewSize: size)
    }
    
    // MARK: Toolbar actions
    
    var talkPageURL: URL? {
        var talkPageURLComponents = URLComponents(url: viewModel.siteURL, resolvingAgainstBaseURL: false)
        talkPageURLComponents?.path = "/wiki/\(viewModel.pageTitle)"
        return talkPageURLComponents?.url
    }
    
    @objc fileprivate func userDidTapShareButton() {
        guard let talkPageURL = talkPageURL else {
            return
        }
        
        let activityController = UIActivityViewController(activityItems: [talkPageURL], applicationActivities: [TUSafariActivity()])
        present(activityController, animated: true)
    }
    
    @objc fileprivate func userDidTapFindButton() {
        
    }
    
    @objc fileprivate func userDidTapRevisionButton() {
        
    }
    
    @objc fileprivate func userDidTapAddTopicButton() {
        let topicComposeVC = TalkPageTopicComposeViewController(theme: theme)
        topicComposeVC.delegate = self
        let navVC = UINavigationController(rootViewController: topicComposeVC)
        navVC.modalPresentationStyle = .pageSheet
        navVC.presentationController?.delegate = self
        present(navVC, animated: true, completion: nil)
    }
    
    fileprivate func setupToolbar() {
        enableToolbar()
        setToolbarHidden(false, animated: false)
        
        toolbar.items = [shareButton,  .flexibleSpaceToolbar(), revisionButton, .flexibleSpaceToolbar(), findButton,.flexibleSpaceToolbar(), addTopicButton]
        
        shareButton.accessibilityLabel = TalkPageLocalizedStrings.shareButtonAccesibilityLabel
        findButton.accessibilityLabel = TalkPageLocalizedStrings.findButtonAccesibilityLabel
        revisionButton.accessibilityLabel = CommonStrings.revisionHistory
        addTopicButton.accessibilityLabel = TalkPageLocalizedStrings.addTopicButtonAccesibilityLabel
    }

    private func scrollToLastTopic() {
        if viewModel.topics.count > 0 {
            let indexPath = IndexPath.init(item: viewModel.topics.count - 1, section: 0)
            talkPageView.collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
        }
    }
    
    fileprivate func handleSubscriptionAlert(isSubscribedToTopic: Bool) {
        let title = isSubscribedToTopic ? TalkPageLocalizedStrings.subscribedAlertTitle : TalkPageLocalizedStrings.unsubscribedAlertTitle
        let subtitle = isSubscribedToTopic ? TalkPageLocalizedStrings.subscribedAlertSubtitle : TalkPageLocalizedStrings.unsubscribedAlertSubtitle
        let image = isSubscribedToTopic ? UIImage(systemName: "bell.fill") : UIImage(systemName: "bell.slash.fill")
        
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: title)
        } else {
            WMFAlertManager.sharedInstance.showBottomAlertWithMessage(title, subtitle: subtitle, image: image, dismissPreviousAlerts: true)
        }
    }
    
    private func handleNewTopicOrCommentAlert(isNewTopic: Bool) {
        let title = isNewTopic ? TalkPageLocalizedStrings.addedTopicAlertTitle : TalkPageLocalizedStrings.addedCommentAlertTitle
        let image = UIImage(systemName: "checkmark.circle.fill")
        
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: title)
        } else {
            WMFAlertManager.sharedInstance.showBottomAlertWithMessage(title, subtitle: nil, image: image, dismissPreviousAlerts: true)
        }
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource

extension TalkPageViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.topics.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TalkPageCell.reuseIdentifier, for: indexPath) as? TalkPageCell else {
            return UICollectionViewCell()
        }

        let viewModel = viewModel.topics[indexPath.row]

        cell.delegate = self
        cell.replyDelegate = self
        cell.configure(viewModel: viewModel, linkDelegate: self)
        cell.apply(theme: theme)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? TalkPageCell else {
            return
        }
        
        userDidTapDisclosureButton(cellViewModel: cell.viewModel, cell: cell)
    }
}

// MARK: - TalkPageCellDelegate

extension TalkPageViewController: TalkPageCellDelegate {
    
    func userDidTapDisclosureButton(cellViewModel: TalkPageCellViewModel?, cell: TalkPageCell) {
        guard let cellViewModel = cellViewModel, let indexOfConfiguredCell = viewModel.topics.firstIndex(where: {$0 === cellViewModel}) else {
            return
        }
        
        let configuredCellViewModel = viewModel.topics[indexOfConfiguredCell]
        configuredCellViewModel.isThreadExpanded.toggle()
        
        cell.removeExpandedElements()
        cell.configure(viewModel: configuredCellViewModel, linkDelegate: self)
        cell.apply(theme: theme)
        talkPageView.collectionView.collectionViewLayout.invalidateLayout()
    }
    
    func userDidTapSubscribeButton(cellViewModel: TalkPageCellViewModel?, cell: TalkPageCell) {
        guard let cellViewModel = cellViewModel, let indexOfConfiguredCell = viewModel.topics.firstIndex(where: {$0 === cellViewModel}) else {
            return
        }
        
        let configuredCellViewModel = viewModel.topics[indexOfConfiguredCell]
        
        let shouldSubscribe = !configuredCellViewModel.isSubscribed
        cellViewModel.isSubscribed.toggle()
        cell.configure(viewModel: configuredCellViewModel, linkDelegate: self)
        
        viewModel.subscribe(to: configuredCellViewModel.topicName, shouldSubscribe: shouldSubscribe) { result in
            switch result {
            case let .success(didSubscribe):
                self.handleSubscriptionAlert(isSubscribedToTopic: didSubscribe)
            case let .failure(error):
                cellViewModel.isSubscribed.toggle()
                if cell.viewModel?.topicName == cellViewModel.topicName {
                    cell.configure(viewModel: cellViewModel, linkDelegate: self)
                }
                DDLogError("Error subscribing to topic: \(error)")
                // TODO: Error handling
            }
        }
 
    }
}

extension TalkPageViewController: TalkPageCellReplyDelegate {
    func tappedReply(commentViewModel: TalkPageCellCommentViewModel) {
        replyComposeController.setupAndDisplay(in: self, commentViewModel: commentViewModel)
    }
}

extension TalkPageViewController: TalkPageReplyComposeDelegate {
    func tappedClose() {
        replyComposeController.reset()
    }
    
    func tappedPublish(text: String, commentViewModel: TalkPageCellCommentViewModel) {
        viewModel.postReply(commentId: commentViewModel.commentId, comment: text) { [weak self] result in

            switch result {
            case .success:
                self?.replyComposeController.reset()
                
                // Try to refresh page
                self?.viewModel.fetchTalkPage { [weak self] result in
                    switch result {
                    case .success:
                        self?.talkPageView.collectionView.reloadData()
                        self?.handleNewTopicOrCommentAlert(isNewTopic: false)
                    case .failure:
                        break
                    }
                }
            case .failure(let error):
                DDLogError("Failure publishing reply: \(error)")
                self?.replyComposeController.isLoading = false
                // TODO: Display failure banner
            }
        }
    }
}

extension TalkPageViewController: TalkPageTopicComposeViewControllerDelegate {
    func tappedPublish(topicTitle: String, topicBody: String, composeViewController: TalkPageTopicComposeViewController) {

        viewModel.postTopic(topicTitle: topicTitle, topicBody: topicBody) { [weak self] result in

            switch result {
            case .success:
                
                composeViewController.dismiss(animated: true) {
                    // TODO: Display success banner
                }
                
                // Try to refresh page
                self?.viewModel.fetchTalkPage { [weak self] result in
                    switch result {
                    case .success:
                        self?.talkPageView.collectionView.reloadData()
                        self?.scrollToLastTopic()
                        self?.handleNewTopicOrCommentAlert(isNewTopic: true)
                    case .failure:
                        break
                    }
                }
            case .failure(let error):
                DDLogError("Failure publishing topic: \(error)")
                composeViewController.setupNavigationBar(isPublishing: false)
                // TODO: Display failure banner on topic compose VC
            }
        }
    }
    
    
}

extension TalkPageViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        guard let navVC = presentationController.presentingViewController as? UINavigationController,
              let topicComposeVC = navVC.visibleViewController as? TalkPageTopicComposeViewController else {
            return true
        }
        
        guard topicComposeVC.shouldBlockDismissal else {
            return true
        }
        
        topicComposeVC.presentDismissConfirmationActionSheet()
        return false
    }
}

extension TalkPageViewController {
    enum TalkPageLocalizedStrings {
        static let title = WMFLocalizedString("talk-pages-view-title", value: "Talk", comment: "Title of user and article talk pages view.")
        static let openAllThreads = WMFLocalizedString("talk-page-menu-open-all", value: "Open all threads", comment: "Title for menu option open all talk page threads")
        static let readInWeb = WMFLocalizedString("talk-page-read-in-web", value: "Read in web", comment: "Title for menu option to read a talk page in a web browser")
        static let archives = WMFLocalizedString("talk-page-archives", value: "Archives", comment: "Title for menu option that redirects to talk page archives")
        static let pageInfo = WMFLocalizedString("talk-page-page-info", value: "Page information", comment: "Title for menu option to go to the talk page information link")
        static let permaLink = WMFLocalizedString("talk-page-permanent-link", value: "Permanent link", comment: "Title for menu option to open the talk page's permanent link in a web browser")
        static let changeLanguage = WMFLocalizedString("talk-page-change-language", value: "Change language", comment: "Title for menu option to got to the change language page")
        static let relatedLinks = WMFLocalizedString("talk-page-related-links", value: "What links here", comment: "Title for menu option that redirects to a page that shows related links")
        static let aboutArticleTalk = WMFLocalizedString("talk-page-article-about", value: "About talk pages", comment: "Title for menu option for information on article talk pages")
        static let aboutUserTalk = WMFLocalizedString("talk-page-user-about", value: "About user talk pages", comment: "Title for menu option for information on user talk pages")
        static let contributions = WMFLocalizedString("talk-page-user-contributions", value: "Contributions", comment: "Title for menu option for information on the user's contributions")
        static let userGroups = WMFLocalizedString("talk-pages-user-groups", value: "User groups", comment: "Title for menu option for information on the user's user groups")
        static let logs = WMFLocalizedString("talk-pages-user-logs", value: "Logs", comment: "Title for menu option to consult the user's public logs")
        
        static let subscribedAlertTitle = WMFLocalizedString("talk-page-subscribed-alert-title", value: "You have subscribed!", comment: "Title for alert informing that the user subscribed to a topic")
        static let unsubscribedAlertTitle = WMFLocalizedString("talk-page-unsubscribed-alert-title", value: "You have unsubscribed.", comment: "Title for alert informing that the user unsubscribed to a topic")
        static let subscribedAlertSubtitle = WMFLocalizedString("talk-page-subscribed-alert-subtitle", value: "You will receive notifications about new comments in this topic.", comment: "Subtitle for alert informing that the user will receive notifications for a subscribed topic")
        static let unsubscribedAlertSubtitle = WMFLocalizedString("talk-page-unsubscribed-alert-subtitle", value: "You will no longer receive notifications about new comments in this topic.", comment: "Subtitle for alert informing that the user will no longer receive notifications for a topic")
        
        static let addedTopicAlertTitle = WMFLocalizedString("talk-pages-topic-added-alert-title", value: "Your topic was added", comment: "Title for alert informing that the user's new topic was successfully published.")
        static let addedCommentAlertTitle = WMFLocalizedString("talk-pages-comment-added-alert-title", value: "Your comment was added", comment: "Title for alert informing that the user's new comment was successfully published.")
        
        static let shareButtonAccesibilityLabel = WMFLocalizedString("talk-page-share-button", value: "Share talk page", comment: "Title for share talk page button")
        static let findButtonAccesibilityLabel = WMFLocalizedString("talk-page-find-in-page-button", value: "Find in page", comment: "Title for find content in page button")
        static let addTopicButtonAccesibilityLabel = WMFLocalizedString("talk-page-add-topic-button", value: "Add topic", comment: "Title for add topic to talk page button")
    }
}

protocol TalkPageTextViewLinkHandling: AnyObject {
    func tappedLink(_ url: URL, sourceTextView: UITextView)
}

extension TalkPageViewController: TalkPageTextViewLinkHandling {
    func tappedLink(_ url: URL, sourceTextView: UITextView) {
        guard let url = URL(string: url.absoluteString, relativeTo: talkPageURL) else {
            return
        }
        navigate(to: url.absoluteURL)
    }
}
