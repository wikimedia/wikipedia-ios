import UIKit
import WMF
import WMFComponents
import WMFData

@MainActor
final class HomeFeedSettingsCoordinator: Coordinator {

    /// The screen the coordinator opens on when started.
    enum InitialView {
        /// The root "Customize the home feed" screen.
        case root
        /// Deep-links straight to "What's driving your feed" (e.g. from a button in the feed).
        case modalFromFeed
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
        let viewModel = WMFHomeFeedForYouSettingsViewModel()
        let forYouSettingsVC = WMFHomeFeedForYouSettingsViewController(viewModel: viewModel)
        activeNavigationController.pushViewController(forYouSettingsVC, animated: true)
    }

    private func showWhatsDrivingSettings() {
        activeNavigationController.pushViewController(makeWhatsDrivingViewController(), animated: true)
    }

    private func showInterestsSettings() {
        let language = homeDataController.selectedLanguage() ?? WMFDataEnvironment.current.primaryAppLanguage ?? WMFLanguage(languageCode: "en", languageVariantCode: nil)
        let project = WMFProject.wikipedia(language)
        let searchLanguages = MWKDataStore.shared().languageLinkController.preferredLanguages.map {
            WMFLanguage(languageCode: $0.languageCode, languageVariantCode: $0.languageVariantCode)
        }
        let viewModel = WMFHomeFeedInterestsSettingsViewModel(project: project, searchLanguages: searchLanguages)
        let interestsVC = WMFHomeFeedInterestsSettingsViewController(viewModel: viewModel)
        activeNavigationController.pushViewController(interestsVC, animated: true)
    }

    private func switchToSearchTab() {
        // `AppDelegate` is compiled out of test builds (replaced by `MockAppDelegate`), so any reference to it must be guarded in test builds
#if !TEST
        guard let appViewController = (UIApplication.shared.delegate as? AppDelegate)?.appViewController else {
            return
        }
        appViewController.switchToSearchTab(focusSearchBar: false, animated: true)
#endif
    }

    private func showLanguages() {
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
