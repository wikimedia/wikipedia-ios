import WMF
import CocoaLumberjackSwift
import WMFComponents
import WMFData

public enum InputAccessoryViewType {
    case format
    case findInPage
}

class TalkPageViewController: ThemeableViewController, WMFNavigationBarConfiguring {

    // MARK: - Properties

    let viewModel: TalkPageViewModel
    fileprivate var headerView: TalkPageHeaderView?
    let findInPageState = TalkPageFindInPageState()

    internal var preselectedTextRange = UITextRange()

    fileprivate var topicReplyOnboardingHostingViewController: TalkPageTopicReplyOnboardingHostingController?
    
    fileprivate lazy var shareButton: IconBarButtonItem = IconBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(userDidTapShareButton))
    
    fileprivate lazy var findButton: IconBarButtonItem = IconBarButtonItem(image: UIImage(systemName: "doc.text.magnifyingglass"), style: .plain, target: self, action: #selector(userDidTapFindButton))
    
    fileprivate lazy var revisionButton: IconBarButtonItem = IconBarButtonItem(image: UIImage(systemName: "clock.arrow.circlepath"), style: .plain, target: self, action: #selector(userDidTapRevisionButton))
    
    fileprivate lazy var addTopicButton: IconBarButtonItem = IconBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(userDidTapAddTopicButton))
    
    var talkPageView: TalkPageView {
        return view as! TalkPageView
    }
    
    private let textFormattingToolbarView = TalkPageFormattingToolbarView()

    private(set) var inputAccessoryViewType: InputAccessoryViewType?

    override var inputAccessoryView: UIView? {
        guard let inputAccessoryViewType = inputAccessoryViewType else {
            return nil
        }

        switch inputAccessoryViewType {
        case .findInPage:
            return findInPageState.keyboardBar
        case .format:
            textFormattingToolbarView.apply(theme: theme)
            textFormattingToolbarView.delegate = self
            return textFormattingToolbarView
        }
    }
    
    var scrollingToIndexPath: IndexPath?
    var scrollingToResult: TalkPageFindInPageSearchController.SearchResult?
    var scrollingToCommentViewModel: TalkPageCellCommentViewModel?
    
    private var lastViewDidAppearDate: Date?
    
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

        let  goToArchivesAction = UIAction(title: TalkPageLocalizedStrings.archives, image: UIImage(systemName: "archivebox"), handler: { [weak self] _ in
            self?.pushToArchives()
        })

        let pageInfoAction = UIAction(title: TalkPageLocalizedStrings.pageInfo, image: UIImage(systemName: "info.circle"), handler: { [weak self] _ in
            self?.pushToPageInfo()
        })

        let goToPermalinkAction = UIAction(title: TalkPageLocalizedStrings.permaLink, image: UIImage(systemName: "link"), handler: { [weak self] _ in
            self?.pushToPermanentLink()
        })

        let changeLanguageAction = UIAction(title: TalkPageLocalizedStrings.changeLanguage, image: UIImage(named: "language-talk-page"), handler: { _ in
            self.hideFindInPage()
            self.userDidTapChangeLanguage()
        })

        let relatedLinksAction = UIAction(title: TalkPageLocalizedStrings.relatedLinks, image: UIImage(systemName: "arrowshape.turn.up.forward"), handler: { [weak self] _ in
            self?.pushToWhatLinksHere()
        })

        var actions = [goToArchivesAction, pageInfoAction, goToPermalinkAction, relatedLinksAction]
        
        if viewModel.project.languageCode != nil {
            actions.insert(changeLanguageAction, at: 3)
        }

        if viewModel.pageType == .user {
            actions.insert(contentsOf: userTalkOverflowSubmenuActions, at: 1)

        }
        let aboutTalkPagesAction = UIAction(title: TalkPageLocalizedStrings.aboutTalkPages, image: UIImage(systemName: "doc.plaintext"), handler: { [weak self] _ in
            self?.pushToAboutTalkPages()
        })
        actions.append(aboutTalkPagesAction)

        return actions
    }

    var overflowMenu: UIMenu {
        
        let openAllAction = UIAction(title: TalkPageLocalizedStrings.openAllThreads, image: UIImage(systemName: "square.stack"), handler: { _ in
            self.hideFindInPage()

            for topic in self.viewModel.topics {
                topic.isThreadExpanded = true
            }

            self.talkPageView.collectionView.reloadData()
        })
        
        let revisionHistoryAction = UIAction(title: CommonStrings.revisionHistory, image: UIImage(systemName: "clock.arrow.circlepath"), handler: { [weak self] _ in
            self?.pushToRevisionHistory()
        })
        
        let editSourceAction = UIAction(title: TalkPageLocalizedStrings.editSource, image: WMFIcon.pencil, handler: { [weak self] _ in
            
            guard let self else {
                return
            }
            
            self.pushToEditor()
            
            if let project = WikimediaProject(siteURL: self.viewModel.siteURL) {
                EditInteractionFunnel.shared.logTalkDidTapEditSourceButton(project: project)
            }
        })
        
        let openInWebAction = UIAction(title: TalkPageLocalizedStrings.readInWeb, image: UIImage(systemName: "display"), handler: { [weak self] _ in
            self?.pushToDesktopWeb()
        })
        
        let submenu = UIMenu(title: String(), options: .displayInline, children: overflowSubmenuActions)
        let children: [UIMenuElement] = [openAllAction, revisionHistoryAction, editSourceAction, openInWebAction, submenu]
        let mainMenu = UIMenu(title: String(), children: children)

        return mainMenu
    }

    // MARK: - Lifecycle

    init(theme: Theme, viewModel: TalkPageViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.theme = theme
        hidesBottomBarWhenPushed = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let talkPageView = TalkPageView(frame: UIScreen.main.bounds)
        view = talkPageView
    }

    fileprivate func fetchTalkPage() {
        self.headerView = nil
        viewModel.fetchTalkPage { [weak self] result in

            guard let self = self else {
                return
            }

            switch result {
            case .success:
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

        setupOverflowMenu()

        talkPageView.collectionView.dataSource = self
        talkPageView.collectionView.delegate = self

        talkPageView.emptyView.scrollView.delegate = self

        fetchTalkPage()
        setupToolbar()

        Task {
            self.viewModel.wikiHasTempAccounts = await checkWikiStatus()
            replyComposeController.wikiHasTempAccounts = self.viewModel.wikiHasTempAccounts
        }

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIWindow.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didLogIn), name:WMFAuthenticationManager.didLogInNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureNavigationBar()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let headerViewHeight = self.headerView?.frame.height ?? 0
        talkPageView.updateEmptyErrorViewsTopPadding(padding: headerViewHeight)
    }
    
    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: TalkPageLocalizedStrings.title, customView: nil, alignment: .centerCompact)
        
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: nil, profileButtonConfig: nil, tabsButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reachabilityNotifier.start()
        lastViewDidAppearDate = Date()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        hideFindInPage(releaseKeyboardBar: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        reachabilityNotifier.stop()
    }
    
    override func accessibilityPerformEscape() -> Bool {
        if replyComposeController.containerView != nil {
            replyComposeController.attemptClose()
            return true
        }
        
        return super.accessibilityPerformEscape()
    }

    @objc func tryAgain() {
        fetchTalkPage()
    }

    private func checkWikiStatus() async -> Bool? {
        guard let languageCode = viewModel.siteURL.wmf_languageCode else { return false }
        let dataController = WMFTempAccountDataController.shared
        return await dataController.asyncCheckWikiTempAccountAvailability(language: languageCode, isCheckingPrimaryWiki: false)
    }

    private func setupOverflowMenu() {
        let rightBarButtonItem = UIBarButtonItem(image: WMFSFSymbolIcon.for(symbol: .ellipsisCircle), primaryAction: nil, menu: overflowMenu)
        rightBarButtonItem.accessibilityLabel = Self.TalkPageLocalizedStrings.overflowMenuAccessibilityLabel
        navigationItem.rightBarButtonItem = rightBarButtonItem
        rightBarButtonItem.tintColor = theme.colors.link
    }
    
    @objc private func didLogIn() {
        if let replyComposeContentView = replyComposeController.contentView {
            replyComposeContentView.ipTempButton.isHidden = true
        } else if let topicComposeVC = self.topicComposeVC {
            topicComposeVC.ipTempButton.isHidden = true
        }
    }
    
    // MARK: - Keyboard
    
    @objc func keyboardWillChangeFrame(_ notification: Notification) {
        if let window = view.window, let endFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let windowFrame = window.convert(endFrame, from: nil)
            keyboardFrame = window.convert(windowFrame, to: view)
        }
    }
        
    @objc func keyboardDidHide(_ notification: Notification) {
        keyboardFrame = nil
    }
    
    private(set) var keyboardFrame: CGRect? {
        didSet {
            keyboardDidChangeFrame(from: oldValue, newKeyboardFrame: keyboardFrame)
        }
    }
    
    func keyboardDidChangeFrame(from oldKeyboardFrame: CGRect?, newKeyboardFrame: CGRect?) {

        guard oldKeyboardFrame != newKeyboardFrame else {
            return
        }
        
        replyComposeController.calculateLayout(in: self, newKeyboardFrame: newKeyboardFrame)
        
        view.setNeedsLayout()
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }

    // MARK: - Coffee Roll

    @objc private func userDidTapCoffeeRollReadMoreButton() {
        let coffeeRollViewModel = TalkPageCoffeeRollViewModel(coffeeRollText: viewModel.coffeeRollText, talkPageURL: viewModel.getTalkPageURL(encoded: true), semanticContentAttribute: viewModel.semanticContentAttribute)
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
            present(WMFComponentNavigationController(rootViewController: languageVC, modalPresentationStyle: .overFullScreen), animated: true, completion: nil)
        } else if viewModel.pageType == .article {
            guard let languageCode  = viewModel.siteURL.wmf_languageCode else {
                return
            }
            if let articleTitle = viewModel.pageTitle.extractingArticleTitleFromTalkPage(languageCode: languageCode)?.denormalizedPageTitle {
                if let articleURL = viewModel.siteURL.wmf_URL(withTitle: articleTitle) {
                    let languageVC = WMFArticleLanguagesViewController(articleURL: articleURL)
                    languageVC.delegate = self
                    let navVC = WMFComponentNavigationController(rootViewController: languageVC, modalPresentationStyle: .overFullScreen)
                    present(navVC, animated: true, completion: nil)
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

        findInPageState.keyboardBar?.apply(theme: theme)
    }

    func rethemeVisibleCells() {
        talkPageView.collectionView.visibleCells.forEach { cell in
            if let talkCell = cell as? TalkPageCell {
                talkCell.apply(theme: theme)
            }
        }
    }

    // MARK: - Reply Compose Management
    
    let replyComposeController = TalkPageReplyComposeController()

    private var isClosing: Bool = false
    
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

    
    @objc fileprivate func userDidTapShareButton() {
        guard let talkPageURL = viewModel.getTalkPageURL(encoded: false) else {
            return
        }

        let activityController = UIActivityViewController(activityItems: [talkPageURL], applicationActivities: [TUSafariActivity()])
        present(activityController, animated: true)
    }
    
    @objc fileprivate func userDidTapFindButton() {
        for topic in viewModel.topics {
            topic.isThreadExpanded = true
        }

        inputAccessoryViewType = .findInPage
        talkPageView.collectionView.reloadData()

        showFindInPage()
    }
    
    @objc fileprivate func userDidTapRevisionButton() {
        pushToRevisionHistory()
    }

    fileprivate func showAddTopic() {
        if let lastViewDidAppearDate = lastViewDidAppearDate {
            TalkPagesFunnel.shared.logTappedNewTopic(routingSource: viewModel.source, project: viewModel.project, talkPageType: viewModel.pageType, lastViewDidAppearDate: lastViewDidAppearDate)
        }
        let topicComposeViewModel = TalkPageTopicComposeViewModel(semanticContentAttribute: viewModel.semanticContentAttribute, siteURL: viewModel.siteURL, pageLink: viewModel.getTalkPageURL(encoded: false), wikiHasTempAccounts: viewModel.wikiHasTempAccounts)

        let tappedIPTempButtonAction: () -> Void = { [weak self] in
            self?.presentIPTempModalIfNeeded(dismissAction: {
                // do nothing upon dismiss
            })
        }
        
        let topicComposeVC = TalkPageTopicComposeViewController(viewModel: topicComposeViewModel, authenticationManager: viewModel.authenticationManager, theme: theme, tappedIPTempButtonAction: tappedIPTempButtonAction)
        topicComposeVC.delegate = self
        inputAccessoryViewType = .format
        if let url = viewModel.getTalkPageURL(encoded: false) {
            EditAttemptFunnel.shared.logInit(pageURL: url)
        }
        let navVC = WMFComponentNavigationController(rootViewController: topicComposeVC, modalPresentationStyle: .pageSheet)
        navVC.presentationController?.delegate = self
        present(navVC, animated: true) { [weak self] in
            self?.presentIPTempWarningToastIfNeeded()
        }
    }

    @objc fileprivate func userDidTapAddTopicButton() {
        
        let showAddTopicAction: () -> Void = { [weak self] in
            self?.showAddTopic()
            
            if UIAccessibility.isVoiceOverRunning {
                if let height = self?.replyComposeController.containerView?.frame.height, height >= 1.0 {
                    UIAccessibility.post(notification: .screenChanged, argument: self?.replyComposeController.containerView)
                }
            }
        }
        
        let presentNewTopicAction: () -> Void = { [weak self] in
            if UserDefaults.standard.wmf_userHasOnboardedToContributingToTalkPages {
                showAddTopicAction()
            } else {
                self?.presentTopicReplyOnboarding(dismissAction: showAddTopicAction)
            }
        }
        
        presentIPTempModalIfNeeded(dismissAction: presentNewTopicAction)
    }
    
    private var topicComposeVC: TalkPageTopicComposeViewController? {
        guard let presentedNavVC = presentedViewController as? UINavigationController else { return nil }
        guard let topicComposeVC = presentedNavVC.viewControllers.first as? TalkPageTopicComposeViewController else { return nil }
        
        return topicComposeVC
    }
    
    private var topicComposeNavVC: UINavigationController? {
        guard let presentedNavVC = presentedViewController as? UINavigationController else { return nil }
        guard presentedNavVC.viewControllers.first is TalkPageTopicComposeViewController else { return nil }
        
        return presentedNavVC
    }
    
    private func presentIPTempModalIfNeeded(dismissAction: @escaping () -> Void) {
        let navigationController = topicComposeNavVC ?? navigationController
        if let navigationController, let wikiHasTempAccounts = viewModel.wikiHasTempAccounts, !viewModel.authenticationManager.authStateIsPermanent && wikiHasTempAccounts {
            let tempAccountsCoordinator = TempAccountSheetCoordinator(
                navigationController: navigationController,
                theme: theme,
                dataStore: viewModel.dataStore,
                didTapDone: { [weak self] in
                    let vcToDismiss = self?.topicComposeVC ?? self
                    vcToDismiss?.dismiss(animated: true)
            }, didTapContinue: { [weak self] in
                    let vcToDismiss = self?.topicComposeVC ?? self
                    vcToDismiss?.dismiss(animated: true, completion: {
                        dismissAction()
                    })
                },
                isTempAccount: viewModel.authenticationManager.authStateIsTemporary
            )
            
            _ = tempAccountsCoordinator.start()
        } else {
            dismissAction()
        }
    }
    
    private func presentIPTempWarningToastIfNeeded() {
        if let wikiHasTempAccounts = viewModel.wikiHasTempAccounts, !viewModel.authenticationManager.authStateIsPermanent, wikiHasTempAccounts {
            if viewModel.authenticationManager.authStateIsTemporary {
                WMFAlertManager.sharedInstance.showBottomAlertWithMessage(CommonStrings.tempWarningTitle, subtitle: CommonStrings.tempWarningSubtitle(username: viewModel.authenticationManager.authStateTemporaryUsername ?? "*****"), buttonTitle: nil, image: WMFSFSymbolIcon.for(symbol: .exclamationMarkCircleFill), dismissPreviousAlerts: true)
            } else {
                WMFAlertManager.sharedInstance.showBottomWarningAlertWithMessage(CommonStrings.ipWarningTitle, subtitle: CommonStrings.ipWarningSubtitle,  buttonTitle: nil, image: WMFSFSymbolIcon.for(symbol: .exclamationMarkTriangleFill), dismissPreviousAlerts: true)
            }
        }
    }
    
    private var flexibleSpaceToolbarItem: UIBarButtonItem {
        return UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    }
    
    fileprivate func setupToolbar() {
        talkPageView.toolbar.items = [shareButton,  flexibleSpaceToolbarItem, revisionButton, flexibleSpaceToolbarItem, findButton,flexibleSpaceToolbarItem, addTopicButton]
        
        shareButton.accessibilityLabel = TalkPageLocalizedStrings.shareButtonAccesibilityLabel
        findButton.accessibilityLabel = TalkPageLocalizedStrings.findButtonAccesibilityLabel
        revisionButton.accessibilityLabel = CommonStrings.revisionHistory
        addTopicButton.accessibilityLabel = TalkPageLocalizedStrings.addTopicButtonAccesibilityLabel
    }
    
    // MARK: - Overflow menu navigation
    
    fileprivate func pushToRevisionHistory() {
        let historyVC = PageHistoryViewController(pageTitle: viewModel.pageTitle, pageURL: viewModel.siteURL, articleSummaryController: viewModel.dataController.articleSummaryController, authenticationManager: viewModel.authenticationManager)
        historyVC.apply(theme: theme)
        navigationController?.pushViewController(historyVC, animated: true)
    }
    
    fileprivate func pushToEditor() {
        
        let pushToEditorAction: () -> Void = { [weak self] in
            
            guard let self else { return }
            
            guard let pageURL = viewModel.siteURL.wmf_URL(withTitle: viewModel.pageTitle) else {
                return
            }
            
            let dataStore = MWKDataStore.shared()

            let editorViewController = EditorViewController(pageURL: pageURL, sectionID: nil, editFlow: .editorSavePreview, source: .talk, dataStore: dataStore, articleSelectedInfo: nil, editTag: .appTalkSource, delegate: self, theme: theme)
            
            let navigationController = WMFComponentNavigationController(rootViewController: editorViewController, modalPresentationStyle: .overFullScreen)
            present(navigationController, animated: true)
            
            guard let url = viewModel.siteURL.wmf_URL(withTitle: viewModel.pageTitle) else {
                return
            }
            
            EditAttemptFunnel.shared.logInit(pageURL: url)
        }
        
        let presentOnboardingAction: () -> Void = { [weak self] in
            if UserDefaults.standard.wmf_userHasOnboardedToContributingToTalkPages {
                pushToEditorAction()
            } else {
                self?.presentTopicReplyOnboarding(dismissAction: pushToEditorAction)
            }
        }
        
        presentIPTempModalIfNeeded(dismissAction: presentOnboardingAction)
        
    }

    fileprivate func pushToDesktopWeb() {
        guard let url = viewModel.siteURL.wmf_URL(withPath: "/wiki/\(viewModel.pageTitle)") else {
            showGenericError()
            return
        }
        
        navigate(to: url, useSafari: true)
    }
    
    fileprivate func pushToArchives() {
        let archivesViewModel = TalkPageArchivesViewModel(talkPageViewModel: viewModel)
        let archivesVC = TalkPageArchivesViewController(viewModel: archivesViewModel, theme: theme)
        navigationController?.pushViewController(archivesVC, animated: true)
    }
    
    fileprivate func pushToPageInfo() {
        
        guard let host = viewModel.siteURL.host,
              let url = Configuration.current.expandedArticleURLForHost(host, languageVariantCode: viewModel.siteURL.wmf_languageVariantCode, queryParameters: ["title": viewModel.pageTitle,
                                                                                                                                                                "action": "info"]) else {
            showGenericError()
            return
        }
        
        navigate(to: url)
    }
    
    fileprivate func pushToWhatLinksHere() {
        guard let url = viewModel.siteURL.wmf_URL(withPath: "/wiki/Special:WhatLinksHere/\(viewModel.pageTitle)") else {
            showGenericError()
            return
        }
        
        navigate(to: url)
    }
    
    fileprivate func pushToContributions() {
        guard let username = usernameFromPageTitle(),
              let url = viewModel.siteURL.wmf_URL(withPath: "/wiki/Special:Contributions/\(username)") else {
            showGenericError()
            return
        }
        if let lastViewDidAppearDate {
            TalkPagesFunnel.shared.logTappedContributions(routingSource: .talkPage, project: viewModel.project, talkPageType: viewModel.pageType, lastViewDidAppearDate: lastViewDidAppearDate)
        }
        navigate(to: url)
    }
    
    fileprivate func pushToUserGroups() {
        guard let username = usernameFromPageTitle(),
              let url = viewModel.siteURL.wmf_URL(withPath: "/wiki/Special:UserRights/\(username)") else {
            showGenericError()
            return
        }
        
        navigate(to: url)
    }
    
    fileprivate func pushToLogs() {
        guard let username = usernameFromPageTitle(),
              let url = viewModel.siteURL.wmf_URL(withPath: "/wiki/Special:Log/\(username)") else {
            showGenericError()
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
              let siteURL = viewModel.siteURL.wmf_URL(withPath: ""),
              let host = siteURL.host,
              let url = Configuration.current.expandedArticleURLForHost(host, languageVariantCode: viewModel.siteURL.wmf_languageVariantCode, queryParameters: ["title": viewModel.pageTitle,
                                                                                                                                                                "oldid": latestRevisionID]) else {
            showGenericError()
            return
        }
        
        navigate(to: url, useSafari: true)
    }
    
    fileprivate func pushToAboutTalkPages() {
        guard let url = URL(string: "https://www.mediawiki.org/wiki/Wikimedia_Apps/iOS_FAQ#Talk_pages") else {
            return
        }
        
        navigate(to: url, useSafari: true)
    }
    
    // MARK: - Alerts
    
    fileprivate func handleSubscriptionAlert(isSubscribedToTopic: Bool) {
        let title = isSubscribedToTopic ? TalkPageLocalizedStrings.subscribedAlertTitle : TalkPageLocalizedStrings.unsubscribedAlertTitle
        let subtitle = isSubscribedToTopic ? TalkPageLocalizedStrings.subscribedAlertSubtitle : TalkPageLocalizedStrings.unsubscribedAlertSubtitle
        let image = isSubscribedToTopic ? UIImage(systemName: "bell.fill") : UIImage(systemName: "bell.slash.fill")

        let voiceoverAnnoucement = title + subtitle
        
        if UIAccessibility.isVoiceOverRunning {
            DispatchQueue.main.async {
                UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: voiceoverAnnoucement)
            }
        } else {
            WMFAlertManager.sharedInstance.showBottomAlertWithMessage(title, subtitle: subtitle, image: image, type: .custom, customTypeName: "subscription-success", dismissPreviousAlerts: true)
        }
    }

    fileprivate func subscriptionErrorAlert(isSubscribed: Bool) {
        let title = isSubscribed ? TalkPageLocalizedStrings.unsubscriptionFailed : TalkPageLocalizedStrings.subscriptionFailed

        if UIAccessibility.isVoiceOverRunning {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: title)
            }
        } else {
            WMFAlertManager.sharedInstance.showBottomAlertWithMessage(title, subtitle: nil, image: UIImage(systemName: "exclamationmark.circle"), type: .custom, customTypeName: "subscription-error", dismissPreviousAlerts: true)
        }
    }
    
    var tempAccountsMediaWikiURL: String {
        var languageCodeSuffix = ""
        if let primaryAppLanguageCode = viewModel.languageLinkController.appLanguage?.languageCode {
            languageCodeSuffix = "\(primaryAppLanguageCode)"
        }
        return "https://www.mediawiki.org/wiki/Special:MyLanguage/Help:Temporary_accounts?uselang=\(languageCodeSuffix)"
    }
    
    private func handleNewTopicOrCommentAlert(isNewTopic: Bool, needsFollowupTempAccountToast: Bool) {
        let title = isNewTopic ? TalkPageLocalizedStrings.addedTopicAlertTitle : TalkPageLocalizedStrings.addedCommentAlertTitle
        let image = UIImage(systemName: "checkmark.circle.fill")
        
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: title)
        } else {
            let tempAccountUsername = viewModel.authenticationManager.authStateTemporaryUsername
            WMFAlertManager.sharedInstance.showBottomAlertWithMessage(
                title,
                subtitle: nil,
                image: image,
                type: .custom,
                customTypeName: "edit-published",
                dismissPreviousAlerts: true,
                completion: {
                    let title = CommonStrings.tempAccountCreatedToastTitle
                    let subtitle = CommonStrings.tempAccountCreatedToastSubtitle(username: tempAccountUsername)
                    let image = WMFIcon.temp
                    if needsFollowupTempAccountToast {
                        WMFAlertManager.sharedInstance.showBottomAlertWithMessage(
                            title,
                            subtitle: subtitle,
                            image: image,
                            type: .custom,
                            customTypeName: "edit-published",
                            dismissPreviousAlerts: true,
                            buttonTitle: CommonStrings.learnMoreTitle(),
                            buttonCallBack: {
                                if let url = URL(string: self.tempAccountsMediaWikiURL) {
                                    let config = SinglePageWebViewController.StandardConfig(url: url, useSimpleNavigationBar: true)
                                    let webVC = SinglePageWebViewController(configType: .standard(config), theme: self.theme)
                                    let newNavigationVC =
                                    WMFComponentNavigationController(rootViewController: webVC, modalPresentationStyle: .formSheet)
                                    self.present(newNavigationVC, animated: true)
                                }
                            }
                        )
                    }
                })
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
        
        talkPageView.collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
        
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
            let stringFromTitle = cellViewModel.topicTitleHtml.removingHTML
            if stringFromTitle == topicTitle {
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
                if commentViewModel.html.removingHTML.contains(replyText.removingHTML) {
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
    
    func scrollToComment(commentViewModel: TalkPageCellCommentViewModel, animated: Bool = true) {

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

        guard let project = WikimediaProject(siteURL: siteURL, languageLinkController: viewModel.languageLinkController) else {
            showGenericError()
            return
        }
        
        if let lastViewDidAppearDate = lastViewDidAppearDate {
            TalkPagesFunnel.shared.logChangedLanguage(routingSource: viewModel.source, project: viewModel.project, talkPageType: viewModel.pageType, lastViewDidAppearDate: lastViewDidAppearDate)
        }
        
        viewModel.resetToNewSiteURL(siteURL, pageTitle: pageTitle, project: project)
        setupOverflowMenu()
        
        fetchTalkPage()
    }

    // MARK: Reachability notifier - internet connection monitoring

    lazy var reachabilityNotifier: ReachabilityNotifier = {
        let notifier = ReachabilityNotifier(Configuration.current.defaultSiteDomain) { [weak self] (reachable, _) in
            if reachable {
                DispatchQueue.main.async {
                    self?.hideOfflineAlertIfNeeded()
                }
            } else {
                DispatchQueue.main.async {
                    self?.showOfflineAlertIfNeeded()
                }
            }
        }
        return notifier
    }()

    fileprivate func showOfflineAlertIfNeeded() {
        let title = CommonStrings.noInternetConnection
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: title)
        } else {
            WMFAlertManager.sharedInstance.showErrorAlertWithMessage(title, subtitle: nil, buttonTitle: nil, image: UIImage(systemName: "exclamationmark.circle"), dismissPreviousAlerts: true)
        }
    }

    fileprivate func hideOfflineAlertIfNeeded() {
        WMFAlertManager.sharedInstance.dismissAllAlerts()
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
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard indexPath.section == 0 else {
            return UICollectionReusableView()
        }
        
        if let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: TalkPageHeaderView.reuseIdentifier, for: indexPath) as? TalkPageHeaderView {
            headerView.configure(viewModel: viewModel)
            headerView.coffeeRollReadMoreButton.addTarget(self, action: #selector(userDidTapCoffeeRollReadMoreButton), for: .primaryActionTriggered)
            headerView.apply(theme: theme)
            self.headerView = headerView
            return headerView
        }
        
        return UICollectionReusableView()
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
        guard let cellViewModel = cellViewModel,
              let indexOfConfiguredCell = viewModel.topics.firstIndex(where: {$0 === cellViewModel}),
               isShowingFindInPage == false else {
            return
        }
        
        let configuredCellViewModel = viewModel.topics[indexOfConfiguredCell]
        configuredCellViewModel.isThreadExpanded.toggle()
        
        cell.removeExpandedElements()
        cell.configure(viewModel: configuredCellViewModel, linkDelegate: self)
        cell.apply(theme: theme)
        talkPageView.collectionView.collectionViewLayout.invalidateLayout()
        
        if configuredCellViewModel.isThreadExpanded,
        let lastViewDidAppearDate = lastViewDidAppearDate {
            TalkPagesFunnel.shared.logExpandedTopic(routingSource: viewModel.source, project: viewModel.project, talkPageType: viewModel.pageType, lastViewDidAppearDate: lastViewDidAppearDate)
        }
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
                self.subscriptionErrorAlert(isSubscribed: configuredCellViewModel.isSubscribed)
            }
        }
    }

    // MARK: - Empty State

    fileprivate func updateEmptyStateVisibility() {
        talkPageView.updateEmptyView(visible: viewModel.topics.count == 0)
    }

    fileprivate func updateErrorStateVisibility() {
        talkPageView.updateErrorView(visible: viewModel.shouldShowErrorState)
    }

}

extension TalkPageViewController: TalkPageCellReplyDelegate {
    func tappedReply(commentViewModel: TalkPageCellCommentViewModel, accessibilityFocusView: UIView?) {
        hideFindInPage(releaseKeyboardBar: true)
        inputAccessoryViewType = .format

        if let url = viewModel.getTalkPageURL(encoded: false) {
            EditAttemptFunnel.shared.logInit(pageURL: url)
        }
        
        let showReplyComposeAction = { [weak self] in
            guard let self else { return }
            
            replyComposeController.setupAndDisplay(in: self, commentViewModel: commentViewModel, authenticationManager: viewModel.authenticationManager, accessibilityFocusView: accessibilityFocusView)
            
            presentIPTempWarningToastIfNeeded()
        }

        let presentOnboardingAction: () -> Void = { [weak self] in
            if UserDefaults.standard.wmf_userHasOnboardedToContributingToTalkPages {
                showReplyComposeAction()
            } else {
                self?.presentTopicReplyOnboarding(dismissAction: showReplyComposeAction)
            }
        }
        
        presentIPTempModalIfNeeded(dismissAction: presentOnboardingAction)
        
        if let lastViewDidAppearDate = lastViewDidAppearDate {
            TalkPagesFunnel.shared.logTappedInlineReply(routingSource: viewModel.source, project: viewModel.project, talkPageType: viewModel.pageType, lastViewDidAppearDate: lastViewDidAppearDate)
        }
    }
}

extension TalkPageViewController: TalkPageReplyComposeDelegate {
    func tappedIPTempButton() {
        presentIPTempModalIfNeeded(dismissAction: {
            // do nothing upon dismiss
        })
    }
    
    func closeReplyView() {
        replyComposeController.closeAndReset { focusView in
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(notification: .screenChanged, argument: focusView)
            }
            if let talkPageURL = self.viewModel.getTalkPageURL(encoded: false) {
                EditAttemptFunnel.shared.logAbort(pageURL: talkPageURL)
            }
        }
    }
    
    func tappedPublish(text: String, commentViewModel: TalkPageCellCommentViewModel) {
        
        var wasIP = false
        if let wikiHasTempAccounts = viewModel.wikiHasTempAccounts, !viewModel.authenticationManager.authStateIsPermanent && wikiHasTempAccounts {
            if !viewModel.authenticationManager.authStateIsTemporary {
                wasIP = true
            }
        }

        if let talkPageURL = viewModel.getTalkPageURL(encoded: false) {
            EditAttemptFunnel.shared.logSaveAttempt(pageURL: talkPageURL)
        }

        let oldCellViewModel = commentViewModel.cellViewModel
        let oldCommentViewModels = oldCellViewModel?.allCommentViewModels
        
        if let lastViewDidAppearDate = lastViewDidAppearDate {
            TalkPagesFunnel.shared.logTappedPublishNewTopicOrInlineReply(routingSource: viewModel.source, project: viewModel.project, talkPageType: viewModel.pageType, lastViewDidAppearDate: lastViewDidAppearDate)
        }
        
        viewModel.postReply(commentId: commentViewModel.commentId, comment: text) { [weak self] result in

            guard let self else {
                return
            }

            switch result {
            case .success:
                self.replyComposeController.closeAndReset()
                
                // Try to refresh page
                self.viewModel.fetchTalkPage { [weak self] result in
                    
                    guard let self else { return }
                    
                    switch result {
                    case .success(let revID):
                        self.updateEmptyStateVisibility()
                        self.talkPageView.collectionView.reloadData()
                        
                        var isTemp = false
                        if let wikiHasTempAccounts = viewModel.wikiHasTempAccounts, !viewModel.authenticationManager.authStateIsPermanent && wikiHasTempAccounts {
                            if viewModel.authenticationManager.authStateIsTemporary {
                                isTemp = true
                            }
                        }
                        
                        self.handleNewTopicOrCommentAlert(isNewTopic: false, needsFollowupTempAccountToast: wasIP && isTemp)
                        if let talkPageURL = self.viewModel.getTalkPageURL(encoded: false) {
                            EditAttemptFunnel.shared.logSaveSuccess(pageURL: talkPageURL, revisionId: revID, project: WikimediaProject(siteURL: talkPageURL))
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.scrollToNewComment(oldCellViewModel: oldCellViewModel, oldCommentViewModels: oldCommentViewModels)
                        }

                    case .failure:
                        if let talkPageURL = self.viewModel.getTalkPageURL(encoded: false) {
                            EditAttemptFunnel.shared.logSaveFailure(pageURL: talkPageURL)
                        }
                    }
                }
            case .failure(let error):
                DDLogError("Failure publishing reply: \(error)")
                self.replyComposeController.isLoading = false
                if let talkPageURL = self.viewModel.getTalkPageURL(encoded: false) {
                    EditAttemptFunnel.shared.logSaveFailure(pageURL: talkPageURL)
                }

                if (error as NSError).wmf_isNetworkConnectionError() {
                    let title = TalkPageLocalizedStrings.replyFailedAlertTitle
                    if UIAccessibility.isVoiceOverRunning {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: title)
                        }
                    } else {
                        WMFAlertManager.sharedInstance.showErrorAlertWithMessage(title, subtitle: TalkPageLocalizedStrings.failureAlertSubtitle, buttonTitle: nil, image: UIImage(systemName: "exclamationmark.circle"), dismissPreviousAlerts: true)
                    }
                } else {
                    self.showUnexpectedErrorAlert(on: self)
                }
            }
        }
    }

    fileprivate func showUnexpectedErrorAlert(on viewController: UIViewController) {
        let alert = UIAlertController(title: TalkPageLocalizedStrings.unexpectedErrorAlertTitle, message: TalkPageLocalizedStrings.unexpectedErrorAlertSubtitle, preferredStyle: .alert)
        let action = UIAlertAction(title: CommonStrings.okTitle, style: .default)
        alert.addAction(action)
        viewController.present(alert, animated: true)
    }

}

// MARK: Extensions

extension TalkPageViewController: TalkPageTopicComposeViewControllerDelegate {
    func tappedPublish(topicTitle: String, topicBody: String, composeViewController: TalkPageTopicComposeViewController) {
        
        var wasIP = false
        if let wikiHasTempAccounts = viewModel.wikiHasTempAccounts, !viewModel.authenticationManager.authStateIsPermanent && wikiHasTempAccounts {
            if !viewModel.authenticationManager.authStateIsTemporary {
                wasIP = true
            }
        }
        
        if let lastViewDidAppearDate = lastViewDidAppearDate {
            TalkPagesFunnel.shared.logTappedPublishNewTopicOrInlineReply(routingSource: viewModel.source, project: viewModel.project, talkPageType: viewModel.pageType, lastViewDidAppearDate: lastViewDidAppearDate)
        }

        viewModel.postTopic(topicTitle: topicTitle, topicBody: topicBody) { [weak self] result in
            
            guard let self else { return }

            switch result {
            case .success:
                
                composeViewController.dismiss(animated: true) { [weak self] in
                    
                    guard let self else { return }
                    
                    var isTemp = false
                    if let wikiHasTempAccounts = viewModel.wikiHasTempAccounts, !viewModel.authenticationManager.authStateIsPermanent && wikiHasTempAccounts {
                        if viewModel.authenticationManager.authStateIsTemporary {
                            isTemp = true
                        }
                    }
                    
                    self.handleNewTopicOrCommentAlert(isNewTopic: true, needsFollowupTempAccountToast: wasIP && isTemp)
                }
                
                // Try to refresh page
                self.viewModel.fetchTalkPage { [weak self] result in
                    
                    
                    switch result {
                    case .success:
                        self?.updateEmptyStateVisibility()
                        self?.talkPageView.collectionView.reloadData()
                        self?.scrollToLastTopic()
                        if let viewModel = self?.viewModel, let pageURL = viewModel.getTalkPageURL(encoded: false) {
                            EditAttemptFunnel.shared.logSaveSuccess(pageURL: pageURL, revisionId: viewModel.latestRevisionID, project: WikimediaProject(siteURL: pageURL))
                        }
                    case .failure:
                        if let viewModel = self?.viewModel, let pageURL = viewModel.getTalkPageURL(encoded: false) {
                            EditAttemptFunnel.shared.logSaveFailure(pageURL: pageURL)
                        }
                    }
                }
            case .failure(let error):
                
                DDLogError("Failure publishing topic: \(error)")
                composeViewController.setupNavigationBar(isPublishing: false)

                if let pageURL = viewModel.getTalkPageURL(encoded: false) {
                    EditAttemptFunnel.shared.logSaveFailure(pageURL: pageURL)
                }
                
                if (error as NSError).wmf_isNetworkConnectionError() {
                    let title = TalkPageLocalizedStrings.newTopicFailedAlertTitle
                    if UIAccessibility.isVoiceOverRunning {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: title)
                        }
                    } else {
                        WMFAlertManager.sharedInstance.showErrorAlertWithMessage(title, subtitle: TalkPageLocalizedStrings.failureAlertSubtitle, buttonTitle: nil, image: UIImage(systemName: "exclamationmark.circle"), dismissPreviousAlerts: true)
                    }
                } else {
                    self.showUnexpectedErrorAlert(on: composeViewController)
                }
            }
        }
    }
}

extension TalkPageViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        guard let topicComposeVC = self.topicComposeVC else {
            return true
        }

        guard topicComposeVC.shouldBlockDismissal else {
            return true
        }

        if !UIAccessibility.isVoiceOverRunning {
            topicComposeVC.presentDismissConfirmationActionSheet()
        }
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
        static let editSource = WMFLocalizedString("talk-pages-edit-source", value: "Edit source", comment: "Title for menu option to edit the full source of the talk page.")
        
        static let subscribedAlertTitle = WMFLocalizedString("talk-page-subscribed-alert-title", value: "You have subscribed!", comment: "Title for alert informing that the user subscribed to a topic. Please prioritize for de, ar and zh wikis.")
        static let unsubscribedAlertTitle = WMFLocalizedString("talk-page-unsubscribed-alert-title", value: "You have unsubscribed.", comment: "Title for alert informing that the user unsubscribed to a topic. Please prioritize for de, ar and zh wikis.")
        static let subscribedAlertSubtitle = WMFLocalizedString("talk-page-subscribed-alert-subtitle", value: "You will receive notifications about new comments in this topic.", comment: "Subtitle for alert informing that the user will receive notifications for a subscribed topic. Please prioritize for de, ar and zh wikis.")
        static let unsubscribedAlertSubtitle = WMFLocalizedString("talk-page-unsubscribed-alert-subtitle", value: "You will no longer receive notifications about new comments in this topic.", comment: "Subtitle for alert informing that the user will no longer receive notifications for a topic. Please prioritize for de, ar and zh wikis.")
        
        static let addedTopicAlertTitle = WMFLocalizedString("talk-pages-topic-added-alert-title", value: "Your topic was added", comment: "Title for alert informing that the user's new topic was successfully published. Please prioritize for de, ar and zh wikis.")
        static let addedCommentAlertTitle = WMFLocalizedString("talk-pages-comment-added-alert-title", value: "Your comment was added", comment: "Title for alert informing that the user's new comment was successfully published. Please prioritize for de, ar and zh wikis.")
        
        static let shareButtonAccesibilityLabel = WMFLocalizedString("talk-page-share-button", value: "Share talk page", comment: "Title for share talk page button")
        static let findButtonAccesibilityLabel = WMFLocalizedString("talk-page-find-in-page-button", value: "Find in page", comment: "Title for find content in page button")
        static let addTopicButtonAccesibilityLabel = WMFLocalizedString("talk-page-add-topic-button", value: "Add topic", comment: "Title for add topic to talk page button")
        static let unsubscriptionFailed = WMFLocalizedString("talk-page-unsubscription-failed-alert", value: "Unsubscribing to the topic failed, please try again.", comment: "Text for the unsubscription failure alert")
        static let subscriptionFailed = WMFLocalizedString("talk-page-subscription-failed-alert", value: "Subscribing to the topic failed, please try again.", comment: "Text for the subscription failure alert")
        static let replyFailedAlertTitle = WMFLocalizedString("talk-page-publish-reply-error-title", value: "Unable to publish your comment.", comment: "Title for topic reply error alert")
        static let newTopicFailedAlertTitle = WMFLocalizedString("talk-page-publish-topic-error-title", value: "Unable to publish new topic.", comment: "Title for new topic post error alert")
        static let failureAlertSubtitle = WMFLocalizedString("talk-page-publish-reply-error-subtitle", value: "Please check your internet connection.", comment: "Subtitle for topic reply error alert")
        static let unexpectedErrorAlertTitle = CommonStrings.unexpectedErrorAlertTitle
        static let unexpectedErrorAlertSubtitle = WMFLocalizedString("talk-page-error-alert-subtitle", value: "The app received an unexpected response from the server. Please try again later.", comment: "Subtitle for unexpected error alert")
        static let overflowMenuAccessibilityLabel = WMFLocalizedString("talk-page-overflow-menu-accessibility", value: "More Talk Page Options", comment: "Accessibility label for the talk page overflow menu button, which displays more navigation options to the user.")
    }
}

protocol TalkPageTextViewLinkHandling: AnyObject {
    func tappedLink(_ url: URL, sourceTextView: UITextView)
}

extension TalkPageViewController: TalkPageTextViewLinkHandling {
    func tappedLink(_ url: URL, sourceTextView: UITextView) {
        guard let url = URL(string: url.absoluteString, relativeTo: viewModel.getTalkPageURL(encoded: true)) else {
            return
        }
        
        let legacyNavigateAction = { [weak self] in
            
            guard let self else { return }
            let userInfo: [AnyHashable : Any] = [RoutingUserInfoKeys.source: RoutingUserInfoSourceValue.talkPage.rawValue]
            navigate(to: url.absoluteURL, userInfo: userInfo)
        }
        
        // first try to navigate using LinkCoordinator. If it fails, use the legacy approach.
        if let navigationController {
            
            let linkCoordinator = LinkCoordinator(navigationController: navigationController, url: url.absoluteURL, dataStore: nil, theme: theme, articleSource: .undefined)
            let success = linkCoordinator.start()
            guard success else {
                legacyNavigateAction()
                return
            }
        } else {
            legacyNavigateAction()
        }
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

// MARK: Onboarding

extension TalkPageViewController {
    
    func presentTopicReplyOnboarding(dismissAction: @escaping () -> Void) {
        let topicReplyOnboardingHostingViewController = TalkPageTopicReplyOnboardingHostingController(dismissAction: dismissAction, theme: theme)
        topicReplyOnboardingHostingViewController.modalPresentationStyle = .pageSheet
        self.topicReplyOnboardingHostingViewController = topicReplyOnboardingHostingViewController
        
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .screenChanged, argument: topicReplyOnboardingHostingViewController)
        }
        
        present(topicReplyOnboardingHostingViewController, animated: true)
        
        UserDefaults.standard.wmf_userHasOnboardedToContributingToTalkPages = true
    }
}

// MARK: - EditorViewControllerDelegate

extension TalkPageViewController: EditorViewControllerDelegate {
    func editorDidCancelEditing(_ editor: EditorViewController, navigateToURL url: URL?) {
        dismiss(animated: true) {
            self.navigate(to: url)
        }
    }
    
    func editorDidFinishEditing(_ editor: EditorViewController, result: Result<EditorChanges, Error>, needsNewTempAccountToast: Bool?) {
        switch result {
        case .failure(let error):
            showError(error)
        case .success:
            dismiss(animated: true) { [weak self] in
                
                guard let self else {
                    return
                }
                
                let title = CommonStrings.editPublishedToastTitle
                let image = UIImage(systemName: "checkmark.circle.fill")
                
                if UIAccessibility.isVoiceOverRunning {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: title)
                    }
                } else {
                    WMFAlertManager.sharedInstance.showBottomAlertWithMessage(title, subtitle: nil, image: image, type: .custom, customTypeName: "edit-published", dismissPreviousAlerts: true)
                }
                
                // Refresh page
                self.viewModel.fetchTalkPage { [weak self] result in
                    
                    
                    switch result {
                    case .success:
                        self?.updateEmptyStateVisibility()
                        self?.talkPageView.collectionView.reloadData()
                    case .failure:
                        break
                    }
                }
            }
        }
    }
}
