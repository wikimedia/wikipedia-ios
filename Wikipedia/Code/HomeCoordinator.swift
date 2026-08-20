import UIKit
import WMF
import WMFComponents
import WMFData
import WMFNativeLocalizations
import WMFTestKitchen

@MainActor
final class HomeCoordinator: NSObject, Coordinator {

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
        let viewModel = WMFHomeViewModel(
            logDidTapLanguagePicker: { languageCode in
                var actionContext: [String: String]? = nil
                if let languageCode {
                    actionContext = ["lang_code": languageCode]
                }
                // Note: purposefully not leaning on homeFeedInstrument property here, as the deck doesn't specify that.
                TestKitchenAdapter.shared.client.getInstrument(name: "apps-home-feed").submitInteraction(action: "click", actionSource: "language_menu", elementId: "language_change", actionContext: actionContext)
            }
        )
        
        viewModel.logCardImpression = { [weak self] module, cardIndex in
            
            guard let self else { return }
            
            self.homeFeedInstrument?.submitInteraction(action: "impression", actionSource: module, actionContext: ["index": cardIndex], mediawikiDatabase: self.mediawikiDatabase(forViewModel: viewModel))
            
        }
        
        viewModel.logCardDidTapShare = { [weak self] module, elementId in
            
            guard let self else { return }
            
            self.homeFeedInstrument?.submitInteraction(action: "click", actionSource: module, elementId: elementId, mediawikiDatabase: self.mediawikiDatabase(forViewModel: viewModel))
            
        }
        
        viewModel.logCardDidToggleSave = { [weak self] module, elementId in
            
            guard let self else { return }
            
            self.homeFeedInstrument?.submitInteraction(action: "click", actionSource: module, elementId: elementId, mediawikiDatabase: self.mediawikiDatabase(forViewModel: viewModel))
            
        }
        
        viewModel.logCardDidTapHideCard = { [weak self] module, elementId in
            
            guard let self else { return }
            
            self.homeFeedInstrument?.submitInteraction(action: "click", actionSource: module, elementId: elementId, mediawikiDatabase: self.mediawikiDatabase(forViewModel: viewModel))
            
        }
        
        viewModel.logCardDidTapHideModule = { [weak self] module, elementId in
            
            guard let self else { return }
            
            self.homeFeedInstrument?.submitInteraction(action: "click", actionSource: module, elementId: elementId, mediawikiDatabase: self.mediawikiDatabase(forViewModel: viewModel))
            
        }
        
        viewModel.logCardDidTapCustomizeInterests = { [weak self] module, elementId in
            
            guard let self else { return }
            
            self.homeFeedInstrument?.submitInteraction(action: "click", actionSource: module, elementId: elementId, mediawikiDatabase: self.mediawikiDatabase(forViewModel: viewModel))
            
        }

        let vc = HomeViewController(dataStore: dataStore, theme: theme, viewModel: viewModel, homeCoordinator: self)
        vc.title = CommonStrings.homeTabTitle
        vc.tabBarItem.image = WMFSFSymbolIcon.for(symbol: .house)
        vc.tabBarItem.accessibilityIdentifier = AccessibilityIdentifiers.RootTab.homeButton
        vc.apply(theme: theme)

        homeViewController = vc
        return vc
    }
    
    private func mediawikiDatabase(forViewModel: WMFHomeViewModel) -> String {
        let language = forViewModel.selectedLanguage
        return WikimediaProject(wmfProject: WMFProject.wikipedia(language ?? WMFLanguage(languageCode: "en", languageVariantCode: nil))).notificationsApiWikiIdentifier
    }
    
    func startFunnelIfNeeded() {
        
        guard homeFeedInstrument == nil else { return }
        
        self.homeFeedInstrument = TestKitchenAdapter.shared.client.getInstrument(name: "apps-home-feed").startFunnel(name: "home_feed")
    }
    
    func stopFunnelIfNeeded() {
        homeFeedInstrument?.stopFunnel()
        homeFeedInstrument = nil
    }
}
