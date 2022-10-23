import UIKit
import WMF
import CocoaLumberjackSwift

class TalkPageViewController: ViewController {

    // MARK: - Properties

    fileprivate let viewModel: TalkPageViewModel
    fileprivate var headerView: TalkPageHeaderView?

    fileprivate var topicReplyOnboardingHostingViewController: TalkPageTopicReplyOnboardingHostingController?
    
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
        let contributionsAction = UIAction(title: TalkPageLocalizedStrings.contributions, image: UIImage(named: "user-contributions"), handler: { [weak self] _ in
            self?.pushToContributions()
        })

        let userGroupsAction = UIAction(title: TalkPageLocalizedStrings.userGroups, image: UIImage(systemName: "person.2"), handler: { [weak self] _ in
            self?.pushToUserGroups()
        })

        let logsAction = UIAction(title: TalkPageLocalizedStrings.logs, image: UIImage(systemName: "list.bullet"), handler: { [weak self] _ in
            self?.pushToLogs()
        })

        return [contributionsAction, userGroupsAction, logsAction]
    }

    fileprivate var overflowSubmenuActions: [UIAction] {

        let goToArchivesAction = UIAction(title: TalkPageLocalizedStrings.archives, image: UIImage(systemName: "archivebox"), handler: { _ in
        })

        let pageInfoAction = UIAction(title: TalkPageLocalizedStrings.pageInfo, image: UIImage(systemName: "info.circle"), handler: { [weak self] _ in
            self?.pushToPageInfo()
        })

        let goToPermalinkAction = UIAction(title: TalkPageLocalizedStrings.permaLink, image: UIImage(systemName: "link"), handler: { [weak self] _ in
            self?.pushToPermanentLink()
        })

        let changeLanguageAction = UIAction(title: TalkPageLocalizedStrings.changeLanguage, image: UIImage(named: "language-talk-page"), handler: { _ in
            self.userDidTapChangeLanguage()
        })

        let relatedLinksAction = UIAction(title: TalkPageLocalizedStrings.relatedLinks, image: UIImage(systemName: "arrowshape.turn.up.forward"), handler: { [weak self] _ in
            self?.pushToWhatLinksHere()
        })

        var actions = [goToArchivesAction, pageInfoAction, goToPermalinkAction, changeLanguageAction, relatedLinksAction]

        if viewModel.pageType == .user {
            actions.insert(contentsOf: userTalkOverflowSubmenuActions, at: 1)

        }
        let aboutTalkPagesAction = UIAction(title: TalkPageLocalizedStrings.aboutTalkPages, image: UIImage(systemName: "doc.plaintext"), handler: { _ in

        })
        actions.append(aboutTalkPagesAction)

        return actions
    }

    var overflowMenu: UIMenu {
        
        let openAllAction = UIAction(title: TalkPageLocalizedStrings.openAllThreads, image: UIImage(systemName: "square.stack"), handler: { _ in
            
            for topic in self.viewModel.topics {
                topic.isThreadExpanded = true
            }

            self.talkPageView.collectionView.reloadData()
        })
        
        let revisionHistoryAction = UIAction(title: CommonStrings.revisionHistory, image: UIImage(systemName: "clock.arrow.circlepath"), handler: { [weak self] _ in
            self?.pushToRevisionHistory()
        })
        
        let openInWebAction = UIAction(title: TalkPageLocalizedStrings.readInWeb, image: UIImage(systemName: "display"), handler: { [weak self] _ in
            self?.pushToDesktopWeb()
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

    fileprivate func fetchTalkPage() {
        navigationBar.removeUnderNavigationBarView()
        self.headerView = nil
        fakeProgressController.start()
        viewModel.fetchTalkPage { [weak self] result in

            guard let self = self else {
                return
            }

            self.fakeProgressController.stop()
            switch result {
            case .success:
                self.setupHeaderView()
                self.talkPageView.configure(viewModel: self.viewModel)
                self.talkPageView.emptyView.actionButton.addTarget(self, action: #selector(self.userDidTapAddTopicButton), for: .primaryActionTriggered)
                self.updateEmptyStateVisibility()
                guard self.needsDeepLinkScroll() else {
                    self.talkPageView.collectionView.reloadData()
                    break
                }
                
                self.reloadDataAndScrollToDeepLink()
                
            case .failure:
                self.talkPageView.errorView.button.addTarget(self, action: #selector(self.tryAgain), for: .primaryActionTriggered)
            }
            self.updateErrorStateVisibility()

        }
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

        talkPageView.emptyView.scrollView.delegate = self

        // Needed for reply compose views to display on top of navigation bar.
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationMode = .forceBar

        fetchTalkPage()
        setupToolbar()
    }

    @objc func tryAgain() {
        fetchTalkPage()
    }

    private func setupHeaderView() {
        
        if self.headerView != nil {
            navigationBar.removeUnderNavigationBarView()
            self.headerView = nil
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

        headerView.coffeeRollReadMoreButton.addTarget(self, action: #selector(userDidTapCoffeeRollReadMoreButton), for: .primaryActionTriggered)
    }

    // MARK: - Coffee Roll

    @objc private func userDidTapCoffeeRollReadMoreButton() {
        let coffeeRollViewModel = TalkPageCoffeeRollViewModel(coffeeRollText: viewModel.coffeeRollText, talkPageURL: talkPageURL)
        let coffeeViewController = TalkPageCoffeeRollViewController(theme: theme, viewModel: coffeeRollViewModel)
        push(coffeeViewController, animated: true)
    }

    @objc private func userDidTapChangeLanguage() {
        if viewModel.pageType == .user {
            let languageVC = WMFPreferredLanguagesViewController.preferredLanguagesViewController()
            languageVC.delegate = self
            if let themeableVC = languageVC as Themeable? {
                themeableVC.apply(theme: self.theme)
            }
            present(WMFThemeableNavigationController(rootViewController: languageVC, theme: self.theme), animated: true, completion: nil)
        } else if viewModel.pageType == .article {
            guard let languageCode  = viewModel.siteURL.wmf_languageCode else {
                return
            }
            if let articleTitle = viewModel.pageTitle.extractingArticleTitleFromTalkPage(languageCode: languageCode)?.denormalizedPageTitle {
                if let articleURL = viewModel.siteURL.wmf_URL(withTitle: articleTitle) {
                    let languageVC = WMFArticleLanguagesViewController(articleURL: articleURL)
                    languageVC.delegate = self
                    present(WMFThemeableNavigationController(rootViewController: languageVC, theme: self.theme), animated: true, completion: nil)
                }
            }
        }
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
    
    // MARK: - Reply Compose Management
    
    let replyComposeController = TalkPageReplyComposeController()
    
    private var isClosing: Bool = false
    
    override var keyboardIsIncludedInBottomContentInset: Bool {
        return false
    }
    
    override var additionalBottomContentInset: CGFloat {

        if let replyComposeView = replyComposeController.containerView {
            return max(0, toolbar.frame.minY - replyComposeView.frame.minY)
        }

        return 0
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
        talkPageView.collectionView.reloadData()
        headerView?.updateLabelFonts()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        replyComposeController.calculateLayout(in: self, newViewSize: size)
    }
    
    // MARK: - Toolbar actions
    
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
        pushToRevisionHistory()
    }

    @objc fileprivate func userDidTapAddTopicButton() {
        let topicComposeVC = TalkPageTopicComposeViewController(theme: theme)
        topicComposeVC.delegate = self
        let navVC = UINavigationController(rootViewController: topicComposeVC)
        navVC.modalPresentationStyle = .pageSheet
        navVC.presentationController?.delegate = self
        present(navVC, animated: true, completion: { [weak self] in
            self?.presentTopicReplyOnboardingIfNecessary()
        })
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
    
    fileprivate func pushToRevisionHistory() {
        let historyVC = PageHistoryViewController(pageTitle: viewModel.pageTitle, pageURL: viewModel.siteURL)
        navigationController?.pushViewController(historyVC, animated: true)
    }
    
    // MARK: - Overflow menu navigation
    
    fileprivate func pushToDesktopWeb() {
        guard let url = viewModel.siteURL.wmf_URL(withPath: "/wiki/\(viewModel.pageTitle)", isMobile: false) else {
            // TODO: Error banner
            return
        }
        
        navigate(to: url, useSafari: true)
    }
    
    fileprivate func pushToPageInfo() {
        
        guard let host = viewModel.siteURL.host,
              let url = Configuration.current.expandedArticleURLForHost(host, languageVariantCode: viewModel.siteURL.wmf_languageVariantCode, queryParameters: ["title": viewModel.pageTitle,
                                                                                                                                                                "action": "info"]) else {
            // TODO: Error banner
            return
        }
        
        navigate(to: url)
    }
    
    fileprivate func pushToWhatLinksHere() {
        guard let url = viewModel.siteURL.wmf_URL(withPath: "/wiki/Special:WhatLinksHere/\(viewModel.pageTitle)", isMobile: true) else {
            // TODO: Error banner
            return
        }
        
        navigate(to: url)
    }
    
    fileprivate func pushToContributions() {
        guard let username = usernameFromPageTitle(),
              let url = viewModel.siteURL.wmf_URL(withPath: "/wiki/Special:Contributions/\(username)", isMobile: true) else {
            // TODO: Error banner
            return
        }
        
        navigate(to: url)
    }
    
    fileprivate func pushToUserGroups() {
        guard let username = usernameFromPageTitle(),
              let url = viewModel.siteURL.wmf_URL(withPath: "/wiki/Special:UserRights/\(username)", isMobile: true) else {
            // TODO: Error banner
            return
        }
        
        navigate(to: url)
    }
    
    fileprivate func pushToLogs() {
        guard let username = usernameFromPageTitle(),
              let url = viewModel.siteURL.wmf_URL(withPath: "/wiki/Special:Log/\(username)", isMobile: true) else {
            // TODO: Error banner
            return
        }
        
        navigate(to: url)
    }
    
    fileprivate func usernameFromPageTitle() -> String? {
        guard let languageCode = viewModel.siteURL.wmf_languageCode else {
            return nil
        }
        
        let namespaceAndTitle = viewModel.pageTitle.namespaceAndTitleOfWikiResourcePath(with: languageCode)
        
        guard namespaceAndTitle.0 == .userTalk else {
            return nil
        }
        
        return namespaceAndTitle.1
    }
    
    fileprivate func pushToPermanentLink() {
        
        guard let latestRevisionID = viewModel.latestRevisionID,
              let mobileSiteURL = viewModel.siteURL.wmf_URL(withPath: "", isMobile: true),
              let host = mobileSiteURL.host,
              let url = Configuration.current.expandedArticleURLForHost(host, languageVariantCode: viewModel.siteURL.wmf_languageVariantCode, queryParameters: ["title": viewModel.pageTitle,
                                                                                                                                                                "oldid": latestRevisionID]) else {
            // TODO: Error banner
            return
        }
        
        navigate(to: url, useSafari: true)
    }
    
    // MARK: - Alerts
    
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
    
    // MARK: - Scrolling Helpers
    
    private func scrollToLastTopic() {
        if viewModel.topics.count > 0 {
            let indexPath = IndexPath(item: viewModel.topics.count - 1, section: 0)
            talkPageView.collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
        }
    }
    
    private func needsDeepLinkScroll() -> Bool {
            return deepLinkDestination() != nil
        }
        
    private func reloadDataAndScrollToDeepLink() {
        
        guard let destination = deepLinkDestination() else {
            return
        }
        
        let cellViewModel = destination.0
        let indexPath = destination.1
        let commentViewModel = destination.2
        
        cellViewModel.isThreadExpanded = true
        talkPageView.collectionView.reloadData()
        
        isProgramaticallyScrolling = true
        talkPageView.collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
        isProgramaticallyScrolling = false
        
        if let commentViewModel = commentViewModel {
            scrollToComment(commentViewModel: commentViewModel, animated: false)
        }
    }
    
    private func deepLinkDestination() -> (TalkPageCellViewModel, IndexPath, TalkPageCellCommentViewModel?)? {
        
        guard let deepLinkData = viewModel.deepLinkData,
              let topicTitle = deepLinkData.topicTitle.unescapedNormalizedPageTitle else {
            return nil
        }
        
        var targetIndexPath: IndexPath?
        var targetCellViewModel: TalkPageCellViewModel?
        var targetCommentViewModel: TalkPageCellCommentViewModel?
        
        for (index, cellViewModel) in viewModel.topics.enumerated() {
            if cellViewModel.topicTitle.removingHTML == topicTitle {
                targetIndexPath = IndexPath(item: index, section: 0)
                targetCellViewModel = cellViewModel
                break
            }
        }
        
        guard let targetCellViewModel = targetCellViewModel,
            let targetIndexPath = targetIndexPath else {
            return nil
        }
        
        if let replyText = deepLinkData.replyText {
            
            for commentViewModel in targetCellViewModel.allCommentViewModels {
                if commentViewModel.text.removingHTML.contains(replyText.removingHTML) {
                    targetCommentViewModel = commentViewModel
                }
            }
        }
        
        return (targetCellViewModel, targetIndexPath, targetCommentViewModel)
    }
    
    private func scrollToNewComment(oldCellViewModel: TalkPageCellViewModel?, oldCommentViewModels: [TalkPageCellCommentViewModel]?) {
        
        guard let oldCellViewModel = oldCellViewModel,
              let oldCommentViewModels = oldCommentViewModels else {
            return
        }
        
        let newCellViewModel = viewModel.topics.first { $0 == oldCellViewModel }
        
        guard let newCommentViewModels = newCellViewModel?.allCommentViewModels else {
            return
        }
        
        if let newCommentViewModel = newestComment(from: oldCommentViewModels, to: newCommentViewModels) {
            scrollToComment(commentViewModel: newCommentViewModel)
        }
    }
    
    private func newestComment(from oldCommentViewModels: [TalkPageCellCommentViewModel], to newCommentViewModels: [TalkPageCellCommentViewModel]) -> TalkPageCellCommentViewModel? {
        
        let oldCommentViewModelsSet = Set(oldCommentViewModels)
        let newCommentViewModelsSet = Set(newCommentViewModels)
        
        let newComments = newCommentViewModelsSet.subtracting(oldCommentViewModelsSet)
        
        // MAYBETODO: Sort by date here?
        
        guard let newComment = newComments.first else {
            return nil
        }
        
        return newComment
    }
    
    private func scrollToComment(commentViewModel: TalkPageCellCommentViewModel, animated: Bool = true) {
        
        guard let cellViewModel = commentViewModel.cellViewModel else {
            return
        }

        let collectionView = talkPageView.collectionView
        
        guard let index = viewModel.topics.firstIndex(of: cellViewModel)
        else {
            return
        }
        
        let topicIndexPath = IndexPath(item: index, section: 0)
        
        let scrollToIndividualComment = {
            for cell in self.talkPageView.collectionView.visibleCells {
                if let talkPageCell = cell as? TalkPageCell {
                    
                    if talkPageCell.viewModel == cellViewModel {
                         if let commentView = talkPageCell.commentViewForViewModel(commentViewModel),
                             let convertedCommentViewFrame = commentView.superview?.convert(commentView.frame, to: collectionView) {
                             let shiftedFrame = CGRect(x: convertedCommentViewFrame.minX, y: convertedCommentViewFrame.minY + 50, width: convertedCommentViewFrame.width, height: convertedCommentViewFrame.height)
                                 collectionView.scrollRectToVisible(shiftedFrame, animated: animated)
                         }
                    }
                }
            }
        }
        
        if talkPageView.collectionView.indexPathsForVisibleItems.contains(topicIndexPath) {
            scrollToIndividualComment()
        } else {
            talkPageView.collectionView.scrollToItem(at: topicIndexPath, at: .top, animated: animated)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                scrollToIndividualComment()
            })
        }
    }

    private func changeTalkPageLanguage(_ siteURL: URL, pageTitle: String) {
        viewModel.pageTitle = pageTitle
        
        viewModel.siteURL = siteURL
        viewModel.dataController = TalkPageDataController(pageType: viewModel.pageType, pageTitle: viewModel.pageTitle, siteURL: siteURL, articleSummaryController: viewModel.dataController.articleSummaryController)

        fetchTalkPage()
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
        
        cell.updateSubscribedState(viewModel: cellViewModel)

        viewModel.subscribe(to: configuredCellViewModel.topicName, shouldSubscribe: shouldSubscribe) { result in
            switch result {
            case let .success(didSubscribe):
                self.handleSubscriptionAlert(isSubscribedToTopic: didSubscribe)
            case let .failure(error):
                cellViewModel.isSubscribed.toggle()
                if cell.viewModel?.topicName == cellViewModel.topicName {
                    cell.updateSubscribedState(viewModel: cellViewModel)
                }
                DDLogError("Error subscribing to topic: \(error)")
                // TODO: Error handling
            }
        }
    }

    // MARK: - Empty State

    fileprivate func updateEmptyStateVisibility() {
        talkPageView.updateEmptyView(visible: viewModel.topics.count == 0)
        scrollView = viewModel.topics.count == 0 ? talkPageView.emptyView.scrollView : talkPageView.collectionView
        updateScrollViewInsets()
    }

    fileprivate func updateErrorStateVisibility() {
        talkPageView.updateErrorView(visible: viewModel.shouldShowErrorState)
    }

}

extension TalkPageViewController: TalkPageCellReplyDelegate {
    func tappedReply(commentViewModel: TalkPageCellCommentViewModel) {
        presentTopicReplyOnboardingIfNecessary()
        replyComposeController.setupAndDisplay(in: self, commentViewModel: commentViewModel)
    }
}

extension TalkPageViewController: TalkPageReplyComposeDelegate {
    func closeReplyView() {
        replyComposeController.closeAndReset()
    }
    
    func tappedPublish(text: String, commentViewModel: TalkPageCellCommentViewModel) {
        let oldCellViewModel = commentViewModel.cellViewModel
        let oldCommentViewModels = oldCellViewModel?.allCommentViewModels
        
        viewModel.postReply(commentId: commentViewModel.commentId, comment: text) { [weak self] result in

            switch result {
            case .success:
                self?.replyComposeController.closeAndReset()
                
                // Try to refresh page
                self?.viewModel.fetchTalkPage { [weak self] result in
                    switch result {
                    case .success:
                        self?.updateEmptyStateVisibility()
                        self?.talkPageView.collectionView.reloadData()
                        self?.handleNewTopicOrCommentAlert(isNewTopic: false)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self?.scrollToNewComment(oldCellViewModel: oldCellViewModel, oldCommentViewModels: oldCommentViewModels)
                        }

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

// MARK: Extensions

extension TalkPageViewController: TalkPageTopicComposeViewControllerDelegate {
    func tappedPublish(topicTitle: String, topicBody: String, composeViewController: TalkPageTopicComposeViewController) {

        viewModel.postTopic(topicTitle: topicTitle, topicBody: topicBody) { [weak self] result in

            switch result {
            case .success:
                
                composeViewController.dismiss(animated: true) {
                    self?.handleNewTopicOrCommentAlert(isNewTopic: true)
                }
                
                // Try to refresh page
                self?.viewModel.fetchTalkPage { [weak self] result in
                    switch result {
                    case .success:
                        self?.updateEmptyStateVisibility()
                        self?.talkPageView.collectionView.reloadData()
                        self?.scrollToLastTopic()
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
        static let title = WMFLocalizedString("talk-pages-view-title", value: "Talk", comment: "Title of user and article talk pages view. Please prioritize for de, ar and zh wikis.")
        static let openAllThreads = WMFLocalizedString("talk-page-menu-open-all", value: "Open all threads", comment: "Title for menu option open all talk page threads. Please prioritize for de, ar and zh wikis.")
        static let readInWeb = WMFLocalizedString("talk-page-read-in-web", value: "Read in web", comment: "Title for menu option to read a talk page in a web browser. Please prioritize for de, ar and zh wikis.")
        static let archives = WMFLocalizedString("talk-page-archives", value: "Archives", comment: "Title for menu option that redirects to talk page archives. Please prioritize for de, ar and zh wikis.")
        static let pageInfo = WMFLocalizedString("talk-page-page-info", value: "Page information", comment: "Title for menu option to go to the talk page information link. Please prioritize for de, ar and zh wikis.")
        static let permaLink = WMFLocalizedString("talk-page-permanent-link", value: "Permanent link", comment: "Title for menu option to open the talk page's permanent link in a web browser. Please prioritize for de, ar and zh wikis.")
        static let changeLanguage = WMFLocalizedString("talk-page-change-language", value: "Change language", comment: "Title for menu option to got to the change language page. Please prioritize for de, ar and zh wikis.")
        static let relatedLinks = WMFLocalizedString("talk-page-related-links", value: "What links here", comment: "Title for menu option that redirects to a page that shows related links. Please prioritize for de, ar and zh wikis.")
        static let aboutTalkPages = WMFLocalizedString("talk-page-article-about", value: "About talk pages", comment: "Title for menu option for information on article talk pages. Please prioritize for de, ar and zh wikis.")
        static let aboutUserTalk = WMFLocalizedString("talk-page-user-about", value: "About user talk pages", comment: "Title for menu option for information on user talk pages")
        static let contributions = WMFLocalizedString("talk-page-user-contributions", value: "Contributions", comment: "Title for menu option for information on the user's contributions. Please prioritize for de, ar and zh wikis.")
        static let userGroups = WMFLocalizedString("talk-pages-user-groups", value: "User groups", comment: "Title for menu option for information on the user's user groups. Please prioritize for de, ar and zh wikis.")
        static let logs = WMFLocalizedString("talk-pages-user-logs", value: "Logs", comment: "Title for menu option to consult the user's public logs. Please prioritize for de, ar and zh wikis.")
        
        static let subscribedAlertTitle = WMFLocalizedString("talk-page-subscribed-alert-title", value: "You have subscribed!", comment: "Title for alert informing that the user subscribed to a topic. Please prioritize for de, ar and zh wikis.")
        static let unsubscribedAlertTitle = WMFLocalizedString("talk-page-unsubscribed-alert-title", value: "You have unsubscribed.", comment: "Title for alert informing that the user unsubscribed to a topic. Please prioritize for de, ar and zh wikis.")
        static let subscribedAlertSubtitle = WMFLocalizedString("talk-page-subscribed-alert-subtitle", value: "You will receive notifications about new comments in this topic.", comment: "Subtitle for alert informing that the user will receive notifications for a subscribed topic. Please prioritize for de, ar and zh wikis.")
        static let unsubscribedAlertSubtitle = WMFLocalizedString("talk-page-unsubscribed-alert-subtitle", value: "You will no longer receive notifications about new comments in this topic.", comment: "Subtitle for alert informing that the user will no longer receive notifications for a topic. Please prioritize for de, ar and zh wikis.")
        
        static let addedTopicAlertTitle = WMFLocalizedString("talk-pages-topic-added-alert-title", value: "Your topic was added", comment: "Title for alert informing that the user's new topic was successfully published. Please prioritize for de, ar and zh wikis.")
        static let addedCommentAlertTitle = WMFLocalizedString("talk-pages-comment-added-alert-title", value: "Your comment was added", comment: "Title for alert informing that the user's new comment was successfully published. Please prioritize for de, ar and zh wikis.")
        
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

extension TalkPageViewController: WMFPreferredLanguagesViewControllerDelegate {

    func languagesController(_ controller: WMFLanguagesViewController, didSelectLanguage language: MWKLanguageLink) {
        guard let currentLanguage = viewModel.siteURL.wmf_contentLanguageCode else {
            return
        }

        let selectedLanguage = language.contentLanguageCode

        if viewModel.pageType == .article {
            guard let newSiteURL = language.articleURL.wmf_site,
                  let newPageTitle = language.articleURL.wmf_title else {
                return
            }
            if selectedLanguage != currentLanguage {
                changeTalkPageLanguage(newSiteURL, pageTitle: "Talk:\(newPageTitle)")
            }
        } else {
            let newSiteURL = language.siteURL
            changeTalkPageLanguage(newSiteURL, pageTitle: viewModel.pageTitle)
        }
        controller.dismiss(animated: true)
    }
}

extension TalkPageViewController: TalkPageTopicReplyOnboardingDelegate {

    func presentTopicReplyOnboardingIfNecessary() {
        guard !UserDefaults.standard.wmf_userHasOnboardedToContributingToTalkPages else {
            return
        }

        let topicReplyOnboardingHostingViewController = TalkPageTopicReplyOnboardingHostingController(theme: theme)
        topicReplyOnboardingHostingViewController.delegate = self
        topicReplyOnboardingHostingViewController.modalPresentationStyle = .pageSheet
        self.topicReplyOnboardingHostingViewController = topicReplyOnboardingHostingViewController

        if let presentedViewController = presentedViewController {
            presentedViewController.present(topicReplyOnboardingHostingViewController, animated: true)
        } else {
            present(topicReplyOnboardingHostingViewController, animated: true)
        }
    }

    func userDidDismissTopicReplyOnboardingView() {
        UserDefaults.standard.wmf_userHasOnboardedToContributingToTalkPages = true
    }
}
