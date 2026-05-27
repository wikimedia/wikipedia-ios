import UIKit
import SwiftUI
import WMF
import WMFComponents
import WMFData
import WMFNativeLocalizations

/// Coordinator that presents the Which Came First game, starting with the splash screen.
@MainActor
final class WhichCameFirstCoordinator: NSObject, Coordinator {

    // MARK: - Properties

    var navigationController: UINavigationController
    private let theme: Theme
    private let gamesDataController = WMFGamesDataController()

    /// The modal navigation controller that hosts the splash screen and game screens.
    private weak var gameNavigationController: UINavigationController?
    
    private let dataStore: MWKDataStore

    init(navigationController: UINavigationController, theme: Theme, dataStore: MWKDataStore) {
        self.navigationController = navigationController
        self.theme = theme
        self.dataStore = dataStore
    }

    // MARK: - Coordinator

    @discardableResult
    func start() -> Bool {
        let splashViewController = makeSplashViewController()
        let nav = WMFComponentNavigationController(
            rootViewController: splashViewController,
            modalPresentationStyle: .fullScreen
        )
        gameNavigationController = nav
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
        guard let language = WMFDataEnvironment.current.primaryAppLanguage,
              let gameNav = gameNavigationController else { return }
        let project = WMFProject.wikipedia(language)
        let isLoggedIn = dataStore.authenticationManager.authStateIsPermanent
        let viewModel = WMFWhichCameFirstViewModel(date: formattedTodayISODateString(), project: project)
        viewModel.didTapShare = { [weak self, weak viewModel] in
            guard let self, let viewModel else { return }
            self.showShare(gameViewModel: viewModel)
        }
        viewModel.isLoggedIn = isLoggedIn
        viewModel.onLogIn = { [weak self] in
            self?.showLogin()
        }
        let gameVC = WMFWhichCameFirstHostingController(viewModel: viewModel)
        gameNav.setViewControllers([gameVC], animated: true)
    }

    private func showLogin() {
        guard let gameNav = gameNavigationController,
              let hostingVC = gameNav.viewControllers.first as? WMFWhichCameFirstHostingController else { return }
        let gameViewModel = hostingVC.viewModel
        
        let loginCoordinator = LoginCoordinator(navigationController: gameNav, theme: theme, loggingCategory: .activity)
        loginCoordinator.loginSuccessCompletion = { [weak self, weak gameViewModel, weak gameNav] in
            guard let self else { return }
            gameNav?.presentedViewController?.dismiss(animated: true)
            gameViewModel?.isLoggedIn = self.dataStore.authenticationManager.authStateIsPermanent
        }
        loginCoordinator.start()
    }

    private func showShare(gameViewModel: WMFWhichCameFirstViewModel) {
        guard let gameNav = gameNavigationController,
              let events = gameViewModel.makeShareArticleEvents(),
              let results = gameViewModel.makeShareQuestionResults() else { return }

        Task { [weak self, weak gameNav] in
            guard let self, let gameNav else { return }

            let summaryController = WMFArticleSummaryDataController.shared
            let imageController = WMFImageDataController.shared

            var articles: [WMFWhichCameFirstShareViewModel.ArticleItem] = []

            for (event, project) in events {
                guard let articleTitle = event.articleTitle else { continue }
                let cleanTitle = articleTitle.underscoresToSpaces

                // Fetch summary for description
                let summary = try? await summaryController.fetchArticleSummary(project: project, title: articleTitle)
                let description = summary?.description ?? summary?.extract

                // Fetch thumbnail image — prefer the event's known URL, fall back to summary's
                let thumbnailURL = event.thumbnailURL ?? summary?.thumbnailURL
                var image: UIImage?
                if let url = thumbnailURL,
                   let data = try? await imageController.fetchImageData(url: url) {
                    image = UIImage(data: data)
                }

                articles.append(.init(title: cleanTitle, description: description, image: image))
            }

            let shareViewModel = WMFWhichCameFirstShareViewModel(
                score: gameViewModel.score,
                totalQuestions: gameViewModel.totalQuestions,
                questionResults: results,
                articles: articles
            )

            let shareView = WMFWhichCameFirstShareView(viewModel: shareViewModel, theme: Theme.wmfTheme(from: self.theme))
            let renderer = ImageRenderer(content: shareView)
            renderer.scale = UIScreen.main.scale
            guard let image = renderer.uiImage else { return }

            let shareText = WMFLocalizedString("which-came-first-share-activity-text", value: "I'm playing \"Which came first?\" a daily trivia game on the Wikipedia iOS app https://apps.apple.com/app/apple-store/id324715238?pt=208305&ct=wiki_game_202605&mt=8", comment: "Text shared when a user shares the Which Came First game via Messages, Notes, or other text-based share targets.")
            let textProvider = WCFShareActivityContentProvider(
                text: shareText
            )
            let imageProvider = ShareAFactActivityImageItemProvider(image: image)
            let activityVC = UIActivityViewController(activityItems: [textProvider, imageProvider], applicationActivities: nil)
            activityVC.excludedActivityTypes = [.print, .assignToContact, .addToReadingList]

            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = gameNav.visibleViewController?.view
                popover.sourceRect = gameNav.visibleViewController?.view.bounds ?? .zero
                popover.permittedArrowDirections = []
            }

            gameNav.present(activityVC, animated: true)
        }
    }

    private func showAbout() {
        guard let gameNav = gameNavigationController,
              let url = URL(string: "https://www.mediawiki.org/wiki/Wikimedia_Apps/Team/iOS/Game:_Which_came_first") else { return }
        let config = SinglePageWebViewController.StandardConfig(url: url, useSimpleNavigationBar: true)
        let webVC = SinglePageWebViewController(configType: .standard(config), theme: theme)
        let webNav = WMFComponentNavigationController(rootViewController: webVC, modalPresentationStyle: .fullScreen)
        gameNav.present(webNav, animated: true)
    }

    private func showMoreOptions() {
        // TODO: Present an action sheet with additional game options.
    }

    // MARK: - Helpers

    /// Returns today's date formatted for display (e.g. "May 27" or "May 27, 240").
    ///
    /// `setLocalizedDateFormatFromTemplate` can zero-pad short years (e.g. "0240") on some
    /// locales. We strip leading zeros from the year so that year 240 displays as "240" while
    /// a four-digit year like 2010 is left untouched.
    private func formattedTodayDateString() -> String {
        let calendar = Calendar.current
        let date = Date()
        let year = calendar.component(.year, from: date)

        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMMd")
        var result = formatter.string(from: date)

        // Only attempt year fixup for years that could be zero-padded (fewer than 4 digits).
        if year > 0 && year < 1000 {
            let paddedYear = String(format: "%04d", year) // e.g. "0240"
            let naturalYear = String(year)                // e.g. "240"
            if paddedYear != naturalYear {
                result = result.replacingOccurrences(of: paddedYear, with: naturalYear)
            }
        }

        return result
    }

    /// Returns today's date as a "YYYY-MM-DD" string for matching game session records.
    private func formattedTodayISODateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: Date())
    }
}

// MARK: - Share Content Provider

// @unchecked Sendable: UIActivityItemProvider is a legacy UIKit class with no Sendable conformance,
// required by UIActivityViewController. This usage is safe because the provider is short-lived,
// immutable after init, and only accessed on the main thread via UIActivityViewController callbacks.
private final class WCFShareActivityContentProvider: UIActivityItemProvider, @unchecked Sendable {

    let text: String

    init(text: String) {
        self.text = text
        super.init(placeholderItem: text)
    }

    override var item: Any {
        return text
    }

    override func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        if let activityType, activityType.rawValue.lowercased().contains("instagram") {
            return nil
        }
        return text
    }
}
