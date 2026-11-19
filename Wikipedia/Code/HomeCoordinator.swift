import UIKit
import WMF
import WMFComponents
import WMFData
import WMFNativeLocalizations
import WMFTestKitchen

@MainActor
final class HomeCoordinator: NSObject, TabRootCoordinator {

    let tab: WMFAppTabType = .main

    // The Home tab's navigation controller. Injected via `attach(navigationController:)` once the
    // Home view controller has been wrapped in its tab navigation controller.
    private var tabNavigationController: UINavigationController?
    var navigationController: UINavigationController {
        guard let tabNavigationController else {
            fatalError("HomeCoordinator.navigationController accessed before attach(navigationController:)")
        }
        return tabNavigationController
    }

    var theme: Theme
    let dataStore: MWKDataStore

    private(set) weak var homeViewController: HomeViewController?
    
    private var homeFeedInstrument: InstrumentImpl?

    init(theme: Theme, dataStore: MWKDataStore) {
        self.theme = theme
        self.dataStore = dataStore
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(handleEnableHomePhase2DidChange), name: WMFNSNotification.enableHomePhase2DidChange, object: nil)
    }

    /// Rebuilds the Home tab when the phase 2 flag is toggled so the Community segment swaps between
    /// the embedded legacy Explore feed and the new community feed without an app relaunch.
    @objc private func handleEnableHomePhase2DidChange() {
        guard tabNavigationController != nil else { return }
        start()
    }

    var rootViewController: UIViewController {
        homeViewController ?? makeHomeViewController()
    }

    func apply(theme: Theme) {
        self.theme = theme
    }

    func tabWasReselected() {
        homeViewController?.scrollSelectedFeedToTop()
    }

    func attach(navigationController: UINavigationController) {
        self.tabNavigationController = navigationController
    }

    @discardableResult
    func start() -> Bool {
        let vc = makeHomeViewController()
        navigationController.setViewControllers([vc], animated: false)
        return true
    }

    func makeHomeViewController() -> HomeViewController {
        let viewModel = WMFHomeViewModel()
        
        viewModel.logDidTapLanguagePicker = { [weak self, weak viewModel] languageCode in
            guard let self, let viewModel else { return }
            var actionContext: [String: String]? = nil
            if let languageCode {
                actionContext = ["lang_code": languageCode]
            }
            // Note: purposefully not leaning on homeFeedInstrument property here, as the deck doesn't specify that.
            TestKitchenAdapter.shared.client.getInstrument(name: "apps-home-feed").submitInteraction(action: "click", actionSource: "language_menu", elementId: "language_change", actionContext: actionContext, mediawikiDatabase: self.mediawikiDatabase(for: viewModel))
        }
        
        viewModel.logCardImpression = { [weak self, weak viewModel] module, cardIndex in
            guard let self, let viewModel else { return }
            self.homeFeedInstrument?.submitInteraction(action: "impression", actionSource: module, actionContext: ["index": cardIndex], mediawikiDatabase: self.mediawikiDatabase(for: viewModel))
        }

        viewModel.logCardDidTapShare = { [weak self, weak viewModel] module in
            guard let self, let viewModel else { return }
            self.homeFeedInstrument?.submitInteraction(action: "click", actionSource: module, actionSubtype: "feed_overflow", elementId: "article_share", mediawikiDatabase: self.mediawikiDatabase(for: viewModel))
        }

        viewModel.logCardDidSave = { [weak self, weak viewModel] card in
            guard let self, let viewModel else { return }
            self.homeFeedInstrument?.submitInteraction(action: "click", actionSource: card.module.loggingId, actionSubtype: "feed_overflow", elementId: "article_save", mediawikiDatabase: self.mediawikiDatabase(for: viewModel))
            let articleURL = card.project.siteURL?.wmf_URL(withTitle: card.title)
            ReadingListsFunnel.shared.logSave(category: .article, label: nil, articleURL: articleURL)
        }

        viewModel.logCardDidUnsave = { [weak self, weak viewModel] card in
            guard let self, let viewModel else { return }
            self.homeFeedInstrument?.submitInteraction(action: "click", actionSource: card.module.loggingId, actionSubtype: "feed_overflow", elementId: "article_unsave", mediawikiDatabase: self.mediawikiDatabase(for: viewModel))
            let articleURL = card.project.siteURL?.wmf_URL(withTitle: card.title)
            ReadingListsFunnel.shared.logUnsave(category: .article, label: nil, articleURL: articleURL)
        }

        viewModel.logCardDidTapHideCard = { [weak self, weak viewModel] module in
            guard let self, let viewModel else { return }
            self.homeFeedInstrument?.submitInteraction(action: "click", actionSource: module, actionSubtype: "feed_overflow", elementId: "card_hide", mediawikiDatabase: self.mediawikiDatabase(for: viewModel))
        }

        viewModel.logCardDidTapHideModule = { [weak self, weak viewModel] module in
            guard let self, let viewModel else { return }
            self.homeFeedInstrument?.submitInteraction(action: "click", actionSource: module, actionSubtype: "feed_overflow", elementId: "module_hide", mediawikiDatabase: self.mediawikiDatabase(for: viewModel))
        }

        viewModel.logDidTapCustomizeInterests = { [weak self, weak viewModel] module, elementId in
            guard let self, let viewModel else { return }
            self.homeFeedInstrument?.submitInteraction(action: "click", actionSource: module, actionSubtype: "feed_overflow", elementId: elementId, mediawikiDatabase: self.mediawikiDatabase(for: viewModel))
        }

        viewModel.logEmptyViewImpression = { [weak self, weak viewModel] in
            guard let self, let viewModel else { return }
            self.homeFeedInstrument?.submitInteraction(action: "impression", actionSource: "EmptyForYouCard", mediawikiDatabase: self.mediawikiDatabase(for: viewModel))
        }

        viewModel.logCardDidTapArticle = { [weak self, weak viewModel] module, articleTitle in
            guard let self, let viewModel else { return }
            let project = self.currentProject(forViewModel: viewModel)
            let pageData = TestKitchenAdapter.getPageData(title: articleTitle, project: project)
            self.homeFeedInstrument?.submitInteraction(action: "click", actionSource: module, elementId: "article_open", mediawikiDatabase: self.mediawikiDatabase(for: viewModel), pageData: pageData)
        }
        
        viewModel.logEndOfFeedImpression = { [weak self, weak viewModel] in
            guard let self, let viewModel else { return }
            // Per the data team, this impression ends the home_feed funnel: any event after it
            // must not carry the funnel. Submit first so this event keeps time_spent_ms, then stop.
            self.homeFeedInstrument?.submitInteraction(action: "impression", actionSource: WMFForYouEndOfFeedCardViewModel.loggingId, mediawikiDatabase: self.mediawikiDatabase(for: viewModel))
            self.homeFeedInstrument?.stopFunnel()
        }

        viewModel.logEndOfFeedDidTapCommunity = { [weak self, weak viewModel] in
            guard let self, let viewModel else { return }
            self.homeFeedInstrument?.submitInteraction(action: "click", actionSource: WMFForYouEndOfFeedCardViewModel.loggingId, elementId: "community_feed", mediawikiDatabase: self.mediawikiDatabase(for: viewModel))
        }

        let vc = HomeViewController(dataStore: dataStore, theme: theme, viewModel: viewModel, homeCoordinator: self)
        vc.title = CommonStrings.homeTabTitle
        vc.tabBarItem.image = WMFSFSymbolIcon.for(symbol: .house)
        vc.tabBarItem.accessibilityIdentifier = AccessibilityIdentifiers.RootTab.homeButton
        vc.apply(theme: theme)

        homeViewController = vc
        return vc
    }
    
    private func currentProject(forViewModel: WMFHomeViewModel) -> WMFProject {
        let language = forViewModel.selectedLanguage
        return WMFProject.wikipedia(language ?? WMFDataEnvironment.current.primaryAppLanguage ?? WMFLanguage(languageCode: "en", languageVariantCode: nil))
    }
    
    private func mediawikiDatabase(for viewModel: WMFHomeViewModel) -> String {
        return WikimediaProject(wmfProject: currentProject(forViewModel: viewModel)).notificationsApiWikiIdentifier
    }
    
    func startFunnelIfNeeded() {
        
        guard homeFeedInstrument == nil else { return }
        
        self.homeFeedInstrument = TestKitchenAdapter.shared.client.getInstrument(name: "apps-home-feed").startFunnel(name: "home_feed")
    }
    
    func stopFunnelIfNeeded() {
        homeFeedInstrument?.stopFunnel()
        homeFeedInstrument = nil
    }

    // MARK: - One-time Home onboarding

    /// Set by `WMFAppViewController`, because the customization flow loads the main UI when it closes.
    var startFeedCustomization: ((InstrumentImpl) -> Void)?
    private var oneTimeOnboardingViewController: WMFOnboardingViewController?

    func presentOneTimeOnboardingIfNeeded(isExistingUser: Bool) {
        guard let tabBarController = tabNavigationController?.tabBarController,
              tabBarController.selectedIndex == tab.rawValue,
              navigationController.viewControllers.count == 1,
              tabBarController.presentedViewController == nil else { return }

        // Show the sheet only to a reader who saw the old onboarding, did not see the Home onboarding, and did not see this sheet.
        let hasSeenHomeOnboarding = WMFHomeDataController.shared.hasSeenUpdatedHomeOnboarding()
        let hasSeenOneTimeOnboarding = WMFHomeDataController.shared.hasSeenOneTimeOnboarding()

        guard isExistingUser && !hasSeenOneTimeOnboarding && !hasSeenHomeOnboarding else { return }

        let viewModel = WMFOnboardingViewModel(
            title: WMFLocalizedString(
                "one-time-onboarding-title",
                value: "Explore is now Home, with a new look",
                comment: "Title of the one-time onboarding sheet shown to existing users after the Explore tab is renamed to Home."
            ),
            cells: [
                WMFOnboardingViewModel.WMFOnboardingCellViewModel(
                    icon: WMFSFSymbolIcon.for(symbol: .house),
                    title: WMFLocalizedString(
                        "one-time-onboarding-feature-name-title",
                        value: "A new name",
                        comment: "Title of the 'A new name' feature item on the one-time onboarding sheet."
                    ),
                    subtitle: WMFLocalizedString(
                        "one-time-onboarding-feature-name-body",
                        value: "The Explore feed is now Home, in the same spot as before.",
                        comment: "Description of the 'A new name' feature item on the one-time onboarding sheet."
                    ),
                    tintBlue: true
                ),
                WMFOnboardingViewModel.WMFOnboardingCellViewModel(
                    icon: WMFSFSymbolIcon.for(symbol: .squareSplit),
                    title: WMFLocalizedString(
                        "one-time-onboarding-feature-feed-title",
                        value: "Your feed, two ways",
                        comment: "Title of the 'Your feed, two ways' feature item on the one-time onboarding sheet."
                    ),
                    subtitle: WMFLocalizedString(
                        "one-time-onboarding-feature-feed-body",
                        value: "Discover articles personalized to your interests in For You, or browse Wikipedia's best editorial content in Community.",
                        comment: "Description of the 'Your feed, two ways' feature item on the one-time onboarding sheet."
                    ),
                    tintBlue: true
                ),
                WMFOnboardingViewModel.WMFOnboardingCellViewModel(
                    icon: WMFSFSymbolIcon.for(symbol: .sliderHorizontal3),
                    title: WMFLocalizedString(
                        "one-time-onboarding-feature-control-title",
                        value: "Stay in control",
                        comment: "Title of the 'Stay in control' feature item on the one-time onboarding sheet."
                    ),
                    subtitle: WMFLocalizedString(
                        "one-time-onboarding-feature-control-body",
                        value: "Every recommendation tells you exactly why it's there. You can update your preferences anytime in Settings.",
                        comment: "Description of the 'Stay in control' feature item on the one-time onboarding sheet."
                    ),
                    tintBlue: true
                ),
                WMFOnboardingViewModel.WMFOnboardingCellViewModel(
                    icon: WMFSFSymbolIcon.for(symbol: .globeAmericas),
                    title: WMFLocalizedString(
                        "one-time-onboarding-feature-languages-title",
                        value: "Every language, fully personalized",
                        comment: "Title of the 'Every language, fully personalized' feature item on the one-time onboarding sheet."
                    ),
                    subtitle: WMFLocalizedString(
                        "one-time-onboarding-feature-languages-body",
                        value: "Reading in multiple languages? Each one gets its own experience. Just switch and your new feed is ready.",
                        comment: "Description of the 'Every language, fully personalized' feature item on the one-time onboarding sheet."
                    ),
                    tintBlue: true
                )
            ],
            primaryButtonTitle: WMFLocalizedString(
                "one-time-onboarding-customize-button",
                value: "Customize my feed",
                comment: "Primary button on the one-time onboarding sheet that opens the feed customization flow."
            ),
            secondaryButtonTitle: WMFLocalizedString(
                "one-time-onboarding-auto-setup-button",
                value: "Set it up for me",
                comment: "Secondary button on the one-time onboarding sheet that automatically configures the feed without customization."
            )
        )

        let onboardingVC = WMFOnboardingViewController(viewModel: viewModel)
        onboardingVC.modalPresentationStyle = .pageSheet
        onboardingVC.delegate = self
        oneTimeOnboardingViewController = onboardingVC

        DispatchQueue.main.async {
            tabBarController.present(onboardingVC, animated: true) {
                TestKitchenAdapter.shared.client.getInstrument(name: "apps-home-feed").submitInteraction(action: "impression", actionSource: "feed_announce")
                WMFHomeDataController.shared.setHasSeenOneTimeOnboarding(true)
            }
        }
    }

    func selectFeedChosenInOnboarding() {
        homeViewController?.viewModel.selectedTab = WMFHomeDataController.shared.seeFirstContent() == .personalized ? .forYou : .community
    }
}

// MARK: - WMFOnboardingViewDelegate (one-time Home onboarding)

extension HomeCoordinator: WMFOnboardingViewDelegate {

    func onboardingViewDidClickPrimaryButton() {
        
        let instrument = TestKitchenAdapter.shared.client.getInstrument(name: "apps-home-feed").startFunnel(name: "feed_customize")
        instrument.submitInteraction(action: "click", actionSource: "feed_announce", elementId: "customize_feed")
        
        oneTimeOnboardingViewController?.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            self.oneTimeOnboardingViewController = nil
            self.startFeedCustomization?(instrument)
        }
    }

    func onboardingViewDidClickSecondaryButton() {
        TestKitchenAdapter.shared.client.getInstrument(name: "apps-home-feed").submitInteraction(action: "click", actionSource: "feed_announce", elementId: "accept_default")
        
        WMFHomeDataController.shared.setSeeFirstContent(.community)
        if let homeViewModel = homeViewController?.viewModel {
            homeViewModel.selectedTab = .community
            homeViewModel.loadForYouFeedIfNeeded()
        }
        oneTimeOnboardingViewController?.dismiss(animated: true) { [weak self] in
            self?.oneTimeOnboardingViewController = nil
        }
    }
}
