import WMFData
import CocoaLumberjackSwift
import WMFComponents
import WMF
import Combine


final class WMFHistoryHostingController: WMFComponentHostingController<WMFHistoryView> {

}

@objc public final class WMFHistoryViewController: WMFCanvasViewController, Themeable, WMFNavigationBarConfiguring, HintPresenting, MEPEventsProviding {

    // MARK: - Properties

    private var theme: Theme
    private let dataStore: MWKDataStore?
    private let hostingController: WMFHistoryHostingController
    var viewModel: WMFHistoryViewModel
    var dataController: WMFHistoryDataController
    var deleteButton: UIBarButtonItem?
    private var viewModelCancellables = Set<AnyCancellable>()

    // MARK: - Hint presenting protocol properties

    var hintController: HintController?

    // MARK: - MEP Protocol properties

    public var eventLoggingCategory: EventCategoryMEP {
        return .history
    }

    public var eventLoggingLabel: EventLabelMEP? {
        return nil
    }

    // MARK: - Profile button dependencies

    private var _yirCoordinator: YearInReviewCoordinator?
    var yirCoordinator: YearInReviewCoordinator? {

        guard let navigationController,
              let yirDataController,
              let dataStore else {
            return nil
        }

        guard let existingYirCoordinator = _yirCoordinator else {
            _yirCoordinator = YearInReviewCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore, dataController: yirDataController)
            _yirCoordinator?.badgeDelegate = self
            return _yirCoordinator
        }

        return existingYirCoordinator
    }

    private var _tabsCoordinator: TabsOverviewCoordinator?
    private var tabsCoordinator: TabsOverviewCoordinator? {
        guard let navigationController, let dataStore else { return nil }
        _tabsCoordinator = TabsOverviewCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore)
        return _tabsCoordinator
    }

    private var _profileCoordinator: ProfileCoordinator?
    private var profileCoordinator: ProfileCoordinator? {

        guard let navigationController,
              let yirCoordinator = self.yirCoordinator,
              let dataStore else {
            return nil
        }

        guard let existingProfileCoordinator = _profileCoordinator else {
            _profileCoordinator = ProfileCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore, donateSouce: .historyProfile, logoutDelegate: self, sourcePage: ProfileCoordinatorSource.history, yirCoordinator: yirCoordinator)
            _profileCoordinator?.badgeDelegate = self
            return _profileCoordinator
        }

        return existingProfileCoordinator
    }

    private var yirDataController: WMFYearInReviewDataController? {
        return try? WMFYearInReviewDataController()
    }

    // MARK: - Lifecycle

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(viewModel: WMFHistoryViewModel, dataController: WMFHistoryDataController, theme: Theme, dataStore: MWKDataStore) {
        self.theme = theme
        let view = WMFHistoryView(viewModel: viewModel)
        self.hostingController = WMFHistoryHostingController(rootView: view)
        self.dataStore = dataStore
        self.viewModel = viewModel
        self.dataController = dataController
        super.init()

        let deleteRecordAction: WMFHistoryDataController.DeleteRecordAction = { [weak self] historyItem in
            guard let self, let dataStore = self.dataStore else { return }
            let request: NSFetchRequest<WMFArticle> = WMFArticle.fetchRequest()
            request.predicate = NSPredicate(format: "pageID == %@", historyItem.id)
            do {
                if let article = try dataStore.viewContext.fetch(request).first {
                    try article.removeFromReadHistory()
                }

            } catch {
                showError(error)

            }
            guard let title = historyItem.url?.wmf_title,
                  let languageCode = historyItem.url?.wmf_languageCode else {
                return
            }

            let variant = historyItem.variant

            let project = WMFProject.wikipedia(WMFLanguage(languageCode: languageCode, languageVariantCode: variant))

            Task {
                do {
                    let dataController = try WMFPageViewsDataController()
                    try await dataController.deletePageView(title: title, namespaceID: 0, project: project)
                } catch {
                    DDLogError("Failure deleting WMFData WMFPageViews: \(error)")
                }
            }
        }

        let saveArticleAction: WMFHistoryDataController.SaveRecordAction = { [weak self] historyItem in
            guard let self, let dataStore = self.dataStore, let articleURL = historyItem.url else { return }
            dataStore.savedPageList.addSavedPage(with: articleURL)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(userDidSaveOrUnsaveArticle(_:)),
                                                   name: WMFReadingListsController.userDidSaveOrUnsaveArticleNotification,
                                                   object: nil)
            historyItem.isSaved = true
        }

        let unsaveArticleAction: WMFHistoryDataController.UnsaveRecordAction = { [weak self] historyItem in
            guard let self, let dataStore = self.dataStore, let articleURL = historyItem.url else { return }

            dataStore.savedPageList.removeEntry(with: articleURL)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(userDidSaveOrUnsaveArticle(_:)),
                                                   name: WMFReadingListsController.userDidSaveOrUnsaveArticleNotification,
                                                   object: nil)
            historyItem.isSaved = false
        }

        dataController.deleteRecordAction = deleteRecordAction
        dataController.saveRecordAction = saveArticleAction
        dataController.unsaveRecordAction = unsaveArticleAction

        let shareArticleAction: WMFHistoryViewModel.ShareRecordAction = { [weak self] frame, historyItem in
            guard let self else { return }
            self.share(item:historyItem, frame: frame)
        }

        let onTapArticleAction: WMFHistoryViewModel.OnRecordTapAction = { [weak self] historyItem in
            guard let self else { return }
            self.tappedArticle(historyItem)
        }

        viewModel.onTapArticle = onTapArticleAction
        viewModel.shareRecordAction = shareArticleAction
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        addComponent(hostingController, pinToEdges: true, respectSafeArea: true)

        viewModel.$isEmpty
            .receive(on: RunLoop.main)
            .sink { [weak self] isEmpty in
                self?.deleteButton?.isEnabled = !isEmpty
            }
            .store(in: &viewModelCancellables)
        setupReadingListsHelpers()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        configureNavigationBar()
    }

    // MARK: - Methods

    private func configureNavigationBar() {
        let deleteAllButtonText = WMFLocalizedString("history-clear-all", value: "Clear", comment: "Text of the button shown at the top of history which deletes all history {{Identical|Clear}}")
        var profileButtonConfig: WMFNavigationBarProfileButtonConfig? = nil
        var tabsButtonConfig: WMFNavigationBarTabsButtonConfig? = nil
        deleteButton = UIBarButtonItem(title: deleteAllButtonText, style: .plain, target: self, action: #selector(deleteButtonPressed(_:)))
        deleteButton?.isEnabled = !viewModel.isEmpty
        let hideNavigationBarOnScroll = !viewModel.isEmpty

        var titleConfig: WMFNavigationBarTitleConfig = WMFNavigationBarTitleConfig(title: CommonStrings.historyTabTitle, customView: nil, alignment: .leadingCompact)
        extendedLayoutIncludesOpaqueBars = false

        if #available(iOS 18, *) {
            if UIDevice.current.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .regular {
                titleConfig = WMFNavigationBarTitleConfig(title: CommonStrings.historyTabTitle, customView: nil, alignment: .leadingLarge)
                extendedLayoutIncludesOpaqueBars = true
            }
        }

        if let dataStore {
            profileButtonConfig = self.profileButtonConfig(target: self, action: #selector(userDidTapProfile), dataStore: dataStore, yirDataController: yirDataController, leadingBarButtonItem: nil)
            tabsButtonConfig = self.tabsButtonConfig(target: self, action: #selector(userDidTapTabs), dataStore: dataStore, leadingBarButtonItem: deleteButton)
        }

        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: nil, profileButtonConfig: profileButtonConfig, tabsButtonConfig: tabsButtonConfig, searchBarConfig: nil, hideNavigationBarOnScroll: hideNavigationBarOnScroll)

    }

    @objc func userDidTapProfile() {
        guard let dataStore else {
            return
        }

        guard let languageCode = dataStore.languageLinkController.appLanguage?.languageCode,
              let metricsID = DonateCoordinator.metricsID(for: .historyProfile, languageCode: languageCode) else {
            return
        }

        DonateFunnel.shared.logHistoryProfile(metricsID: metricsID)

        profileCoordinator?.start()
    }

    @objc func userDidTapTabs() {
        tabsCoordinator?.start()
        ArticleTabsFunnel.shared.logIconClick(interface: .history, project: nil)
    }

    func tappedArticle(_ item: HistoryItem) {
        if let articleURL = item.url, let dataStore, let navVC = navigationController {
            let articleCoordinator = ArticleCoordinator(navigationController: navVC, articleURL: articleURL, dataStore: dataStore, theme: theme, source: .history)
            articleCoordinator.start()
        }
    }

    func share(item: HistoryItem, frame: CGRect?) {
        if let dataStore, let url = item.url {
            let article = dataStore.fetchArticle(with: url)
            if let frame , let window = view.window {
                let convertedRect = view.convert(frame, from: window)
                let dummyView = UIView(frame: convertedRect)
                dummyView.translatesAutoresizingMaskIntoConstraints = true
                view.addSubview(dummyView)
                _ = share(article: article, articleURL: url, dataStore: dataStore, theme: theme, eventLoggingCategory: eventLoggingCategory, eventLoggingLabel: eventLoggingLabel, sourceView: dummyView)
            } else {
                _ = share(article: article, articleURL: url, dataStore: dataStore, theme: theme, eventLoggingCategory: eventLoggingCategory, eventLoggingLabel: eventLoggingLabel, sourceView: UIView(frame: .zero))
            }
        }
    }

    @objc final func deleteButtonPressed(_ sender: UIBarButtonItem) {

        let deleteAllConfirmationText = WMFLocalizedString("history-clear-confirmation-heading", value: "Are you sure you want to delete all your recent items?", comment: "Heading text of delete all confirmation dialog")
        let deleteAllText = WMFLocalizedString("history-clear-delete-all", value: "Yes, delete all", comment: "Button text for confirming delete all action")

        let alertController = UIAlertController(title: deleteAllConfirmationText, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: deleteAllText, style: .destructive, handler: { (action) in
            self.deleteAll()
        }))
        alertController.addAction(UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel, handler: nil))
        alertController.popoverPresentationController?.barButtonItem = sender
        alertController.popoverPresentationController?.permittedArrowDirections = .any
        present(alertController, animated: true, completion: nil)
    }

    private func deleteAll() {
        guard let dataStore else { return }
        do {
            try dataStore.viewContext.clearReadHistory()
            viewModel.sections.removeAll()

        } catch let error {
            showError(error)
        }

        Task {
            do {
                let dataController = try WMFPageViewsDataController()
                try await dataController.deleteAllPageViewsAndCategories()

            } catch {
                DDLogError("Failure deleting WMFData WMFPageViews: \(error)")
            }
        }
    }

    private func updateProfileButton() {

        guard let dataStore else {
            return
        }

        let config = self.profileButtonConfig(target: self, action: #selector(userDidTapProfile), dataStore: dataStore, yirDataController: yirDataController, leadingBarButtonItem: nil)
        updateNavigationBarProfileButton(needsBadge: config.needsBadge, needsBadgeLabel: CommonStrings.profileButtonBadgeTitle, noBadgeLabel: CommonStrings.profileButtonTitle)
    }

    // MARK: - Reading lists hint controller

    private func setupReadingListsHelpers() {
        guard let dataStore else { return }
        hintController = ReadingListHintController(dataStore: dataStore)
        hintController?.apply(theme: theme)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(userDidSaveOrUnsaveArticle(_:)),
                                               name: WMFReadingListsController.userDidSaveOrUnsaveArticleNotification,
                                               object: nil)
    }

    @objc private func userDidSaveOrUnsaveArticle(_ notification: Notification) {
        guard let article = notification.object as? WMFArticle else {
            return
        }

        showReadingListHint(for: article)
    }

    private func showReadingListHint(for article: WMFArticle) {

        guard let presentingVC = visibleHintPresentingViewController() else {
            return
        }

        let context: [String: Any] = [ReadingListHintController.ContextArticleKey: article]
        hintController?.setCustomHintVisibilityTime(7)
        toggleHint(hintController, context: context, presentingIn: presentingVC)
    }

    func visibleHintPresentingViewController() -> (UIViewController & HintPresenting)? {
        if let nav = self.tabBarController?.selectedViewController as? UINavigationController {
            return nav.topViewController as? (UIViewController & HintPresenting)
        }
        return nil
    }

    private func toggleHint(_ hintController: HintController?, context: [String: Any], presentingIn presentingVC: UIViewController) {

        if let presenting = presentingVC as? (UIViewController & HintPresenting) {
            hintController?.toggle(presenter: presenting, context: context, theme: theme)
        }
    }

    // MARK: Theming

    public func apply(theme: Theme) {
        guard viewIfLoaded != nil else {
            return
        }
        updateProfileButton()
        profileCoordinator?.theme = theme
        self.theme = theme
    }
}

// MARK: - Extensions

extension WMFHistoryViewController: YearInReviewBadgeDelegate {
    public func updateYIRBadgeVisibility() {
        updateProfileButton()
    }
}

extension WMFHistoryViewController: LogoutCoordinatorDelegate {
    func didTapLogout() {

        guard let dataStore else {
            return
        }

        wmf_showKeepSavedArticlesOnDevicePanelIfNeeded(triggeredBy: .logout, theme: theme) {
            dataStore.authenticationManager.logout(initiatedBy: .user)
        }
    }
}

extension WMFHistoryViewController: ShareableArticlesProvider {}
