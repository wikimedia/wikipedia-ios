import UIKit
import WMFComponents
import WMFData
import WMFNativeLocalizations

final class WMFTrendingCoordinator: NSObject, Coordinator {

    // MARK: Coordinator Protocol Properties

    var navigationController: UINavigationController

    // MARK: Properties

    private let dataStore: MWKDataStore
    private let theme: Theme

    // MARK: Lifecycle

    init(navigationController: UINavigationController, dataStore: MWKDataStore, theme: Theme) {
        self.navigationController = navigationController
        self.dataStore = dataStore
        self.theme = theme
    }

    // MARK: Coordinator Protocol Methods

    @discardableResult
    func start() -> Bool {
        let localizedStrings = WMFTrendingViewModel.LocalizedStrings(
            navigationTitle: WMFLocalizedString("trending-title", value: "Trending", comment: "Title for the Trending articles feature"),
            byTopicSegment: WMFLocalizedString("trending-segment-by-topic", value: "By Topic", comment: "Segment label for trending articles filtered by topic"),
            byAreaSegment: WMFLocalizedString("trending-segment-by-area", value: "By Area", comment: "Segment label for trending articles filtered by geographic area"),
            topicPickerTitle: WMFLocalizedString("trending-topic-picker-title", value: "Choose a Topic", comment: "Title for the topic picker sheet in the Trending feature"),
            loadingMessage: WMFLocalizedString("trending-loading", value: "Loading trending articles…", comment: "Loading message for the Trending feature"),
            errorMessage: WMFLocalizedString("trending-error", value: "Could not load trending articles. Please try again.", comment: "Error message for the Trending feature"),
            noArticlesMessage: WMFLocalizedString("trending-empty", value: "No trending articles found.", comment: "Empty state message for the Trending feature")
        )

        let viewModel = WMFTrendingViewModel(localizedStrings: localizedStrings)

        viewModel.onTapArticle = { [weak self] title, project in
            self?.showArticle(title: title, project: project)
        }

        let viewController = WMFTrendingViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
        return true
    }

    // MARK: - Private

    private func showArticle(title: String, project: WMFProject) {
        guard let siteURL = project.siteURL,
              var articleURL = siteURL.wmf_URL(withTitle: title) else {
            return
        }
        articleURL.wmf_languageVariantCode = project.languageVariantCode

        let articleCoordinator = ArticleCoordinator(
            navigationController: navigationController,
            articleURL: articleURL,
            dataStore: dataStore,
            theme: theme,
            source: .undefined,
            tabConfig: .appendArticleAndAssignCurrentTab
        )
        articleCoordinator.start()
    }
}
