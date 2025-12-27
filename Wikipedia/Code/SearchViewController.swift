import UIKit
import WMFComponents
import WMFData
import CocoaLumberjackSwift
import SwiftUI

final class SearchHostingController: WMFComponentHostingController<WMFSearchView> {}

class SearchViewController: ThemeableViewController, WMFNavigationBarConfiguring, WMFNavigationBarHiding {
    @objc enum EventLoggingSource: Int {
        case searchTab, topOfFeed, article, unknown
        var stringValue: String {
            switch self {
            case .article: return "article"
            case .topOfFeed: return "top_of_feed"
            case .searchTab: return "search_tab"
            case .unknown: return "unknown"
            }
        }
    }

    private let dataController = WMFSearchDataController()
    private let recentSearchesDataController = WMFRecentSearchesDataController()
    @objc var dataStore: MWKDataStore?
    private let source: EventLoggingSource

    // MARK: - Profile / YIR Coordinators

    private var _yirCoordinator: YearInReviewCoordinator?
    var yirCoordinator: YearInReviewCoordinator? {
        guard let navigationController,
              let yirDataController,
              let dataStore else { return nil }

        if let existing = _yirCoordinator { return existing }
        _yirCoordinator = YearInReviewCoordinator(
            navigationController: navigationController,
            theme: theme,
            dataStore: dataStore,
            dataController: yirDataController
        )
        _yirCoordinator?.badgeDelegate = self
        return _yirCoordinator
    }

    private var _profileCoordinator: ProfileCoordinator?
    private var profileCoordinator: ProfileCoordinator? {
        guard let navigationController,
              let yirCoordinator = self.yirCoordinator,
              let dataStore else { return nil }

        if let existing = _profileCoordinator { return existing }
        _profileCoordinator = ProfileCoordinator(
            navigationController: navigationController,
            theme: theme,
            dataStore: dataStore,
            donateSouce: .searchProfile,
            logoutDelegate: self,
            sourcePage: .search,
            yirCoordinator: yirCoordinator
        )
        _profileCoordinator?.badgeDelegate = self
        return _profileCoordinator
    }

    private lazy var tabsCoordinator: TabsOverviewCoordinator? = { [weak self] in
        guard let self, let nav = self.navigationController, let dataStore else { return nil }
        return TabsOverviewCoordinator(navigationController: nav, theme: self.theme, dataStore: dataStore)
    }()

    var customTabConfigUponArticleNavigation: ArticleTabConfig?

    private var yirDataController: WMFYearInReviewDataController? {
        return try? WMFYearInReviewDataController()
    }

    // MARK: - Recent Searches

    @MainActor
    private func migrateRecentSearchesIfNeeded() async {
        guard recentSearchesDataController.hasMigrated == false, let dataStore else { return }

        let oldEntries = Array(dataStore.recentSearchList.entries.prefix(20))
        guard !oldEntries.isEmpty else {
            recentSearchesDataController.hasMigrated = true
            return
        }

        do {
            for entry in oldEntries {
                guard let siteURL = entry.url else { continue }
                try await recentSearchesDataController.saveRecentSearch(term: entry.searchTerm, siteURL: siteURL)
            }
            recentSearchesDataController.hasMigrated = true
        } catch {
            recentSearchesDataController.hasMigrated = false
            DDLogError("Recent search migration failed: \(error)")
        }
    }

    @MainActor
    private func loadRecentSearchTerms() async {
        do {
            let terms = try await recentSearchesDataController.fetchRecentSearches()
            wmfSearchViewModel.recentSearches = terms.map { WMFSearchViewModel.RecentSearchTerm(text: $0) }
        } catch {
            DDLogError("Failed to fetch recent searches: \(error)")
            wmfSearchViewModel.recentSearches = []
        }
    }

    // MARK: - SwiftUI Search View

    private lazy var searchSwiftUIView: WMFSearchView = WMFSearchView(viewModel: wmfSearchViewModel)
    private lazy var searchHostingController: UIHostingController<WMFSearchView> = {
        let host = UIHostingController(rootView: searchSwiftUIView)
        host.view.backgroundColor = .clear
        return host
    }()

    @MainActor
    private lazy var wmfSearchViewModel: WMFSearchViewModel = {
        let vm = WMFSearchViewModel(
            dataController: dataController,
            localizedStrings: WMFSearchViewModel.LocalizedStrings(
                recentTitle: CommonStrings.recentlySearchedTitle,
                noSearches: CommonStrings.recentlySearchedEmpty,
                clearAll: CommonStrings.clearRecentSearchesDialogTitle,
                deleteActionAccessibilityLabel: CommonStrings.deleteActionTitle
            )
        )

        vm.didTapSearchResult = { [weak self] result in
            guard let self, let url = result.articleURL else { return }
            self.saveLastSearch()

            if let navigateToSearchResultAction {
                navigateToSearchResultAction(url)
            } else if let customNav = self.customArticleCoordinatorNavigationController ?? self.navigationController {
                let tabConfig = self.customTabConfigUponArticleNavigation ?? .appendArticleAndAssignCurrentTab
                let coordinator = LinkCoordinator(navigationController: customNav, url: url, dataStore: self.dataStore, theme: self.theme, articleSource: .search, tabConfig: tabConfig)
                _ = coordinator.start()
            }
        }

        return vm
    }()

    // MARK: - General Properties

    var navigateToSearchResultAction: ((URL) -> Void)?
    var populateSearchBarWithTextAction: ((String) -> Void)?

    var customTitle: String?
    @objc var needsCenteredTitle: Bool = false
    private let isMainRootView: Bool

    private var searchLanguageBarViewController: SearchLanguagesBarViewController?
    private var needsAnimateLanguageBarMovement = false

    var topSafeAreaOverlayView: UIView?
    var topSafeAreaOverlayHeightConstraint: NSLayoutConstraint?

    private var customArticleCoordinatorNavigationController: UINavigationController?
    private var presentingSearchResults: Bool = false

    // MARK: - Lifecycle

    @objc required init(source: EventLoggingSource, customArticleCoordinatorNavigationController: UINavigationController? = nil, isMainRootView: Bool = false) {
        self.source = source
        self.customArticleCoordinatorNavigationController = customArticleCoordinatorNavigationController
        self.isMainRootView = isMainRootView
        super.init(nibName: nil, bundle: nil)
        if !isMainRootView { hidesBottomBarWhenPushed = true }
    }

    @MainActor required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        embedSearchSwiftUIView()
        embedResultsViewController()
        updateLanguageBarVisibility()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
        Task {
            await migrateRecentSearchesIfNeeded()
            await loadRecentSearchTerms()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NSUserActivity.wmf_makeActive(NSUserActivity.wmf_searchView())
        SearchFunnel.shared.logSearchStart(source: source.stringValue)

        if shouldBecomeFirstResponder {
            DispatchQueue.main.async { [weak self] in
                self?.navigationItem.searchController?.isActive = true
                self?.navigationItem.searchController?.searchBar.becomeFirstResponder()
            }
        }

        if isMainRootView {
            ArticleTabsFunnel.shared.logIconImpression(interface: .search, project: nil)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let topPadding = searchLanguageBarViewController?.view.bounds.height ?? 0
        resultsViewController.collectionView.contentInset.top = topPadding
    }

    @objc var shouldBecomeFirstResponder: Bool = false

    // MARK: - Navigation Bar & Buttons

    private func configureNavigationBar() {
        let title = customTitle ?? CommonStrings.searchTitle
        var alignment: WMFNavigationBarTitleConfig.Alignment = needsCenteredTitle ? .centerCompact : .leadingCompact
        extendedLayoutIncludesOpaqueBars = false
        if #available(iOS 18, *) {
            if UIDevice.current.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .regular && alignment == .leadingCompact {
                alignment = .leadingLarge
                extendedLayoutIncludesOpaqueBars = true
            }
        }

        let titleConfig = WMFNavigationBarTitleConfig(title: title, customView: nil, alignment: alignment)
        let profileButtonConfig = dataStore.map { self.profileButtonConfig(target: self, action: #selector(userDidTapProfile), dataStore: $0, yirDataController: yirDataController, leadingBarButtonItem: nil) }
        let tabsButtonConfig = dataStore.map { self.tabsButtonConfig(target: self, action: #selector(userDidTapTabs), dataStore: $0) }
        let searchBarConfig = WMFNavigationBarSearchConfig(searchResultsController: nil, searchControllerDelegate: self, searchResultsUpdater: self, searchBarDelegate: self, searchBarPlaceholder: CommonStrings.searchBarPlaceholder, showsScopeBar: false, scopeButtonTitles: nil)

        configureNavigationBar(titleConfig: titleConfig, backButtonConfig: nil, closeButtonConfig: nil, profileButtonConfig: profileButtonConfig, tabsButtonConfig: tabsButtonConfig, searchBarConfig: searchBarConfig, hideNavigationBarOnScroll: !presentingSearchResults)
    }

    private func updateProfileButton() {
        guard let dataStore else { return }
        let config = self.profileButtonConfig(target: self, action: #selector(userDidTapProfile), dataStore: dataStore, yirDataController: yirDataController, leadingBarButtonItem: nil)
        updateNavigationBarProfileButton(needsBadge: config.needsBadge, needsBadgeLabel: CommonStrings.profileButtonBadgeTitle, noBadgeLabel: CommonStrings.profileButtonTitle)
    }

    @objc func userDidTapProfile() {
        guard let dataStore else { return }
        guard let languageCode = dataStore.languageLinkController.appLanguage?.languageCode,
              let metricsID = DonateCoordinator.metricsID(for: .searchProfile, languageCode: languageCode) else { return }
        DonateFunnel.shared.logSearchProfile(metricsID: metricsID)
        profileCoordinator?.start()
    }

    @objc func userDidTapTabs() {
        tabsCoordinator?.start()
        ArticleTabsFunnel.shared.logIconClick(interface: .search, project: nil)
    }

    // MARK: - Embed Views

    private func embedSearchSwiftUIView() {
        addChild(searchHostingController)
        view.addSubview(searchHostingController.view)
        searchHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchHostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            searchHostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchHostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchHostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        searchHostingController.didMove(toParent: self)
    }

    lazy var resultsViewController: SearchResultsViewController = {
        let vc = SearchResultsViewController()
        vc.dataStore = dataStore
        vc.apply(theme: theme)
        return vc
    }()

    private func embedResultsViewController() {
        addChild(resultsViewController)
        view.wmf_addSubviewWithConstraintsToEdges(resultsViewController.view)
        resultsViewController.didMove(toParent: self)
        updateRecentlySearchedVisibility(searchText: nil)
    }

    // MARK: - Search

    func search() {
        search(for: searchTerm, suggested: false)
    }
    
    @objc(searchAndMakeResultsVisibleForSearchTerm:animated:)
    func searchAndMakeResultsVisible(for term: String?, animated: Bool) {
        searchTerm = term
        navigationItem.searchController?.searchBar.text = term
        search(for: searchTerm, suggested: false)
        navigationItem.searchController?.searchBar.becomeFirstResponder()
    }
    
    private func search(for searchTerm: String?, suggested: Bool) {
        guard let siteURL = siteURL else {
            assertionFailure("No siteURL available")
            return
        }

        self.lastSearchSiteURL = siteURL

        guard let searchTerm = searchTerm, searchTerm.wmf_hasNonWhitespaceText else {
            didCancelSearch()
            return
        }

        guard (searchTerm as NSString).character(at: 0) != NSTextAttachment.character else {
            return
        }

        resetSearchResults()
        let start = Date()

        Task {
            do {
                let results = try await dataController.searchArticles(
                    term: searchTerm,
                    siteURL: siteURL,
                    limit: Int(WMFMaxSearchResultLimit)
                )

                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    NSUserActivity.wmf_makeActive(
                        NSUserActivity.wmf_searchResultsActivitySearchSiteURL(siteURL, searchTerm: searchTerm)
                    )
                    self.resultsViewController.results = results.results
                    self.resultsViewController.searchSiteURL = siteURL
                    self.resultsViewController.emptyViewType = results.results.isEmpty ? .noSearchResults : .none

                    guard !suggested else { return }
                    SearchFunnel.shared.logSearchResults(
                        with: .prefix,
                        resultCount: results.results.count,
                        elapsedTime: Date().timeIntervalSince(start),
                        source: self.source.stringValue
                    )
                }

                if results.results.count < 12 {
                    let fullTextResults = try await dataController.searchArticles(
                        term: searchTerm,
                        siteURL: siteURL,
                        limit: Int(WMFMaxSearchResultLimit),
                        fullText: true
                    )

                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        self.resultsViewController.results.append(contentsOf: fullTextResults.results)
                        SearchFunnel.shared.logSearchResults(
                            with: .full,
                            resultCount: fullTextResults.results.count,
                            elapsedTime: Date().timeIntervalSince(start),
                            source: self.source.stringValue
                        )
                    }
                }

            } catch {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.resultsViewController.emptyViewType = (error as NSError).wmf_isNetworkConnectionError() ? .noInternetConnection : .noSearchResults
                    self.resultsViewController.results = []
                    SearchFunnel.shared.logShowSearchError(
                        with: .prefix,
                        elapsedTime: Date().timeIntervalSince(start),
                        source: self.source.stringValue
                    )
                }
            }
        }
    }


    @objc func makeSearchBarBecomeFirstResponder() {
        if !(navigationItem.searchController?.searchBar.isFirstResponder ?? false) {
            navigationItem.searchController?.searchBar.becomeFirstResponder()
        }
    }

    @objc func clear() {
        didCancelSearch()
        updateRecentlySearchedVisibility(searchText: navigationItem.searchController?.searchBar.text)
    }

    func resetSearchResults() {
        resultsViewController.emptyViewType = .none
        resultsViewController.results = []
    }

    func didCancelSearch() {
        resultsViewController.emptyViewType = .none
        resultsViewController.results = []
        navigationItem.searchController?.searchBar.text = nil
    }

    public func updateRecentlySearchedVisibility(searchText: String?) {
        let showRecent = searchText?.isEmpty ?? true
        resultsViewController.view.isHidden = showRecent
    }

    func saveLastSearch() {
        guard let term = searchTerm, let siteURL = siteURL else { return }
        Task {
            try? await recentSearchesDataController.saveRecentSearch(term: term, siteURL: siteURL)
            await reloadRecentSearches()
        }
    }

    @MainActor
    private func reloadRecentSearches() async {
        let terms = (try? await recentSearchesDataController.fetchRecentSearches()) ?? []
        wmfSearchViewModel.recentSearches = terms.map { WMFSearchViewModel.RecentSearchTerm(text: $0) }
    }

    var searchTerm: String?
    private var lastSearchSiteURL: URL?
    private var _siteURL: URL?

    var siteURL: URL? {
        get { _siteURL ?? searchLanguageBarViewController?.selectedSiteURL ?? MWKDataStore.shared().primarySiteURL ?? NSURL.wmf_URLWithDefaultSiteAndCurrentLocale() }
        set { _siteURL = newValue }
    }

    var showLanguageBar: Bool?

    private func setupLanguageBarViewController() -> SearchLanguagesBarViewController {
        if let vc = self.searchLanguageBarViewController { return vc }
        let vc = SearchLanguagesBarViewController()
        vc.apply(theme: theme)
        vc.delegate = self
        self.searchLanguageBarViewController = vc
        return vc
    }

    var searchLanguageBarTopConstraint: NSLayoutConstraint?
    private func updateLanguageBarVisibility() {
        let showLanguageBar = self.showLanguageBar ?? UserDefaults.standard.wmf_showSearchLanguageBar()
        if showLanguageBar && searchLanguageBarViewController == nil {
            let vc = setupLanguageBarViewController()
            addChild(vc)
            vc.view.translatesAutoresizingMaskIntoConstraints = false
            let topConstraint = vc.view.topAnchor.constraint(equalTo: view.topAnchor, constant: view.safeAreaInsets.top)
            self.searchLanguageBarTopConstraint = topConstraint
            view.addSubview(vc.view)
            NSLayoutConstraint.activate([
                topConstraint,
                view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
                view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor)
            ])
            vc.didMove(toParent: self)
            vc.view.isHidden = false
        } else if !showLanguageBar, let vc = searchLanguageBarViewController {
            vc.willMove(toParent: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParent()
            self.searchLanguageBarViewController = nil
            self.searchLanguageBarTopConstraint = nil
        }
        view.setNeedsLayout()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        searchLanguageBarTopConstraint?.constant = view.safeAreaInsets.top
        if needsAnimateLanguageBarMovement {
            UIView.animate(withDuration: 0.2) { self.view.layoutIfNeeded() }
        } else {
            view.layoutIfNeeded()
        }
    }
}

// MARK: - SearchLanguagesBarViewControllerDelegate
extension SearchViewController: SearchLanguagesBarViewControllerDelegate {
    func searchLanguagesBarViewController(_ controller: SearchLanguagesBarViewController, didChangeSelectedSearchContentLanguageCode contentLanguageCode: String) {
        SearchFunnel.shared.logSearchLangSwitch(source: source.stringValue)
        search()
    }
}

// MARK: - UISearchResultsUpdating
extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text, !text.isEmpty else {
            searchTerm = nil
            updateRecentlySearchedVisibility(searchText: nil)
            return
        }
        searchTerm = text
        wmfSearchViewModel.searchQuery = text
        Task { await wmfSearchViewModel.performSearch(query: text) }
    }
}

// MARK: - UISearchControllerDelegate
extension SearchViewController: UISearchControllerDelegate {
    func didPresentSearchController(_ searchController: UISearchController) {
        if shouldBecomeFirstResponder {
            DispatchQueue.main.async { [weak self] in self?.navigationItem.searchController?.searchBar.becomeFirstResponder() }
        }
        needsAnimateLanguageBarMovement = false
    }

    func willPresentSearchController(_ searchController: UISearchController) {
        needsAnimateLanguageBarMovement = true
        navigationController?.hidesBarsOnSwipe = false
        presentingSearchResults = true
    }

    func willDismissSearchController(_ searchController: UISearchController) {
        needsAnimateLanguageBarMovement = true
    }

    func didDismissSearchController(_ searchController: UISearchController) {
        needsAnimateLanguageBarMovement = false
        navigationController?.hidesBarsOnSwipe = true
        presentingSearchResults = false
        SearchFunnel.shared.logSearchCancel(source: source.stringValue)
    }
}

// MARK: - UISearchBarDelegate
extension SearchViewController: UISearchBarDelegate {
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        navigationItem.searchController?.isActive = false
    }
}

// MARK: - LogoutCoordinatorDelegate
extension SearchViewController: LogoutCoordinatorDelegate {
    func didTapLogout() {
        guard let dataStore else { return }
        wmf_showKeepSavedArticlesOnDevicePanelIfNeeded(triggeredBy: .logout, theme: theme) {
            dataStore.authenticationManager.logout(initiatedBy: .user)
        }
    }
}

// MARK: - YearInReviewBadgeDelegate
extension SearchViewController: YearInReviewBadgeDelegate {
    func updateYIRBadgeVisibility() {
        updateProfileButton()
    }
}
