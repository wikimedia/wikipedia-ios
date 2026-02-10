import WMFData
import CocoaLumberjackSwift
import WMFComponents
import WMF
import Combine

public final class WMFSettingsHostingController: WMFComponentHostingController<WMFSettingsView> {}

@objc final class SettingsViewController: WMFCanvasViewController, WMFNavigationBarConfiguring, Themeable {

    // MARK: - Properties

    private var theme: Theme
    private let dataStore: MWKDataStore?
    private let hostingController: WMFSettingsHostingController
    private let viewModel: WMFSettingsViewModel
    private let coordinatorDelegate: SettingsCoordinatorDelegate?

    private var yirDataController: WMFYearInReviewDataController? {
        return try? WMFYearInReviewDataController()
    }

    // MARK: - Coordinators

    private lazy var tabsCoordinator: TabsOverviewCoordinator? = { [weak self] in
        guard let self, let nav = self.navigationController, let dataStore else { return nil }
        return TabsOverviewCoordinator(
            navigationController: nav,
            theme: self.theme,
            dataStore: dataStore
        )
    }()

    private var _yirCoordinator: YearInReviewCoordinator?
    private var yirCoordinator: YearInReviewCoordinator? {
        guard let navigationController,
              let yirDataController,
              let dataStore else {
            return nil
        }

        guard let existingYirCoordinator = _yirCoordinator else {
            _yirCoordinator = YearInReviewCoordinator(
                navigationController: navigationController,
                theme: theme,
                dataStore: dataStore,
                dataController: yirDataController
            )
            return _yirCoordinator
        }

        return existingYirCoordinator
    }

    private var _profileCoordinator: ProfileCoordinator?
    private var profileCoordinator: ProfileCoordinator? {
        guard let navigationController,
              let yirCoordinator = self.yirCoordinator,
              let dataStore else {
            return nil
        }

        guard let existingProfileCoordinator = _profileCoordinator else {
            _profileCoordinator = ProfileCoordinator(
                navigationController: navigationController,
                theme: theme,
                dataStore: dataStore,
                donateSouce: .settingsProfile,
                logoutDelegate: nil,
                sourcePage: .exploreOptOut,
                yirCoordinator: yirCoordinator
            )
            return _profileCoordinator
        }

        return existingProfileCoordinator
    }

    // MARK: - Initialization

    public init(viewModel: WMFSettingsViewModel, coordinatorDelegate: SettingsCoordinatorDelegate?, dataStore: MWKDataStore?, theme: Theme) {
        self.viewModel = viewModel
        self.coordinatorDelegate = coordinatorDelegate
        self.dataStore = dataStore
        self.theme = theme

        let view = WMFSettingsView(viewModel: viewModel)
        self.hostingController = WMFSettingsHostingController(rootView: view)

        super.init()
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()

        // Observe authentication state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userAuthenticationStateDidChange),
            name: WMFAuthenticationManager.didLogInNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userAuthenticationStateDidChange),
            name: WMFAuthenticationManager.didLogOutNotification,
            object: nil
        )

        // Add hosting controller as a child
        addComponent(hostingController, pinToEdges: true, respectSafeArea: true)

        // Configure navigation bar
        configureNavigationBar()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateProfileButton()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Navigation Bar Configuration

    private func configureNavigationBar() {
        var titleConfig: WMFNavigationBarTitleConfig = WMFNavigationBarTitleConfig(
            title: CommonStrings.settingsTitle,
            customView: nil,
            alignment: .leadingCompact
        )

        extendedLayoutIncludesOpaqueBars = false

        if #available(iOS 18, *) {
            if UIDevice.current.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .regular {
                titleConfig = WMFNavigationBarTitleConfig(
                    title: CommonStrings.settingsTitle,
                    customView: nil,
                    alignment: .leadingLarge
                )
                extendedLayoutIncludesOpaqueBars = true
            }
        }

        let profileButtonConfig: WMFNavigationBarProfileButtonConfig?
        let tabsButtonConfig: WMFNavigationBarTabsButtonConfig?

        if let dataStore {
            profileButtonConfig = self.profileButtonConfig(
                target: self,
                action: #selector(userDidTapProfile),
                dataStore: dataStore,
                yirDataController: yirDataController,
                leadingBarButtonItem: nil
            )
            tabsButtonConfig = self.tabsButtonConfig(
                target: self,
                action: #selector(userDidTapTabs),
                dataStore: dataStore,
                leadingBarButtonItem: nil
            )
        } else {
            profileButtonConfig = nil
            tabsButtonConfig = nil
        }

        configureNavigationBar(
            titleConfig: titleConfig,
            closeButtonConfig: nil,
            profileButtonConfig: profileButtonConfig,
            tabsButtonConfig: tabsButtonConfig,
            searchBarConfig: nil,
            hideNavigationBarOnScroll: true
        )
    }

    // MARK: - Actions

    @objc private func userDidTapTabs() {
        tabsCoordinator?.start()
        ArticleTabsFunnel.shared.logIconClick(interface: .mainPage, project: nil)
    }

    @objc private func userDidTapProfile() {
        guard let dataStore else {
            return
        }

        guard let languageCode = dataStore.languageLinkController.appLanguage?.languageCode,
              DonateCoordinator.metricsID(for: .settingsProfile, languageCode: languageCode) != nil else {
            return
        }

        profileCoordinator?.start()

        // Log metrics
        if let metricsID = DonateCoordinator.metricsID(for: .settingsProfile, languageCode: languageCode) {
            DonateFunnel.shared.logExploreOptOutProfileClick(metricsID: metricsID)
        }
    }

    @objc private func userAuthenticationStateDidChange() {
        Task { @MainActor [weak self] in
            guard let self = self else { return }

            // Fetch current authentication state from dataStore
            let username = self.dataStore?.authenticationManager.authStatePermanentUsername
            let tempUsername = self.dataStore?.authenticationManager.authStateTemporaryUsername
            let isTempAccount = WMFTempAccountDataController.shared.primaryWikiHasTempAccountsEnabled &&
                                self.dataStore?.authenticationManager.authStateIsTemporary == true

            // Update view model with new authentication state
            await self.viewModel.updateAuthenticationState(
                username: username,
                tempUsername: tempUsername,
                isTempAccount: isTempAccount
            )

            // Update profile button
            updateProfileButton()
        }
    }

    @objc func updateProfileButton() {
        guard let dataStore else {
            return
        }

        let config = self.profileButtonConfig(
            target: self,
            action: #selector(userDidTapProfile),
            dataStore: dataStore,
            yirDataController: yirDataController,
            leadingBarButtonItem: nil
        )

        updateNavigationBarProfileButton(
            needsBadge: config.needsBadge,
            needsBadgeLabel: CommonStrings.profileButtonBadgeTitle,
            noBadgeLabel: CommonStrings.profileButtonTitle
        )
    }

    // MARK: - Themeable

    func apply(theme: Theme) {
        self.theme = theme
        hostingController.view.setNeedsLayout()
    }
}
