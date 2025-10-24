import WMFData
import CocoaLumberjackSwift
import WMFComponents
import WMF
import Combine

final class WMFActivityTabHostingController: WMFComponentHostingController<WMFActivityTabView> {}

@objc final class WMFActivityTabViewController: WMFCanvasViewController, WMFNavigationBarConfiguring {
    private let theme: Theme
    private var yirDataController: WMFYearInReviewDataController? {
        return try? WMFYearInReviewDataController()
    }
    private let dataStore: MWKDataStore?
    private let hostingController: WMFActivityTabHostingController
    public let viewModel: WMFActivityTabViewModel
    private let dataController: WMFActivityTabDataController
    
    public init(dataStore: MWKDataStore?, theme: Theme, viewModel: WMFActivityTabViewModel, dataController: WMFActivityTabDataController) {
        self.dataStore = dataStore
        self.viewModel = viewModel
        let view = WMFActivityTabView(viewModel: viewModel)
        self.hostingController = WMFActivityTabHostingController(rootView: view)
        self.dataController = dataController
        self.theme = theme
        super.init()
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(updateLoginState), name:WMFAuthenticationManager.didLogInNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateLoginState), name:WMFAuthenticationManager.didLogOutNotification, object: nil) // < new line
        addComponent(hostingController, pinToEdges: true, respectSafeArea: true)
    }
    
    @objc private func updateLoginState() {
        if let username = dataStore?.authenticationManager.authStatePermanentUsername {
            viewModel.updateUsername(username: username)
        } else {
            viewModel.updateUsername(username: "")
        }
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

    private lazy var tabsCoordinator: TabsOverviewCoordinator? = { [weak self] in
        guard let self, let nav = self.navigationController, let dataStore else { return nil }
        return TabsOverviewCoordinator(
            navigationController: nav,
            theme: self.theme,
            dataStore: dataStore
        )
    }()

    private var _profileCoordinator: ProfileCoordinator?
    private var profileCoordinator: ProfileCoordinator? {

        guard let navigationController,
              let yirCoordinator = self.yirCoordinator,
              let dataStore else {
            return nil
        }

        guard let existingProfileCoordinator = _profileCoordinator else {
            _profileCoordinator = ProfileCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore, donateSouce: .activityTabProfile, logoutDelegate: self, sourcePage: ProfileCoordinatorSource.activity, yirCoordinator: yirCoordinator)
            _profileCoordinator?.badgeDelegate = self
            return _profileCoordinator
        }

        return existingProfileCoordinator
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        didLogIn()
        
        configureNavigationBar()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 18, *) {
            if UIDevice.current.userInterfaceIdiom == .pad {
                if previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass {
                    configureNavigationBar()
                }
            }
        }
    }
    
    @objc private func didLogIn() {
        if let username = dataStore?.authenticationManager.authStatePermanentUsername {
            viewModel.updateUsername(username: username)
        } else {
            viewModel.updateUsername(username: "")
        }
    }
    
    private lazy var moreBarButtonItem: UIBarButtonItem = {
        let button = UIBarButtonItem(image: WMFSFSymbolIcon.for(symbol: .ellipsisCircle), primaryAction: nil, menu: overflowMenu)
        button.accessibilityLabel = CommonStrings.moreButton
        return button
    }()
    
    var overflowMenu: UIMenu {
        let mainMenu = UIMenu(title: String(), children: [])

        return mainMenu
    }
    
    private func configureNavigationBar() {
        
        var titleConfig: WMFNavigationBarTitleConfig = WMFNavigationBarTitleConfig(title: CommonStrings.activityTitle, customView: nil, alignment: .leadingCompact)
        extendedLayoutIncludesOpaqueBars = false
        if #available(iOS 18, *) {
            if UIDevice.current.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .regular {
                titleConfig = WMFNavigationBarTitleConfig(title: CommonStrings.activityTitle, customView: nil, alignment: .leadingLarge)
                extendedLayoutIncludesOpaqueBars = true
            }
        }
        
        let profileButtonConfig: WMFNavigationBarProfileButtonConfig?
        let tabsButtonConfig: WMFNavigationBarTabsButtonConfig?
        if let dataStore {
            profileButtonConfig = self.profileButtonConfig(target: self, action: #selector(userDidTapProfile), dataStore: dataStore, yirDataController: yirDataController, leadingBarButtonItem: nil)
            tabsButtonConfig = self.tabsButtonConfig(target: self, action: #selector(userDidTapTabs), dataStore: dataStore, leadingBarButtonItem: moreBarButtonItem)
        } else {
            profileButtonConfig = nil
            tabsButtonConfig = nil
        }

        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: nil, profileButtonConfig: profileButtonConfig, tabsButtonConfig: tabsButtonConfig, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }

    @objc func userDidTapTabs() {
        tabsCoordinator?.start()
        ArticleTabsFunnel.shared.logIconClick(interface: .activity, project: nil)
    }

    @objc func userDidTapProfile() {
        
        guard let dataStore else {
            return
        }
        
        guard let languageCode = dataStore.languageLinkController.appLanguage?.languageCode,
              let metricsID = DonateCoordinator.metricsID(for: .activityTabProfile, languageCode: languageCode) else {
            return
        }
              
        profileCoordinator?.start()
    }
    
    private func updateProfileButton() {
        
        guard let dataStore else {
            return
        }
        
        let config = self.profileButtonConfig(target: self, action: #selector(userDidTapProfile), dataStore: dataStore, yirDataController: yirDataController, leadingBarButtonItem: nil)
        updateNavigationBarProfileButton(needsBadge: config.needsBadge, needsBadgeLabel: CommonStrings.profileButtonBadgeTitle, noBadgeLabel: CommonStrings.profileButtonTitle)
    }
}

// MARK: - Extensions

extension WMFActivityTabViewController: YearInReviewBadgeDelegate {
    public func updateYIRBadgeVisibility() {
         updateProfileButton()
    }
}

extension WMFActivityTabViewController: LogoutCoordinatorDelegate {
    func didTapLogout() {

        guard let dataStore else {
            return
        }

        wmf_showKeepSavedArticlesOnDevicePanelIfNeeded(triggeredBy: .logout, theme: theme) {
            dataStore.authenticationManager.logout(initiatedBy: .user)
        }
    }
}

extension WMFActivityTabViewController: ShareableArticlesProvider {}
