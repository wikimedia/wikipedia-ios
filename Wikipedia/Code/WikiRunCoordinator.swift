import UIKit
import WMF
import WMFComponents

/// Coordinator for the WikiRun web game: resolves where the game is hosted, presents it, and
/// handles leaving it for an article or the share sheet.
@MainActor
final class WikiRunCoordinator: NSObject, Coordinator {

    var navigationController: UINavigationController

    private let dataStore: MWKDataStore
    private let theme: Theme
    private weak var gameNavigationController: UINavigationController?

    init(navigationController: UINavigationController, dataStore: MWKDataStore, theme: Theme) {
        self.navigationController = navigationController
        self.dataStore = dataStore
        self.theme = theme
    }

    @discardableResult
    func start() -> Bool {
        guard let baseURL = Self.resolveBaseURL() else {
            assertionFailure("WikiRun base URL is not a valid URL")
            return false
        }

        let viewModel = WMFWikiRunViewModel(baseURL: baseURL)
        viewModel.onOpenArticle = { [weak self] url in self?.openArticle(url) }
        viewModel.onShare = { [weak self] text, url in self?.share(text: text, url: url) }
        viewModel.onClose = { [weak self] in self?.gameNavigationController?.dismiss(animated: true) }

        // Keep the game on screen behind the article, so back returns to the game-over screen.
        let gameNavigationController = WMFComponentNavigationController(
            rootViewController: WMFWikiRunHostingController(viewModel: viewModel),
            modalPresentationStyle: .fullScreen
        )
        self.gameNavigationController = gameNavigationController
        navigationController.present(gameNavigationController, animated: true)
        return true
    }

    /// The game is hosted at a build-time configurable URL, falling back to the production host.
    private static func resolveBaseURL() -> URL? {
        let configuredURL = Bundle.main.object(forInfoDictionaryKey: "WikiRunBaseURL") as? String
        if let candidate = URL(string: configuredURL ?? ""),
           ["http", "https"].contains(candidate.scheme?.lowercased() ?? ""),
           candidate.host != nil {
            return candidate
        }
        return URL(string: "https://wikirun-game.toolforge.org")
    }

    // MARK: - Navigation

    private func openArticle(_ url: URL) {
        guard let gameNavigationController else { return }
        // The game decides what is encyclopedic content; anything else keeps going to the browser.
        guard LinkCoordinator.destination(for: url) == .article else {
            UIApplication.shared.open(url)
            return
        }
        let articleCoordinator = ArticleCoordinator(
            navigationController: gameNavigationController,
            articleURL: url,
            dataStore: dataStore,
            theme: theme,
            source: .game,
            tabConfig: .appendArticleAndAssignCurrentTab
        )
        articleCoordinator.start()
    }

    private func share(text: String?, url: URL?) {
        var items: [Any] = []
        if let text { items.append(text) }
        if let url { items.append(url) }
        guard !items.isEmpty, let gameNavigationController else { return }

        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = gameNavigationController.view
            popover.sourceRect = gameNavigationController.view.bounds
            popover.permittedArrowDirections = []
        }
        gameNavigationController.present(activityViewController, animated: true)
    }
}
