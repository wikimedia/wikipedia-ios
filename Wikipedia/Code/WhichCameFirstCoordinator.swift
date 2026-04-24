import UIKit
import WMF
import WMFComponents
import WMFNativeLocalizations

/// Coordinator that presents the Which Came First game, starting with the splash screen.
@MainActor
final class WhichCameFirstCoordinator: NSObject, Coordinator {

    // MARK: - Properties

    var navigationController: UINavigationController
    private let theme: Theme

    // MARK: - Initialization

    init(navigationController: UINavigationController, theme: Theme) {
        self.navigationController = navigationController
        self.theme = theme
    }

    // MARK: - Coordinator

    @discardableResult
    func start() -> Bool {
        let splashViewController = makeSplashViewController()
        let nav = WMFComponentNavigationController(
            rootViewController: splashViewController,
            modalPresentationStyle: .pageSheet
        )
        navigationController.present(nav, animated: true)
        return true
    }

    // MARK: - Factory

    private func makeSplashViewController() -> WMFGamesSplashScreenViewController {
        let localizedStrings = WMFGamesSplashScreenViewModel.LocalizedStrings(
            title: WMFLocalizedString(
                "which-came-first-splash-title",
                value: "Which came first?",
                comment: "Title shown on the Which Came First game splash screen."
            ),
            subtitle: WMFLocalizedString(
                "which-came-first-splash-subtitle",
                value: "Guess which event came first on this day in history.",
                comment: "Subtitle shown on the Which Came First game splash screen."
            ),
            playButtonTitle: WMFLocalizedString(
                "which-came-first-splash-play-button",
                value: "Play today's game",
                comment: "Button title to start the Which Came First game."
            ),
            aboutButtonTitle: WMFLocalizedString(
                "which-came-first-splash-about-button",
                value: "About this game",
                comment: "Button title to learn more about the Which Came First game."
            )
        )

        let dateString = formattedTodayDateString()

        let viewModel = WMFGamesSplashScreenViewModel(
            localizedStrings: localizedStrings,
            icon: WMFSFSymbolIcon.for(symbol: .calendar),
            dateString: dateString,
            backgroundColor: WMFColor.blue600,
            didTapPlay: { [weak self] in
                self?.showGame()
            },
            didTapAbout: { [weak self] in
                self?.showAbout()
            },
            didTapClose: { [weak self] in
                self?.navigationController.dismiss(animated: true)
            },
            didTapMore: { [weak self] in
                self?.showMoreOptions()
            }
        )

        return WMFGamesSplashScreenViewController(viewModel: viewModel)
    }

    // MARK: - Navigation

    private func showGame() {
        // TODO: Push the Which Came First game view controller.
    }

    private func showAbout() {
        // TODO: Present the about / info sheet for the game.
    }

    private func showMoreOptions() {
        // TODO: Present an action sheet with additional game options.
    }

    // MARK: - Helpers

    private func formattedTodayDateString() -> String { // add a date formatter to allow for international dates, not only US
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: Date())
    }
}

