import UIKit
import WMF
import WMFComponents
import WMFData

/// Coordinator that presents the Which Came First game, starting with the splash screen.
@MainActor
final class WhichCameFirstCoordinator: NSObject, Coordinator {

    // MARK: - Properties

    var navigationController: UINavigationController
    private let theme: Theme
    private let gamesDataController = WMFGamesDataController()

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
        let viewModel = WMFGamesSplashScreenViewModel(
            icon: WMFSFSymbolIcon.for(symbol: .calendar),
            dateString: formattedTodayDateString(),
            didTapPlay: { [weak self] in
                self?.showGame()
            },
            didTapAbout: { [weak self] in
                self?.showAbout()
            },
            didTapClose: nil,
            didTapMore: { [weak self] in
                self?.showMoreOptions()
            }
        )

        updatePlayButtonTitleIfNeeded(viewModel: viewModel)

        return WMFGamesSplashScreenViewController(viewModel: viewModel)
    }

    /// Fetches today's session and delegates play button title updates to the view model.
    private func updatePlayButtonTitleIfNeeded(viewModel: WMFGamesSplashScreenViewModel) {
        guard let language = WMFDataEnvironment.current.primaryAppLanguage else { return }
        let project = WMFProject.wikipedia(language)
        let todayDateString = formattedTodayISODateString()

        Task { [weak self, weak viewModel] in
            guard let self, let viewModel else { return }
            guard let session = try? await self.gamesDataController.fetchWhichCameFirstDailySession(date: todayDateString, project: project) else { return }
            viewModel.update(sessionStatus: session.status)
        }
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

    /// Returns today's date as a "YYYY-MM-DD" string for matching game session records.
    private func formattedTodayISODateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: Date())
    }
}

