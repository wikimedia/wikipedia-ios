import UIKit
import WMFComponents
import WMFData
import CocoaLumberjackSwift
import SwiftUI

final class SearchHostingController: WMFComponentHostingController<WMFSearchResultsView> {}

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
            wmfSearchViewModel.recentSearchesViewModel.recentSearchTerms = terms.map { RecentSearchTerm(text: $0) }
        } catch {
            DDLogError("Failed to fetch recent searches: \(error)")
            wmfSearchViewModel.recentSearchesViewModel.recentSearchTerms = []
        }
    }

    // MARK: - SwiftUI Search View

    private lazy var searchSwiftUIView: WMFSearchResultsView = WMFSearchResultsView(viewModel: wmfSearchViewModel)
    private lazy var searchResultsHostingController: UIHostingController<WMFSearchResultsView> = {
        let host = UIHostingController(rootView: searchSwiftUIView)
        host.view.backgroundColor = .clear
        return host
    }()
    
    // MARK: - Recently Searched

    var recentSearches: MWKRecentSearchList? {
        return self.dataStore?.recentSearchList
    }

    var countOfRecentSearches: Int {
        return recentSearches?.entries.count ?? 0
    }

    lazy var didPressClearRecentSearches: () -> Void = { [weak self] in
        let dialog = UIAlertController(title: CommonStrings.clearRecentSearchesDialogTitle, message: CommonStrings.clearRecentSearchesDialogSubtitle, preferredStyle: .alert)
        dialog.addAction(UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel, handler: nil))
        dialog.addAction(UIAlertAction(title: CommonStrings.deleteAllTitle, style: .destructive, handler: { (action) in
            self?.deleteAllAction()
        }))
        self?.present(dialog, animated: true)
    }

    private lazy var recentSearchesViewController: UIViewController = {
        let root = WMFRecentlySearchedView(viewModel: recentSearchesViewModel)
        let host = UIHostingController(rootView: root)
        return host
    }()

    private lazy var deleteAllAction: () -> Void = { [weak self] in
        guard let self = self else { return }

        Task {
            self.dataStore?.recentSearchList.removeAllEntries()
            self.dataStore?.recentSearchList.save()
            self.reloadRecentSearches()
        }

    }

    private lazy var deleteItemAction: (Int) -> Void = { [weak self] index in
        guard
            let self = self,
            let entry = self.recentSearches?.entries[index]
        else {
            return
        }

        Task {
            self.dataStore?.recentSearchList.removeEntry(entry)
            self.dataStore?.recentSearchList.save()
            self.reloadRecentSearches()
        }
    }

    lazy var selectAction: (RecentSearchTerm) -> Void = { [weak self] term in
        guard let self = self else { return }

        if let pop = self.populateSearchBarWithTextAction {
            pop(term.text)
        } else {
            self.navigationItem.searchController?.searchBar.text = term.text
            self.navigationItem.searchController?.searchBar.becomeFirstResponder()
        }
        self.search()
    }

    private lazy var recentSearchesViewModel: WMFRecentlySearchedViewModel = {
        let localizedStrings = WMFRecentlySearchedViewModel.LocalizedStrings(
            title: CommonStrings.recentlySearchedTitle,
            noSearches: CommonStrings.recentlySearchedEmpty,
            clearAll: CommonStrings.clearTitle,
            deleteActionAccessibilityLabel: CommonStrings.deleteActionTitle, editButtonTitle: CommonStrings.editContextMenuTitle
        )
        let vm = WMFRecentlySearchedViewModel(recentSearchTerms: recentSearchTerms, topPadding: 0, localizedStrings: localizedStrings, deleteAllAction: didPressClearRecentSearches, deleteItemAction: deleteItemAction, selectAction: selectAction)
        return vm
    }()

    private lazy var recentSearchTerms: [RecentSearchTerm] = {
        guard let recent = recentSearches else { return [] }
        return recent.entries.map {
            RecentSearchTerm(text: $0.searchTerm)
        }
    }()

    private func embedRecentSearches() {
        addChild(recentSearchesViewController)
        view.addSubview(recentSearchesViewController.view)
        recentSearchesViewController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            recentSearchesViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            recentSearchesViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            recentSearchesViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            recentSearchesViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        recentSearchesViewController.didMove(toParent: self)
    }

    private func reloadRecentSearches() {
        let entries = recentSearches?.entries ?? []
        let terms = entries.map { entry in
            RecentSearchTerm(text: entry.searchTerm)
        }

        recentSearchesViewModel.recentSearchTerms = terms
        updateRecentlySearchedVisibility(
            searchText: navigationItem.searchController?.searchBar.text
        )
    }

    @MainActor
    private lazy var wmfSearchViewModel: WMFSearchResultsViewModel = {
        let vm = WMFSearchResultsViewModel(localizedStrings:
            WMFSearchResultsViewModel.LocalizedStrings(
                emptyText: WMFLocalizedString("search-no-results", value: "No results found", comment: "No results found."),
                openInNewTab: CommonStrings.openInNewTab,
                openInBackgroundTab: CommonStrings.articleTabsOpenInBackgroundTab,
                saveForLater: { languageCode in
                    CommonStrings.saveTitle(languageCode: languageCode)
                },
                preview: "preview"),
            recentSearchesViewModel: recentSearchesViewModel)
        
        // Open
        vm.tappedSearchResultAction = { [weak self] url in
            guard let self else { return }
            self.saveLastSearch()

            if let navigateToSearchResultAction {
                navigateToSearchResultAction(url)
            } else if let customNav = self.customArticleCoordinatorNavigationController ?? self.navigationController {
                let tabConfig = self.customTabConfigUponArticleNavigation ?? .appendArticleAndAssignCurrentTab
                let coordinator = LinkCoordinator(navigationController: customNav, url: url, dataStore: self.dataStore, theme: self.theme, articleSource: .search, tabConfig: tabConfig)
                _ = coordinator.start()
            }
        }
        
        // Open in new tab
        vm.longPressOpenInNewTabAction = { [weak self] url in
            guard let self else { return }

            guard let navVC = customArticleCoordinatorNavigationController ?? navigationController else { return }
            let articleCoordinator = ArticleCoordinator(navigationController: navVC, articleURL: url, dataStore: MWKDataStore.shared(), theme: self.theme, source: .undefined, tabConfig: .appendArticleAndAssignCurrentTab)
            articleCoordinator.start()
        }
        
        // ?
        vm.longPressSearchResultAction = { [weak self] url in
            guard let self, let dataStore = self.dataStore else { return }
            guard let navVC = customArticleCoordinatorNavigationController ?? navigationController else { return }
            let coordinator = ArticleCoordinator(navigationController: navVC, articleURL: url, dataStore: dataStore, theme: self.theme, source: .search)
            coordinator.start()
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
        embedSearchResultsSwiftUIView()
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
        wmfSearchViewModel.topPadding = topPadding
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

    private func embedSearchResultsSwiftUIView() {
        addChild(searchResultsHostingController)
        view.addSubview(searchResultsHostingController.view)
        searchResultsHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchResultsHostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            searchResultsHostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchResultsHostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchResultsHostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        searchResultsHostingController.didMove(toParent: self)
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
    
    private var searchTask: Task<Void, Never>?
    private let searchDebounceNanoseconds: UInt64 = 750_000_000 // 350ms
    
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
        if searchTerm == "" {
            wmfSearchViewModel.searchQuery = searchTerm
            wmfSearchViewModel.reset(clearQuery: true)
        }
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
                    self.wmfSearchViewModel.results = results.results
                    self.wmfSearchViewModel.searchSiteURL = siteURL
                   // self.wmfSearchViewModel.emptyViewType = results.results.isEmpty ? .noSearchResults : .none

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
                        self.wmfSearchViewModel.results.append(contentsOf: fullTextResults.results)
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
                    // self.resultsViewController.emptyViewType = (error as NSError).wmf_isNetworkConnectionError() ? .noInternetConnection : .noSearchResults
                    self.wmfSearchViewModel.results = []
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
        wmfSearchViewModel.results = []
    }

    func didCancelSearch() {
        wmfSearchViewModel.results = []
        wmfSearchViewModel.searchQuery = nil
        wmfSearchViewModel.reset(clearQuery: true)
        navigationItem.searchController?.searchBar.text = nil
    }

    public func updateRecentlySearchedVisibility(searchText: String?) {
        let showRecent = searchText?.isEmpty ?? true
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
        wmfSearchViewModel.recentSearchesViewModel.recentSearchTerms = terms.map { RecentSearchTerm(text: $0)}
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
        let text = searchController.searchBar.text ?? ""

        searchTerm = text
        wmfSearchViewModel.searchQuery = text
        updateRecentlySearchedVisibility(searchText: text)

        searchTask?.cancel()

        guard text.wmf_hasNonWhitespaceText else {
            wmfSearchViewModel.reset(clearQuery: false)
            return
        }

        searchTask = Task {
            try? await Task.sleep(nanoseconds: searchDebounceNanoseconds)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                search()
            }
        }
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
