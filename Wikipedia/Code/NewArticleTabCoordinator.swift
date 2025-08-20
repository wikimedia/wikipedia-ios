import UIKit
import WMF
import WMFComponents
import WMFData

final class NewArticleTabCoordinator: Coordinator {
    internal var navigationController: UINavigationController
    private var dataStore: MWKDataStore
    private var theme: Theme
    private var dataController = WMFArticleTabsDataController.shared
    private let cameFromNewTab: Bool
    private let tabIdentifier: WMFArticleTabsDataController.Identifiers?

    // MARK: - Related pages props
    private let fetcher: RelatedSearchFetcher
    private var seed: WMFArticle?
    private var related: [WMFArticle] = []
    private var seenSeedKeys = Set<String>()
    private let contentSource = WMFRelatedPagesContentSource()

    // MARK: - Did you know props
    private var dykFetcher: WMFFeedDidYouKnowFetcher
    public var dykFacts: [WMFFeedDidYouKnow]? = nil

    private let fromWikipediaDefault = CommonStrings.fromWikipediaDefault
    private let didYouKnowTitle = WMFLocalizedString("did-you-know", value: "Did you know", comment: "Text displayed as heading for section of new tab dedicated to DYK")

    // MARK: - Lifecycle
    init(navigationController: UINavigationController, dataStore: MWKDataStore, theme: Theme, fetcher: RelatedSearchFetcher = RelatedSearchFetcher(), cameFromNewTab: Bool, tabIdentifier: WMFArticleTabsDataController.Identifiers? = nil) {
        self.navigationController = navigationController
        self.dataStore = dataStore
        self.theme = theme
        self.fetcher = fetcher
        self.cameFromNewTab = cameFromNewTab
        self.tabIdentifier = tabIdentifier
        dykFetcher = WMFFeedDidYouKnowFetcher()
    }

    // MARK: - Methods
    @discardableResult
        func start() -> Bool {
            let searchVC = SearchViewController(
                source: .article,
                customArticleCoordinatorNavigationController: navigationController,
                needsAttachedView: true,
                becauseYouReadViewModel: nil,
                didYouKnowViewModel: nil
            )
            searchVC.dataStore = dataStore
            searchVC.theme = theme
            searchVC.shouldBecomeFirstResponder = true
            navigationController.pushViewController(searchVC, animated: true)
            return true
        }

}
