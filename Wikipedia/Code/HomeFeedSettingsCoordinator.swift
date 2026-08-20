import UIKit
import WMF
import WMFComponents
import WMFData
import WMFTestKitchen

@MainActor
final class HomeFeedSettingsCoordinator: Coordinator {

    /// The screen the coordinator opens on when started.
    enum InitialView {
        /// The root "Customize the home feed" screen.
        case root
        /// Deep-links straight to "What's driving your feed" (e.g. from a button in the feed).
        case modalFromFeed
        /// Direct to interests. Pass along instrument to keep a particular funnel tracking.
        case interests(InstrumentImpl?)
    }

    enum Presentation {
        /// Push onto the provided navigation controller.
        case push
        /// Wrap the initial screen in a navigation controller and present it modally.
        case modal
    }

    // MARK: Coordinator Protocol Properties

    internal var navigationController: UINavigationController

    // MARK: Properties

    private let theme: Theme
    private var currentTheme: Theme {
        return UserDefaults.standard.theme(compatibleWith: UITraitCollection.current)
    }

    private let homeDataController: WMFHomeDataController
    private let initialView: InitialView
    private let presentation: Presentation

    /// The navigation controller that sub-screens are pushed onto. For `.push` this is the provided
    /// `navigationController`; for `.modal` it becomes the modally-presented navigation controller.
    private var activeNavigationController: UINavigationController

    // MARK: Lifecycle

    init(navigationController: UINavigationController, theme: Theme, initialView: InitialView = .root, presentation: Presentation = .push, homeDataController: WMFHomeDataController = .shared) {
        self.navigationController = navigationController
        self.theme = theme
        self.initialView = initialView
        self.presentation = presentation
        self.homeDataController = homeDataController
        self.activeNavigationController = navigationController
    }

    @discardableResult
    func start() -> Bool {
        let initialViewController: UIViewController
        switch initialView {
        case .root:
            initialViewController = makeRootViewController()
        case .modalFromFeed:
            let closeButtonHandler: (() -> Void)? = presentation == .modal ? { [weak self] in self?.dismissModal() } : nil
            initialViewController = makeWhatsDrivingViewController(closeButtonHandler: closeButtonHandler)
        case .interests(let instrument):
            let closeButtonHandler: (() -> Void)? = presentation == .modal ? { [weak self] in self?.dismissModal() } : nil
            initialViewController = makeInterestsViewController(instrument: instrument, closeButtonHandler: closeButtonHandler)
        }

        switch presentation {
        case .push:
            navigationController.pushViewController(initialViewController, animated: true)
        case .modal:
            let modalNav = WMFComponentNavigationController(rootViewController: initialViewController, modalPresentationStyle: .pageSheet)
            modalNav.isModalInPresentation = true
            activeNavigationController = modalNav
            navigationController.present(modalNav, animated: true)
        }
        return true
    }
    
    private func makeInterestsViewController(instrument: InstrumentImpl?, closeButtonHandler: (() -> Void)? = nil) -> WMFHomeFeedInterestsSettingsViewController {
        let language = homeDataController.selectedLanguage() ?? WMFDataEnvironment.current.primaryAppLanguage ?? WMFLanguage(languageCode: "en", languageVariantCode: nil)
        let project = WMFProject.wikipedia(language)
        let searchLanguages = MWKDataStore.shared().languageLinkController.preferredLanguages.map {
            WMFLanguage(languageCode: $0.languageCode, languageVariantCode: $0.languageVariantCode)
        }
        let resolvedInstrument = instrument ?? TestKitchenAdapter.shared.client.getInstrument(name: "apps-home-feed").startFunnel(name: "feed_customize")
        let viewModel = WMFHomeFeedInterestsSettingsViewModel(
            project: project,
            searchLanguages: searchLanguages,
            logImpressionIfNeeded: {
                resolvedInstrument.submitInteraction(action: "impression", actionSource: "feed_customize")
            },
            logDidTapTopic: {
                resolvedInstrument.submitInteraction(action: "click", actionSource: "feed_customize", elementId: "topic_select")
            },
            logDidTapArticle: {
                resolvedInstrument.submitInteraction(action: "click", actionSource: "feed_customize", elementId: "article_select")
            },
            logDidTapDeselectAll: {
                resolvedInstrument.submitInteraction(action: "click", actionSource: "feed_customize", elementId: "deselect_all")
            }
        )
        return WMFHomeFeedInterestsSettingsViewController(viewModel: viewModel, closeButtonHandler: closeButtonHandler)
    }

    // MARK: - View controller factories

    private func makeRootViewController() -> WMFHomeFeedSettingsViewController {
        return WMFHomeFeedSettingsViewController(didTapCommunityModules: { [weak self] in
            self?.showCommunityModulesSettings()
        }, didTapForYouModules: { [weak self] in
            self?.showForYouModulesSettings()
        }, didTapForYouWhatsDriving: { [weak self] in
            self?.showWhatsDrivingSettings()
        })
    }

    private func makeWhatsDrivingViewController(closeButtonHandler: (() -> Void)? = nil) -> WMFHomeFeedWhatsDrivingSettingsViewController {
        let viewModel = WMFHomeFeedWhatsDrivingSettingsViewModel(didTapYourInterests: { [weak self] in
            self?.showInterestsSettings()
        }, didTapReadingHistory: { [weak self] in
            self?.switchToSearchTab()
        }, didTapLanguages: { [weak self] in
            self?.showLanguages()
        })
        return WMFHomeFeedWhatsDrivingSettingsViewController(viewModel: viewModel, closeButtonHandler: closeButtonHandler)
    }

    // MARK: - Sub-flows

    private func showCommunityModulesSettings() {
        let viewModel = WMFHomeFeedCommunitySettingsViewModel()
        let modulesSettingsVC = WMFHomeFeedCommunitySettingsViewController(viewModel: viewModel)
        activeNavigationController.pushViewController(modulesSettingsVC, animated: true)
    }

    private func showForYouModulesSettings() {
        let instrument = TestKitchenAdapter.shared.client.getInstrument(name: "apps-home-feed")
        instrument.submitInteraction(action: "click", actionSource: "settings", elementId: "feed_modules_for_you")
        
        let viewModel = WMFHomeFeedForYouSettingsViewModel(
            logToggleModule: { module, isOn in
                let action = isOn ? "enable" : "disable"
                let elementId: String
                switch module {
                case .basedOnYourInterests: elementId = "INTERESTS"
                case .becauseYouRead: elementId = "BECAUSE_READ"
                case .continueReading: elementId = "CONTINUE"
                }
                instrument.submitInteraction(action: action, actionSource: "settings", actionSubtype: "feed_for_you", elementId: elementId)
            }
        )
        let forYouSettingsVC = WMFHomeFeedForYouSettingsViewController(viewModel: viewModel)
        activeNavigationController.pushViewController(forYouSettingsVC, animated: true)
    }

    private func showWhatsDrivingSettings() {
        TestKitchenAdapter.shared.client.getInstrument(name: "apps-home-feed").submitInteraction(action: "click", actionSource: "settings", elementId: "feed_data_info")
        activeNavigationController.pushViewController(makeWhatsDrivingViewController(), animated: true)
    }

    private func showInterestsSettings() {
        
        TestKitchenAdapter.shared.client.getInstrument(name: "apps-home-feed").submitInteraction(action: "click", actionSource: "settings", elementId: "customize_feed")
        
        let language = homeDataController.selectedLanguage() ?? WMFDataEnvironment.current.primaryAppLanguage ?? WMFLanguage(languageCode: "en", languageVariantCode: nil)
        let project = WMFProject.wikipedia(language)
        let searchLanguages = MWKDataStore.shared().languageLinkController.preferredLanguages.map {
            WMFLanguage(languageCode: $0.languageCode, languageVariantCode: $0.languageVariantCode)
        }
        let instrument = TestKitchenAdapter.shared.client.getInstrument(name: "apps-home-feed").startFunnel(name: "feed_customize")
        let viewModel = WMFHomeFeedInterestsSettingsViewModel(
            project: project,
            searchLanguages: searchLanguages,
            logImpressionIfNeeded: {
                instrument.submitInteraction(action: "impression", actionSource: "feed_customize")
            },
            logDidTapTopic: {
                instrument.submitInteraction(action: "click", actionSource: "feed_customize", elementId: "topic_select")
            },
            logDidTapArticle: {
                instrument.submitInteraction(action: "click", actionSource: "feed_customize", elementId: "article_select")
            },
            logDidTapDeselectAll: {
                instrument.submitInteraction(action: "click", actionSource: "feed_customize", elementId: "deselect_all")
            }
        
        )
        let interestsVC = WMFHomeFeedInterestsSettingsViewController(viewModel: viewModel)
        activeNavigationController.pushViewController(interestsVC, animated: true)
    }

    private func switchToSearchTab() {
        // `AppDelegate` is compiled out of test builds (replaced by `MockAppDelegate`), so any reference to it must be guarded in test builds
        TestKitchenAdapter.shared.client.getInstrument(name: "apps-home-feed").submitInteraction(action: "click", actionSource: "settings", elementId: "reading_history")
#if !TEST
        guard let appViewController = (UIApplication.shared.delegate as? AppDelegate)?.appViewController else {
            return
        }
        appViewController.switchToSearchTab(focusSearchBar: false, animated: true)
#endif
    }

    private func showLanguages() {
        TestKitchenAdapter.shared.client.getInstrument(name: "apps-home-feed").submitInteraction(action: "click", actionSource: "settings", elementId: "languages")
        let languagesVC = WMFPreferredLanguagesViewController.preferredLanguagesViewController()
        languagesVC.showExploreFeedCustomizationSettings = true
        languagesVC.apply(currentTheme)
        let languagesNavVC = WMFComponentNavigationController(rootViewController: languagesVC, modalPresentationStyle: .overFullScreen)
        activeNavigationController.present(languagesNavVC, animated: true)
    }

    private func dismissModal() {
        navigationController.dismiss(animated: true)
    }
}
