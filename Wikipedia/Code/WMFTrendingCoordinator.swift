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
    private weak var trendingNavigationController: UINavigationController?
    private var articleCoordinator: ArticleCoordinator?
    private var countryViewModel: WMFTrendingCountryViewModel?

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
            byAreaSegment: WMFLocalizedString("trending-segment-by-area", value: "Your Country", comment: "Segment label for trending articles filtered by geographic area"),
            mapSegment: WMFLocalizedString("trending-segment-map", value: "Explore the Map", comment: "Segment label for the map view in the Trending feature"),
            topicPickerTitle: WMFLocalizedString("trending-topic-picker-title", value: "Select Topics", comment: "Title for the topic picker sheet in the Trending feature"),
            topicPickerDoneButton: WMFLocalizedString("trending-topic-picker-done", value: "Done", comment: "Done button in the topic picker sheet in the Trending feature"),
            loadingMessage: WMFLocalizedString("trending-loading", value: "Loading trending articles…", comment: "Loading message for the Trending feature"),
            errorMessage: WMFLocalizedString("trending-error", value: "Could not load trending articles. Please try again.", comment: "Error message for the Trending feature"),
            noArticlesMessage: WMFLocalizedString("trending-empty", value: "No trending articles for the selected topics.", comment: "Empty state message for the Trending feature when no articles are returned"),
            noTopicsSelectedMessage: WMFLocalizedString("trending-no-topics-selected", value: "Please select topics.", comment: "Empty state message for the Trending feature when no topics are selected")
        )

        let viewModel = WMFTrendingViewModel(localizedStrings: localizedStrings)

        viewModel.onTapArticle = { [weak self] title, project in
            self?.showArticle(title: title, project: project)
        }

        viewModel.onTapCountry = { [weak self] country in
            self?.showCountry(country)
        }

        let viewController = WMFTrendingViewController(viewModel: viewModel)
        let navVC = WMFComponentNavigationController(rootViewController: viewController, modalPresentationStyle: .overFullScreen)
        trendingNavigationController = navVC
        navigationController.present(navVC, animated: true)
        return true
    }

    // MARK: - Private

    private func showCountry(_ country: WMFTrendingCountryAnnotation) {
        let localizedStrings = WMFTrendingCountryViewModel.LocalizedStrings(
            loadingMessage: WMFLocalizedString("trending-loading", value: "Loading trending articles…", comment: "Loading message for the Trending feature"),
            noArticlesMessage: WMFLocalizedString("trending-empty", value: "No trending articles found.", comment: "Empty state message for the Trending feature")
        )
        let viewModel = WMFTrendingCountryViewModel(country: country, localizedStrings: localizedStrings)
        viewModel.onTapArticle = { [weak self] title, project in
            self?.showArticle(title: title, project: project)
        }
        self.countryViewModel = viewModel
        let vc = WMFTrendingCountryViewController(viewModel: viewModel)
        trendingNavigationController?.pushViewController(vc, animated: true)
    }

    private func showArticle(title: String, project: WMFProject) {
        guard let siteURL = project.siteURL,
              var articleURL = siteURL.wmf_URL(withTitle: title) else {
            return
        }
        articleURL.wmf_languageVariantCode = project.languageVariantCode

        let navController = trendingNavigationController ?? navigationController
        let articleCoordinator = ArticleCoordinator(
            navigationController: navController,
            articleURL: articleURL,
            dataStore: dataStore,
            theme: theme,
            source: .undefined,
            tabConfig: .appendArticleAndAssignCurrentTab
        )
        self.articleCoordinator = articleCoordinator
        articleCoordinator.start()
    }
}
