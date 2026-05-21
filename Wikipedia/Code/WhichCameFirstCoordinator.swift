import UIKit
import SwiftUI
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

    /// The modal navigation controller that hosts the splash screen and game screens.
    private weak var gameNavigationController: UINavigationController?

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
        let viewModel = WMFWhichCameFirstViewModel(date: formattedTodayISODateString(), project: project)
        viewModel.didTapShare = { [weak self, weak viewModel] in
            guard let self, let viewModel else { return }
            self.showShare(gameViewModel: viewModel)
        }
        let gameVC = WMFWhichCameFirstHostingController(viewModel: viewModel)
        gameNav.setViewControllers([gameVC], animated: true)
    }

    private func showShare(gameViewModel: WMFWhichCameFirstViewModel) {
        guard let gameNav = gameNavigationController,
              let events = gameViewModel.makeShareArticleEvents(),
              let results = gameViewModel.makeShareQuestionResults() else { return }

        Task { [weak gameNav] in
            guard let gameNav else { return }

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

            let shareView = WMFWhichCameFirstShareView(viewModel: shareViewModel)
            let renderer = ImageRenderer(content: shareView)
            renderer.scale = UIScreen.main.scale
            guard let image = renderer.uiImage else { return }

            let textProvider = WCFShareActivityContentProvider(
                text: "I'm playing \"Which came first?\" a daily trivia game on the Wikipedia iOS app https://apps.apple.com/app/apple-store/id324715238?pt=208305&ct=wiki_game_202605&mt=8"
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

    private func formattedTodayDateString() -> String { // TODO: add a date formatter to allow for international dates, not only US
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

// MARK: - Share Content Provider

/// Provides share text for most activity types, but returns nil for Instagram (image-only).
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

