import UIKit
import WMFComponents
import WMFData

/// A lightweight view controller that wraps `SearchResultsViewController` as its
/// `navigationItem.searchController.searchResultsController` and immediately activates the search bar
/// upon appearance. Intended to be pushed onto an existing navigation stack (e.g. from a search
/// button in a non-search context). No history view is shown; article taps push the article.
class SearchMinimalViewController: ThemeableViewController, WMFNavigationBarConfiguring {

    // MARK: - Dependencies

    private let dataStore: MWKDataStore

    // MARK: - Public configuration (set before pushing)

    /// Forwarded to the container. Default `true`.
    var showLanguageBar: Bool = true

    /// Forwarded to the container to scope searches to a specific wiki.
    var siteURL: URL?

    /// If set, the search bar is pre-populated with this term and a search is triggered on appear.
    var prefilledSearchTerm: String?

    /// Override the default article-push behavior. If nil, uses `LinkCoordinator`.
    var articleTappedAction: ((URL) -> Void)?

    // MARK: - Child

    private lazy var searchResultsContainer: SearchResultsViewController = {
        let container = SearchResultsViewController(source: .unknown, dataStore: dataStore)
        container.apply(theme: theme)
        container.parentSearchControllerDelegate = self
        container.populateSearchBarAction = { [weak self] searchTerm in
            self?.navigationItem.searchController?.searchBar.text = searchTerm
            self?.navigationItem.searchController?.searchBar.becomeFirstResponder()
        }
        container.articleTappedAction = { [weak self] articleURL in
            guard let self else { return }
            if let customAction = self.articleTappedAction {
                customAction(articleURL)
            } else {
                guard let navVC = navigationController else { return }
                let coordinator = LinkCoordinator(
                    navigationController: navVC,
                    url: articleURL,
                    dataStore: dataStore,
                    theme: theme,
                    articleSource: .search,
                    tabConfig: nil
                )
                if !coordinator.start() {
                    navigate(to: articleURL)
                }
            }
        }
        return container
    }()

    // MARK: - Init

    @objc init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // Apply configuration properties to the container now that it's initialized
        searchResultsContainer.showLanguageBar = showLanguageBar
        if let siteURL { searchResultsContainer.siteURL = siteURL }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.navigationItem.searchController?.isActive = true
            if let term = self.prefilledSearchTerm {
                self.navigationItem.searchController?.searchBar.text = term
                self.searchResultsContainer.searchAndMakeResultsVisible(for: term)
            }
            self.navigationItem.searchController?.searchBar.becomeFirstResponder()
        }
    }

    // MARK: - Navigation Bar

    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: CommonStrings.searchTitle, customView: nil, alignment: .centerCompact)

        let searchConfig = WMFNavigationBarSearchConfig(
            searchResultsController: searchResultsContainer,
            searchControllerDelegate: searchResultsContainer,
            searchResultsUpdater: searchResultsContainer,
            searchBarDelegate: nil,
            searchBarPlaceholder: CommonStrings.searchBarPlaceholder,
            showsScopeBar: false,
            scopeButtonTitles: nil
        )

        configureNavigationBar(
            titleConfig: titleConfig,
            backButtonConfig: nil,
            closeButtonConfig: nil,
            profileButtonConfig: nil,
            tabsButtonConfig: nil,
            searchBarConfig: searchConfig,
            hideNavigationBarOnScroll: false
        )
    }

    // MARK: - Theme

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else { return }
        view.backgroundColor = theme.colors.paperBackground
        searchResultsContainer.apply(theme: theme)
    }
}

// MARK: - UISearchControllerDelegate

extension SearchMinimalViewController: UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
        navigationController?.hidesBarsOnSwipe = false
    }

    func didDismissSearchController(_ searchController: UISearchController) {
        navigationController?.hidesBarsOnSwipe = true
        searchResultsContainer.resetSearchResults()
        SearchFunnel.shared.logSearchCancel(source: SearchResultsViewController.EventLoggingSource.unknown.stringValue)
    }
}
