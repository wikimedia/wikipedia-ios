import UIKit
import WMF
import WMFComponents
import WMFData
import WMFNativeLocalizations
import WMFTestKitchen

/// App-side owner of the Saved tab. Builds the SwiftUI screen, presents the flows it leads to
/// and logs its events, as the other root tab coordinators do.
@MainActor
final class SavedCoordinator: NSObject, Coordinator {

    // The tab's navigation controller. Injected via `attach(navigationController:)` once the
    // Saved view controller has been wrapped in its tab navigation controller.
    private var tabNavigationController: UINavigationController?
    var navigationController: UINavigationController {
        guard let tabNavigationController else {
            fatalError("SavedCoordinator.navigationController accessed before attach(navigationController:)")
        }
        return tabNavigationController
    }

    var theme: Theme {
        didSet {
            allArticlesCoordinator?.theme = theme
            readingListsCoordinator?.theme = theme
            _profileCoordinator?.theme = theme
        }
    }
    private let dataStore: MWKDataStore

    private(set) weak var savedViewController: WMFSavedHostingController?
    private weak var viewModel: WMFSavedViewModel?
    private var allArticlesCoordinator: SavedAllArticlesCoordinator?
    private var readingListsCoordinator: ReadingListsCoordinator?
    private var progressObserver: SavedArticleDownloadProgressObserver?

    init(theme: Theme, dataStore: MWKDataStore) {
        self.theme = theme
        self.dataStore = dataStore
        super.init()
    }

    func attach(navigationController: UINavigationController) {
        tabNavigationController = navigationController
    }

    @discardableResult
    func start() -> Bool {
        navigationController.setViewControllers([makeSavedViewController()], animated: false)
        return true
    }

    func makeSavedViewController() -> WMFSavedHostingController {
        let navigationControllerProvider: () -> UINavigationController = { [unowned self] in
            self.navigationController
        }
        let allArticlesCoordinator = SavedAllArticlesCoordinator(navigationControllerProvider: navigationControllerProvider, dataStore: dataStore, theme: theme)
        let readingListsCoordinator = ReadingListsCoordinator(navigationControllerProvider: navigationControllerProvider, dataStore: dataStore, theme: theme)
        let progressViewModel = WMFSavedProgressViewModel()

        let viewModel = WMFSavedViewModel(
            allArticlesViewModel: allArticlesCoordinator.viewModel,
            readingListsViewModel: readingListsCoordinator.viewModel,
            progressViewModel: progressViewModel,
            discoverHeaderViewModel: makeDiscoverHeaderViewModel()
        )
        viewModel.loggingDelegate = self
        viewModel.didTapProfile = { [weak self] in
            self?.profileCoordinator?.start()
        }
        viewModel.didTapTabs = { [weak self] in
            self?.tabsCoordinator?.start()
        }
        viewModel.profileButtonNeedsBadgeProvider = { [weak self] in
            self?.profileButtonNeedsBadge ?? false
        }

        let hostingController = WMFSavedHostingController(viewModel: viewModel)

        self.allArticlesCoordinator = allArticlesCoordinator
        self.readingListsCoordinator = readingListsCoordinator
        self.progressObserver = SavedArticleDownloadProgressObserver(
            viewModel: progressViewModel,
            isInitialSyncPending: { [dataStore] in dataStore.readingListsController.isInitialSyncPending },
            isServerBusy: { [dataStore] in dataStore.session.serverBusyPauseUntil != nil }
        )
        self.viewModel = viewModel
        self.savedViewController = hostingController
        return hostingController
    }

    // MARK: - Discover

    private let discoverNoThanksToastTitle = WMFLocalizedString("discover-announcement-no-thanks-toast", value: "To set up your recommended reading list later, go to Settings.", comment: "Toast shown after the reader dismisses the Discover onboarding card on the Saved tab.")

    /// Each card decides for itself whether it shows, and rechecks every time Saved appears, so a
    /// developer setting flipped while the app runs takes effect without a relaunch.
    private func makeDiscoverHeaderViewModel() -> WMFSavedDiscoverHeaderViewModel {
        WMFSavedDiscoverHeaderViewModel(announcementViewModel: makeDiscoverAnnouncementViewModel(), entryCardViewModel: makeDiscoverEntryCardViewModel())
    }

    private func makeDiscoverAnnouncementViewModel() -> WMFDiscoverAnnouncementViewModel {
        let viewModel = WMFDiscoverAnnouncementViewModel()
        viewModel.loggingDelegate = self
        viewModel.didTapGetStarted = { [weak self] in
            self?.showDiscoverSetup()
        }
        viewModel.didTapNoThanks = { [weak self] in
            guard let self else { return }
            WMFToastPresenter.shared.show(WMFToastConfig(title: self.discoverNoThanksToastTitle))
        }
        return viewModel
    }

    private func makeDiscoverEntryCardViewModel() -> WMFDiscoverEntryCardViewModel {
        let viewModel = WMFDiscoverEntryCardViewModel()
        viewModel.loggingDelegate = self
        viewModel.usernameProvider = { [dataStore] in
            dataStore.authenticationManager.authStatePermanentUsername
        }
        viewModel.didTap = { [weak self] in
            self?.showDiscoverReadingList()
        }
        return viewModel
    }

    /// The coordinators outlive the tap: they load before the push and answer the screens' callbacks.
    private var discoverSetupCoordinator: DiscoverSetupCoordinator?
    private var discoverReadingListCoordinator: DiscoverReadingListCoordinator?

    private func showDiscoverSetup() {
        let coordinator = DiscoverSetupCoordinator(navigationController: navigationController, dataStore: dataStore, theme: theme)
        discoverSetupCoordinator = coordinator
        coordinator.start()
    }

    private func showDiscoverReadingList() {
        let coordinator = DiscoverReadingListCoordinator(navigationController: navigationController, dataStore: dataStore, theme: theme)
        discoverReadingListCoordinator = coordinator
        coordinator.start()
    }

    // MARK: - Profile, tabs and Year in Review

    private var yirDataController: WMFYearInReviewDataController? {
        try? WMFYearInReviewDataController()
    }

    private var _yirCoordinator: YearInReviewCoordinator?
    private var yirCoordinator: YearInReviewCoordinator? {
        guard let yirDataController else {
            return nil
        }
        if let _yirCoordinator {
            return _yirCoordinator
        }
        let coordinator = YearInReviewCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore, dataController: yirDataController)
        coordinator.badgeDelegate = self
        _yirCoordinator = coordinator
        return coordinator
    }

    private var _profileCoordinator: ProfileCoordinator?
    private var profileCoordinator: ProfileCoordinator? {
        guard let yirCoordinator else {
            return nil
        }
        if let _profileCoordinator {
            return _profileCoordinator
        }
        let coordinator = ProfileCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore, donateSouce: .savedProfile, logoutDelegate: self, sourcePage: ProfileCoordinatorSource.saved, yirCoordinator: yirCoordinator)
        coordinator.badgeDelegate = self
        _profileCoordinator = coordinator
        return coordinator
    }

    private lazy var tabsCoordinator: TabsOverviewCoordinator? = {
        TabsOverviewCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore)
    }()

    /// The same rule as every other root tab, through the shared `profileButtonConfig` helper.
    private var profileButtonNeedsBadge: Bool {
        guard let savedViewController else {
            return false
        }
        let config = savedViewController.profileButtonConfig(target: savedViewController, action: #selector(WMFSavedHostingController.didTapProfile), dataStore: dataStore, yirDataController: yirDataController)
        return config.needsBadge
    }
}

// MARK: - WMFSavedLoggingDelegate

extension SavedCoordinator: WMFSavedLoggingDelegate {
    func savedDidAppear() {
        ArticleTabsFunnel.shared.logIconImpression(interface: .saved, project: nil)
        logSavedImpression()
    }

    func savedDidShowSegment(_ segment: WMFSavedViewModel.Segment) {
        switch segment {
        case .allArticles:
            ReadingListsFunnel.shared.logTappedAllArticlesTab()
        case .readingLists:
            ReadingListsFunnel.shared.logTappedReadingListsTab()
        }
    }

    func savedDidSelectSegment(_ segment: WMFSavedViewModel.Segment) {
        switch segment {
        case .allArticles:
            NavigationEventsFunnel.shared.logEvent(action: .savedAll)
        case .readingLists:
            NavigationEventsFunnel.shared.logEvent(action: .savedLists)
        }
        logSavedImpression()
    }

    /// The counts are what the screen holds at this moment. Before the first load they are 0.
    private func logSavedImpression() {
        guard let viewModel else { return }
        SavedInstrumentation.shared.logImpression(
            segment: viewModel.segment,
            listCount: viewModel.readingListsViewModel.readingLists.count,
            articleCount: viewModel.allArticlesViewModel.articles.count
        )
    }

    func savedDidTapEditAllArticles() {
        ReadingListsFunnel.shared.logTappedEditButton()
    }

    func savedDidTapProfile() {
        guard let languageCode = dataStore.languageLinkController.appLanguage?.languageCode,
              let metricsID = DonateCoordinator.metricsID(for: .savedProfile, languageCode: languageCode) else {
            return
        }
        DonateFunnel.shared.logSavedProfile(metricsID: metricsID)
    }

    func savedDidTapTabs() {
        ArticleTabsFunnel.shared.logIconClick(interface: .saved, project: nil)
    }
}

// MARK: - WMFDiscoverAnnouncementLoggingDelegate

extension SavedCoordinator: WMFDiscoverAnnouncementLoggingDelegate {
    func discoverAnnouncementDidAppear() {
        DiscoverInstrumentation.shared.logAnnouncementImpression()
    }

    func discoverAnnouncementDidTapGetStarted() {
        DiscoverInstrumentation.shared.logAnnouncementGetStartedTap()
    }

    func discoverAnnouncementDidTapNoThanks() {
        DiscoverInstrumentation.shared.logAnnouncementNoThanksTap()
    }
}

// MARK: - WMFDiscoverEntryCardLoggingDelegate

extension SavedCoordinator: WMFDiscoverEntryCardLoggingDelegate {
    /// No event of its own: the impression of the segment says that Discover is on.
    func discoverEntryCardDidAppear() {}

    func discoverEntryCardDidTap() {
        DiscoverInstrumentation.shared.logEntryCardTap(segment: viewModel?.segment ?? .allArticles)
    }
}

// MARK: - YearInReviewBadgeDelegate

extension SavedCoordinator: YearInReviewBadgeDelegate {
    func updateYIRBadgeVisibility() {
        viewModel?.refreshProfileButtonBadge()
    }
}

// MARK: - LogoutCoordinatorDelegate

extension SavedCoordinator: LogoutCoordinatorDelegate {
    func didTapLogout(authInstrument: InstrumentImpl) {
        let dataStore = self.dataStore
        savedViewController?.wmf_showKeepSavedArticlesOnDevicePanelIfNeeded(triggeredBy: .logout, theme: theme, authInstrument: authInstrument) {
            dataStore.authenticationManager.logout(initiatedBy: .user, authInstrument: authInstrument)
        }
    }
}
