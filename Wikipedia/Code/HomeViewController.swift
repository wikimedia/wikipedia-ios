import UIKit
import WMF
import WMFComponents
import WMFData
import WMFNativeLocalizations
import WMFTestKitchen

final class WMFHomeHostingController: WMFComponentHostingController<WMFHomeView> {}

/// App-side root view controller for the Home tab. Hosts the SwiftUI `WMFHomeView` and configures the
/// standard tab navigation bar (profile + tabs buttons), matching the other root tabs.
final class HomeViewController: UIViewController, WMFNavigationBarConfiguring, Themeable {

    private var theme: Theme
    private let dataStore: MWKDataStore
    let viewModel: WMFHomeViewModel
    private let hostingController: WMFHomeHostingController

    private var yirDataController: WMFYearInReviewDataController? {
        return try? WMFYearInReviewDataController()
    }

    // Doing basic persistence for now, All this logic should live in a data controller
    private static let selectedLanguageCodeDefaultsKey = "home-selected-language-code"
    private var persistedSelectedLanguageCode: String? {
        get { UserDefaults.standard.string(forKey: Self.selectedLanguageCodeDefaultsKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.selectedLanguageCodeDefaultsKey) }
    }

    init(dataStore: MWKDataStore, theme: Theme, viewModel: WMFHomeViewModel) {
        self.dataStore = dataStore
        self.theme = theme
        self.viewModel = viewModel
        self.hostingController = WMFHomeHostingController(rootView: WMFHomeView(viewModel: viewModel))
        super.init(nibName: nil, bundle: nil)
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = AccessibilityIdentifiers.RootTab.homeButton
        embedHostingController()

        viewModel.didSelectLanguage = { [weak self] languageCode in
            self?.selectLanguage(languageCode)
        }
        viewModel.didTapEditLanguages = { [weak self] in
            self?.presentLanguagesViewController()
        }
        reloadLanguages()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
        reloadLanguages()
    }

    // MARK: - Languages

    private func reloadLanguages() {
        let preferredLanguages = dataStore.languageLinkController.preferredLanguages
        viewModel.languages = preferredLanguages.map { WMFHomeViewModel.Language(code: $0.languageCode, localizedName: $0.localizedName) }

        if let persisted = persistedSelectedLanguageCode, preferredLanguages.contains(where: { $0.languageCode == persisted }) {
            viewModel.selectedLanguageCode = persisted
        } else {
            viewModel.selectedLanguageCode = dataStore.languageLinkController.appLanguage?.languageCode ?? preferredLanguages.first?.languageCode ?? ""
        }
    }

    private func selectLanguage(_ languageCode: String) {
        persistedSelectedLanguageCode = languageCode
        viewModel.selectedLanguageCode = languageCode
    }

    private func presentLanguagesViewController() {
        let languagesVC = WMFPreferredLanguagesViewController.preferredLanguagesViewController()
        languagesVC.showExploreFeedCustomizationSettings = true
        languagesVC.delegate = self
        (languagesVC as Themeable?)?.apply(theme: theme)
        let navVC = WMFComponentNavigationController(rootViewController: languagesVC, modalPresentationStyle: .overFullScreen)
        present(navVC, animated: true)
    }

    private func embedHostingController() {
        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingController.view)
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hostingController.didMove(toParent: self)
    }

    // MARK: - Coordinators

    private var _yirCoordinator: YearInReviewCoordinator?
    private var yirCoordinator: YearInReviewCoordinator? {
        guard let navigationController, let yirDataController else { return nil }
        if let _yirCoordinator { return _yirCoordinator }
        let coordinator = YearInReviewCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore, dataController: yirDataController)
        coordinator.badgeDelegate = self
        _yirCoordinator = coordinator
        return coordinator
    }

    private lazy var tabsCoordinator: TabsOverviewCoordinator? = { [weak self] in
        guard let self, let nav = self.navigationController else { return nil }
        return TabsOverviewCoordinator(navigationController: nav, theme: self.theme, dataStore: self.dataStore)
    }()

    private var _profileCoordinator: ProfileCoordinator?
    private var profileCoordinator: ProfileCoordinator? {
        guard let navigationController, let yirCoordinator else { return nil }
        if let _profileCoordinator { return _profileCoordinator }
        let coordinator = ProfileCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore, donateSouce: .exploreProfile, logoutDelegate: self, sourcePage: .explore, yirCoordinator: yirCoordinator)
        coordinator.badgeDelegate = self
        _profileCoordinator = coordinator
        return coordinator
    }

    // MARK: - Navigation Bar

    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: CommonStrings.homeTabTitle, customView: nil, alignment: .hidden)

        let profileButtonConfig = self.profileButtonConfig(target: self, action: #selector(userDidTapProfile), dataStore: dataStore, yirDataController: yirDataController)
        let tabsButtonConfig = self.tabsButtonConfig(target: self, action: #selector(userDidTapTabs), dataStore: dataStore)

        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: nil, profileButtonConfig: profileButtonConfig, tabsButtonConfig: tabsButtonConfig, searchBarConfig: nil, hideNavigationBarOnScroll: false)

        let logoBarButtonItem = UIBarButtonItem(image: UIImage(named: "W"), style: .plain, target: nil, action: nil)
        logoBarButtonItem.accessibilityLabel = CommonStrings.plainWikipediaName
        navigationItem.leftBarButtonItem = logoBarButtonItem
        if #unavailable(iOS 26.0) {
            logoBarButtonItem.tintColor = theme.colors.logoTintColor
        }
    }

    @objc func userDidTapTabs() {
        tabsCoordinator?.start()
        ArticleTabsFunnel.shared.logIconClick(interface: .feed, project: nil)
    }

    @objc func userDidTapProfile() {
        guard let languageCode = dataStore.languageLinkController.appLanguage?.languageCode,
              DonateCoordinator.metricsID(for: .exploreProfile, languageCode: languageCode) != nil else {
            return
        }
        profileCoordinator?.start()
    }

    func updateProfileButton() {
        let config = self.profileButtonConfig(target: self, action: #selector(userDidTapProfile), dataStore: dataStore, yirDataController: yirDataController)
        updateNavigationBarProfileButton(needsBadge: config.needsBadge, needsBadgeLabel: CommonStrings.profileButtonBadgeTitle, noBadgeLabel: CommonStrings.profileButtonTitle)
    }

    // MARK: - Themeable

    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else { return }
        updateProfileButton()
        profileCoordinator?.theme = theme
        if #unavailable(iOS 26.0) {
            navigationItem.leftBarButtonItem?.tintColor = theme.colors.logoTintColor
        }
    }
}

extension HomeViewController: LogoutCoordinatorDelegate {
    func didTapLogout(authInstrument: InstrumentImpl) {
        wmf_showKeepSavedArticlesOnDevicePanelIfNeeded(triggeredBy: .logout, theme: theme, authInstrument: authInstrument) {
            self.dataStore.authenticationManager.logout(initiatedBy: .user, authInstrument: authInstrument)
        }
    }
}

extension HomeViewController: YearInReviewBadgeDelegate {
    func updateYIRBadgeVisibility() {
        updateProfileButton()
    }
}

extension HomeViewController: WMFPreferredLanguagesViewControllerDelegate {
    func languagesController(_ controller: WMFPreferredLanguagesViewController, didUpdatePreferredLanguages languages: [MWKLanguageLink]) {
        reloadLanguages()
    }
}
