import UIKit
import WMFComponents
import WMFData
import CocoaLumberjackSwift
import SwiftUI
import Combine

class SearchViewController: ThemeableViewController, WMFNavigationBarConfiguring, WMFNavigationBarHiding, MEPEventsProviding, HintPresenting, ShareableArticlesProvider {

    var hintController: HintController?

    var eventLoggingCategory: EventCategoryMEP {
        return .history
    }

    var eventLoggingLabel: EventLabelMEP? {
        return nil
    }

    @objc enum EventLoggingSource: Int {
        case searchTab
        case topOfFeed
        case article
        case unknown

        var stringValue: String {
            switch self {
            case .article:
                return "article"
            case .topOfFeed:
                return "top_of_feed"
            case .searchTab:
                return "search_tab"
            case .unknown:
                return "unknown"
            }
        }
    }

    @objc var dataStore: MWKDataStore?

    var deleteButton: UIBarButtonItem?
    private var cancellables = Set<AnyCancellable>()

    var isSearchTab: Bool {
        if let navigationController,
           navigationController.viewControllers.count == 1 {
            return true
        }

        return false
    }

    var isEditLinkOrArticleSearchButtonSearch: Bool {
        return !isSearchTab && navigationController != nil
    }

    // Assign if you don't want search result selection to do default navigation, and instead want to perform your own custom logic upon search result selection.
    var navigateToSearchResultAction: ((URL) -> Void)?
    
    // Set so that the correct search bar will have it's field populated once a "recently searched" term is selected. If this is missing, logic will default to navigationController?.searchController.searchBar for population.
    var populateSearchBarWithTextAction: ((String) -> Void)?

    var customTitle: String?
    @objc var needsCenteredTitle: Bool = false
    private let isMainRootView: Bool

    private var searchLanguageBarViewController: SearchLanguagesBarViewController?
    private var needsAnimateLanguageBarMovement = false

    var topSafeAreaOverlayView: UIView?
    var topSafeAreaOverlayHeightConstraint: NSLayoutConstraint?

    // Properties needed for Profile Button

    private var _yirCoordinator: YearInReviewCoordinator?
    var yirCoordinator: YearInReviewCoordinator? {

        guard let navigationController,
              let yirDataController,
              let dataStore else {
            return nil
        }

        guard let existingYirCoordinator = _yirCoordinator else {
            _yirCoordinator = YearInReviewCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore, dataController: yirDataController)
            _yirCoordinator?.badgeDelegate = self
            return _yirCoordinator
        }

        return existingYirCoordinator
    }

    private var _profileCoordinator: ProfileCoordinator?
    private var profileCoordinator: ProfileCoordinator? {

        guard let navigationController,
        let yirCoordinator = self.yirCoordinator,
            let dataStore else {
            return nil
        }

        guard let existingProfileCoordinator = _profileCoordinator else {
            _profileCoordinator = ProfileCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore, donateSouce: .searchProfile, logoutDelegate: self, sourcePage: ProfileCoordinatorSource.search, yirCoordinator: yirCoordinator)
            _profileCoordinator?.badgeDelegate = self
            return _profileCoordinator
        }

        return existingProfileCoordinator
    }

    private lazy var tabsCoordinator: TabsOverviewCoordinator? = { [weak self] in
        guard let self, let nav = self.navigationController, let dataStore else { return nil }
        return TabsOverviewCoordinator(
            navigationController: nav,
            theme: self.theme,
            dataStore: dataStore
        )
    }()

    var customTabConfigUponArticleNavigation: ArticleTabConfig?

    private var yirDataController: WMFYearInReviewDataController? {
        return try? WMFYearInReviewDataController()
    }

    private let source: EventLoggingSource

    // Used to push on after tapping search result. This is needed when SearchViewController is embedded directly as the system navigation bar's searchResultsController (i.e. Explore and Article).
    private var customArticleCoordinatorNavigationController: UINavigationController?

    private var presentingSearchResults: Bool = false

    // MARK: - Lifecycle

    @objc required init(source: EventLoggingSource, customArticleCoordinatorNavigationController: UINavigationController? = nil,  isMainRootView: Bool = false) {
        self.source = source
        self.customArticleCoordinatorNavigationController = customArticleCoordinatorNavigationController
        self.isMainRootView = isMainRootView
        super.init(nibName: nil, bundle: nil)
        if !isMainRootView {
            hidesBottomBarWhenPushed = true
        }
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateLanguageBarVisibility()

        setupReadingListsHelpers()

        if isSearchTab {
            embedHistoryViewController()
        } else if !isEditLinkOrArticleSearchButtonSearch { // Edit link & article magnifying glass add results via the navigation bar search controller, so no need to embed in those cases.
            embedResultsViewController()
        }

        deleteButton = UIBarButtonItem(title: CommonStrings.clearTitle, style: .plain, target: self, action: #selector(deleteButtonPressed(_:)))

        historyViewModel.$isEmpty
            .receive(on: RunLoop.main)
            .sink { [weak self] isEmpty in
                self?.deleteButton?.isEnabled = !isEmpty
            }
            .store(in: &cancellables)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
        updateLanguageBarVisibility()
        reloadRecentSearches()
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

        if let searchLanguageBarViewController {
            historyViewModel.topPadding = searchLanguageBarViewController.view.frame.height
            if !isSearchTab && !isEditLinkOrArticleSearchButtonSearch {
                recentSearchesViewModel.topPadding = searchLanguageBarViewController.view.bounds.height
                resultsViewController.collectionView.contentInset.top = searchLanguageBarViewController.view.bounds.height
            }
        } else {
            historyViewModel.topPadding = 0
            recentSearchesViewModel.topPadding = 0
            resultsViewController.collectionView.contentInset.top = 0
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 18, *) {
            if UIDevice.current.userInterfaceIdiom == .pad {
                if previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass {
                    configureNavigationBar()
                }
            }
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.calculateTopSafeAreaOverlayHeight()
        }
    }

    // MARK: - Navigation bar configuring

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
        let wButton = UIButton(type: .custom)
            wButton.setImage(UIImage(named: "W"), for: .normal)

        var titleConfig: WMFNavigationBarTitleConfig
        titleConfig = WMFNavigationBarTitleConfig(title: title, customView: nil, alignment: alignment)


        if #available(iOS 18, *) {
            if UIDevice.current.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .regular {
                titleConfig = WMFNavigationBarTitleConfig(title: CommonStrings.searchTitle, customView: nil, alignment: .leadingLarge)
            }
        }

        let profileButtonConfig: WMFNavigationBarProfileButtonConfig?
        let tabsButtonConfig: WMFNavigationBarTabsButtonConfig?
        if let dataStore {
            profileButtonConfig = self.profileButtonConfig(target: self, action: #selector(userDidTapProfile), dataStore: dataStore, yirDataController: yirDataController, leadingBarButtonItem: nil)
            tabsButtonConfig = self.tabsButtonConfig(target: self, action: #selector(userDidTapTabs), dataStore: dataStore)
        } else {
            profileButtonConfig = nil
            tabsButtonConfig = nil
        }
        
        let searchBarConfig = WMFNavigationBarSearchConfig(searchResultsController: nil, searchControllerDelegate: self, searchResultsUpdater: self, searchBarDelegate: self, searchBarPlaceholder: CommonStrings.searchBarPlaceholder, showsScopeBar: false, scopeButtonTitles: nil)

        configureNavigationBar(titleConfig: titleConfig, backButtonConfig: nil, closeButtonConfig: nil, profileButtonConfig: profileButtonConfig, tabsButtonConfig: tabsButtonConfig, searchBarConfig: searchBarConfig, hideNavigationBarOnScroll: !presentingSearchResults)
    }

    private func updateProfileButton() {

        guard let dataStore else {
            return
        }

        let config = self.profileButtonConfig(target: self, action: #selector(userDidTapProfile), dataStore: dataStore, yirDataController: yirDataController, leadingBarButtonItem: nil)
        updateNavigationBarProfileButton(needsBadge: config.needsBadge, needsBadgeLabel: CommonStrings.profileButtonBadgeTitle, noBadgeLabel: CommonStrings.profileButtonTitle)
    }

    @objc func userDidTapProfile() {

        guard let dataStore else {
            return
        }

        guard let languageCode = dataStore.languageLinkController.appLanguage?.languageCode,
              let metricsID = DonateCoordinator.metricsID(for: .searchProfile, languageCode: languageCode) else {
            return
        }

        DonateFunnel.shared.logSearchProfile(metricsID: metricsID)

        profileCoordinator?.start()
    }

    @objc func userDidTapTabs() {
        tabsCoordinator?.start()
        ArticleTabsFunnel.shared.logIconClick(interface: .search, project: nil)
    }

    @objc final func deleteButtonPressed(_ sender: UIBarButtonItem) {

        let deleteAllConfirmationText = WMFLocalizedString("history-clear-confirmation-heading", value: "Are you sure you want to delete all your recent items?", comment: "Heading text of delete all confirmation dialog")
        let deleteAllText = WMFLocalizedString("history-clear-delete-all", value: "Yes, delete all", comment: "Button text for confirming delete all action")

        let alertController = UIAlertController(title: deleteAllConfirmationText, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: deleteAllText, style: .destructive, handler: { (action) in
            self.deleteAll()
        }))
        alertController.addAction(UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel, handler: nil))
        alertController.popoverPresentationController?.barButtonItem = sender
        alertController.popoverPresentationController?.permittedArrowDirections = .any
        present(alertController, animated: true, completion: nil)
    }

    private func deleteAll() {
        guard let dataStore else { return }
        do {
            try dataStore.viewContext.clearReadHistory()
            historyViewModel.sections = []

        } catch let error {
            showError(error)
        }

        Task {
            do {
                let dataController = try WMFPageViewsDataController()
                try await dataController.deleteAllPageViewsAndCategories()

            } catch {
                DDLogError("Failure deleting WMFData WMFPageViews: \(error)")
            }
        }
    }

    private func embedResultsViewController() {
        addChild(resultsViewController)
        view.wmf_addSubviewWithConstraintsToEdges(resultsViewController.view)
        resultsViewController.didMove(toParent: self)
        updateRecentlySearchedVisibility(searchText: nil)
    }

    private func embedHistoryViewController() {
        addChild(historyViewController)
        view.wmf_addSubviewWithConstraintsToEdges(historyViewController.view)
        historyViewController.didMove(toParent: self)
    }

    private func setupLanguageBarViewController() -> SearchLanguagesBarViewController {
        if let vc = self.searchLanguageBarViewController {
            return vc
        }
        let searchLanguageBarViewController = SearchLanguagesBarViewController()
        searchLanguageBarViewController.apply(theme: theme)
        searchLanguageBarViewController.delegate = self
        self.searchLanguageBarViewController = searchLanguageBarViewController
        return searchLanguageBarViewController
    }

    var searchLanguageBarTopConstraint: NSLayoutConstraint?
    private func updateLanguageBarVisibility() {
        let showLanguageBar = self.showLanguageBar ?? UserDefaults.standard.wmf_showSearchLanguageBar()
        if  showLanguageBar && searchLanguageBarViewController == nil { // check this before accessing the view
            let searchLanguageBarViewController = setupLanguageBarViewController()
            addChild(searchLanguageBarViewController)
            searchLanguageBarViewController.view.translatesAutoresizingMaskIntoConstraints = false

            let searchLanguageBarTopConstraint = searchLanguageBarViewController.view.topAnchor.constraint(equalTo: view.topAnchor, constant: view.safeAreaInsets.top)
            self.searchLanguageBarTopConstraint = searchLanguageBarTopConstraint

            view.addSubview(searchLanguageBarViewController.view)
            NSLayoutConstraint.activate([
                searchLanguageBarTopConstraint,
                view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: searchLanguageBarViewController.view.leadingAnchor),
                view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: searchLanguageBarViewController.view.trailingAnchor)
            ])

            searchLanguageBarViewController.didMove(toParent: self)
            searchLanguageBarViewController.view.isHidden = false
        } else if !showLanguageBar && searchLanguageBarViewController != nil {

            if let searchLanguageBarViewController {
                searchLanguageBarViewController.willMove(toParent: nil)
                searchLanguageBarViewController.view.removeFromSuperview()
                searchLanguageBarViewController.removeFromParent()
                self.searchLanguageBarViewController = nil
                self.searchLanguageBarTopConstraint = nil
            }
        }
        view.setNeedsLayout()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        guard needsAnimateLanguageBarMovement else {
            searchLanguageBarTopConstraint?.constant = view.safeAreaInsets.top
            view.layoutIfNeeded()
            return
        }

        searchLanguageBarTopConstraint?.constant = view.safeAreaInsets.top
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }

    // MARK: - Search

    @objc var shouldBecomeFirstResponder: Bool = false

    var showLanguageBar: Bool?

    var searchTerm: String?
    private var lastSearchSiteURL: URL?
    private var _siteURL: URL?

    var siteURL: URL? {
        get {
            return _siteURL ?? searchLanguageBarViewController?.selectedSiteURL ?? MWKDataStore.shared().primarySiteURL ?? NSURL.wmf_URLWithDefaultSiteAndCurrentLocale()
        }
        set {
            _siteURL = newValue
        }
    }

    @objc func searchAndMakeResultsVisibleForSearchTerm(_ term: String?, animated: Bool) {
        searchTerm = term
        navigationItem.searchController?.searchBar.text = term
        search(for: searchTerm, suggested: false)
        navigationItem.searchController?.searchBar.becomeFirstResponder()
    }

    func search() {
        search(for: searchTerm, suggested: false)
    }

    private func search(for searchTerm: String?, suggested: Bool) {
        guard let siteURL = siteURL else {
            assert(false)
            return
        }

        self.lastSearchSiteURL = siteURL

        guard
            let searchTerm = searchTerm,
            searchTerm.wmf_hasNonWhitespaceText
        else {
            didCancelSearch()
            return
        }

        guard (searchTerm as NSString).character(at: 0) != NSTextAttachment.character else {
            return
        }

        resetSearchResults()
        let start = Date()

        let failure = { (error: Error, type: WMFSearchType) in
            DispatchQueue.main.async { [weak self] in
                guard let self,
                      searchTerm == self.navigationItem.searchController?.searchBar.text else {
                    return
                }
                self.resultsViewController.emptyViewType = (error as NSError).wmf_isNetworkConnectionError() ? .noInternetConnection : .noSearchResults
                self.resultsViewController.results = []
                SearchFunnel.shared.logShowSearchError(with: type, elapsedTime: Date().timeIntervalSince(start), source: self.source.stringValue)
            }
        }

        let success = { (results: WMFSearchResults, type: WMFSearchType) in
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }

                NSUserActivity.wmf_makeActive(NSUserActivity.wmf_searchResultsActivitySearchSiteURL(siteURL, searchTerm: searchTerm))
                let resultsArray = results.results ?? []
                self.resultsViewController.emptyViewType = .noSearchResults
                self.resultsViewController.resultsInfo = results
                self.resultsViewController.searchSiteURL = siteURL
                self.resultsViewController.results = resultsArray
                guard !suggested else {
                    return
                }
                SearchFunnel.shared.logSearchResults(with: type, resultCount: resultsArray.count, elapsedTime: Date().timeIntervalSince(start), source: self.source.stringValue)
            }
        }

        fetcher.fetchArticles(forSearchTerm: searchTerm, siteURL: siteURL, resultLimit: WMFMaxSearchResultLimit, failure: { (error) in
            failure(error, .prefix)
        }) { (results) in
            success(results, .prefix)
            guard let resultsArray = results.results, resultsArray.count < 12 else {
                return
            }
            self.fetcher.fetchArticles(forSearchTerm: searchTerm, siteURL: siteURL, resultLimit: WMFMaxSearchResultLimit, fullTextSearch: true, appendToPreviousResults: results, failure: { (error) in
                failure(error, .full)
            }) { (results) in
                success(results, .full)
            }
        }
    }

    lazy var fetcher: WMFSearchFetcher = {
        return WMFSearchFetcher()
    }()

    func resetSearchResults() {
        resultsViewController.emptyViewType = .none
        resultsViewController.results = []
    }

    func didCancelSearch() {
        resultsViewController.emptyViewType = .none
        resultsViewController.results = []
        navigationItem.searchController?.searchBar.text = nil
    }

    @objc func clear() {
        didCancelSearch()
        updateRecentlySearchedVisibility(searchText: navigationItem.searchController?.searchBar.text)
    }

    lazy var resultsViewController: SearchResultsViewController = {
        let resultsViewController = SearchResultsViewController()
        resultsViewController.dataStore = dataStore
        resultsViewController.apply(theme: theme)

        let tappedSearchResultAction: (URL, IndexPath) -> Void = { [weak self] articleURL, indexPath in

            guard let self else {
                return
            }
            SearchFunnel.shared.logSearchResultTap(position: indexPath.item, source: source.stringValue)

            saveLastSearch()

            if let navigateToSearchResultAction {
                navigateToSearchResultAction(articleURL)
            } else if let customArticleCoordinatorNavigationController {
                
                let tabConfig = self.customTabConfigUponArticleNavigation ?? .appendArticleAndAssignCurrentTab

                let linkCoordinator = LinkCoordinator(navigationController: customArticleCoordinatorNavigationController, url: articleURL, dataStore: dataStore, theme: theme, articleSource: .search, tabConfig: tabConfig)
                let success = linkCoordinator.start()

                if !success {
                    navigate(to: articleURL)
                }

            } else if let navigationController {
                
                let tabConfig = self.customTabConfigUponArticleNavigation

                let linkCoordinator = LinkCoordinator(navigationController: navigationController, url: articleURL, dataStore: dataStore, theme: theme, articleSource: .search, tabConfig: tabConfig)
                let success = linkCoordinator.start()

                if !success {
                    navigate(to: articleURL)
                }
            }
        }

        let longPressSearchResultAndCommitAction: (URL) -> Void = { [weak self] articleURL in
            guard let self, let dataStore = self.dataStore else { return }
            guard let navVC = customArticleCoordinatorNavigationController ?? navigationController else { return }
            let coordinator = ArticleCoordinator(navigationController: navVC, articleURL: articleURL, dataStore: dataStore, theme: self.theme, source: .search)
            coordinator.start()
        }

        let longPressOpenInNewTabAction: (URL) -> Void = { [weak self] articleURL in
            guard let self else { return }

            guard let navVC = customArticleCoordinatorNavigationController ?? navigationController else { return }
            let articleCoordinator = ArticleCoordinator(navigationController: navVC, articleURL: articleURL, dataStore: MWKDataStore.shared(), theme: self.theme, source: .undefined, tabConfig: .appendArticleAndAssignCurrentTab)
            articleCoordinator.start()
        }

        resultsViewController.tappedSearchResultAction = tappedSearchResultAction
        resultsViewController.longPressSearchResultAndCommitAction = longPressSearchResultAndCommitAction
        resultsViewController.longPressOpenInNewTabAction = longPressOpenInNewTabAction

        return resultsViewController
    }()

    // MARK: - Embeded search history

    func tappedArticle(_ item: HistoryItem) -> Void? {
        if let articleURL = item.url, let dataStore, let articleViewController = ArticleViewController(articleURL: articleURL, dataStore: dataStore, theme: theme, source: .history) {
            return self.navigationController?.pushViewController(articleViewController, animated: true)
        }
        return nil
    }


    func share(item: HistoryItem, frame: CGRect?) {
        if let dataStore, let url = item.url {
            let article = dataStore.fetchArticle(with: url)
            let dummyView = UIView(frame: frame ?? CGRect.zero)
            _ = share(article: article, articleURL: url, dataStore: dataStore, theme: theme, eventLoggingCategory: eventLoggingCategory, eventLoggingLabel: eventLoggingLabel, sourceView: dummyView)
        }
    }

    lazy var historyDataController: WMFHistoryDataController = {
        let recordsProvider: WMFHistoryDataController.RecordsProvider = { [weak self] in

            guard let self, let dataStore else {
                return []
            }

            let request: NSFetchRequest<WMFArticle> = WMFArticle.fetchRequest()
            request.predicate = NSPredicate(format: "viewedDate != NULL")
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \WMFArticle.viewedDateWithoutTime, ascending: false),
                NSSortDescriptor(keyPath: \WMFArticle.viewedDate, ascending: false)
            ]

            do {
                var articles: [HistoryRecord] = []
                let articleFetchRequest = try dataStore.viewContext.fetch(request)

                for article in articleFetchRequest {
                    if let viewedDate = article.viewedDate, let pageID = article.pageID {

                        let record = HistoryRecord(
                            id: Int(truncating: pageID),
                            title: article.displayTitle ?? article.displayTitleHTML,
                            descriptionOrSnippet: article.capitalizedWikidataDescriptionOrSnippet,
                            shortDescription: article.snippet,
                            articleURL: article.url,
                            imageURL: article.imageURLString,
                            viewedDate: viewedDate,
                            isSaved: article.isSaved,
                            snippet: article.snippet,
                            variant: article.variant
                        )
                        articles.append(record)
                    }
                }

                return articles

            } catch {
                DDLogError("Error fetching history: \(error)")
                return []
            }
        }

        let deleteRecordAction: WMFHistoryDataController.DeleteRecordAction = { [weak self] historyItem in
            guard let self, let dataStore = self.dataStore else { return }
            let request: NSFetchRequest<WMFArticle> = WMFArticle.fetchRequest()
            request.predicate = NSPredicate(format: "pageID == %@", historyItem.id)
            do {
                if let article = try dataStore.viewContext.fetch(request).first {
                    try article.removeFromReadHistory()
                }

            } catch {
                showError(error)

            }
            guard let title = historyItem.url?.wmf_title,
                  let languageCode = historyItem.url?.wmf_languageCode else {
                return
            }

            let variant = historyItem.variant

            let project = WMFProject.wikipedia(WMFLanguage(languageCode: languageCode, languageVariantCode: variant))

            Task {
                do {
                    let dataController = try WMFPageViewsDataController()
                    try await dataController.deletePageView(title: title, namespaceID: 0, project: project)
                } catch {
                    DDLogError("Failure deleting WMFData WMFPageViews: \(error)")
                }
            }
        }

        let saveArticleAction: WMFHistoryDataController.SaveRecordAction = { [weak self] historyItem in
            guard let self, let dataStore = self.dataStore, let articleURL = historyItem.url else { return }
            dataStore.savedPageList.addSavedPage(with: articleURL)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(userDidSaveOrUnsaveArticle(_:)),
                                                   name: WMFReadingListsController.userDidSaveOrUnsaveArticleNotification,
                                                   object: nil)
            historyItem.isSaved = true
        }

        let unsaveArticleAction: WMFHistoryDataController.UnsaveRecordAction = { [weak self] historyItem in
            guard let self, let dataStore = self.dataStore, let articleURL = historyItem.url else { return }

            dataStore.savedPageList.removeEntry(with: articleURL)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(userDidSaveOrUnsaveArticle(_:)),
                                                   name: WMFReadingListsController.userDidSaveOrUnsaveArticleNotification,
                                                   object: nil)
            historyItem.isSaved = false
        }

        let dataController = WMFHistoryDataController(
            recordsProvider: recordsProvider
        )
        return dataController
    }()

    lazy var historyViewModel: WMFHistoryViewModel = {

        let shareArticleAction: WMFHistoryViewModel.ShareRecordAction = { [weak self] frame, historyItem in
            guard let self else { return }
            self.share(item:historyItem, frame: frame)
        }

        let onTapArticleAction: WMFHistoryViewModel.OnRecordTapAction = { [weak self] historyItem in
            guard let self else { return }
            self.tappedArticle(historyItem)
        }

        let todayTitle = WMFLocalizedString("today-title", value: "Today", comment: "Title for today section on article view history")

        let yesterdayTitle = WMFLocalizedString("yesterday-title", value: "Yesterday", comment: "Title for yesterday section on article view history")

        let localizedStrings = WMFHistoryViewModel.LocalizedStrings(emptyViewTitle: CommonStrings.emptyNoHistoryTitle, emptyViewSubtitle: CommonStrings.emptyNoHistorySubtitle, todayTitle: todayTitle, yesterdayTitle: yesterdayTitle, openArticleActionTitle: "Open article",saveForLaterActionTitle: CommonStrings.saveTitle, unsaveActionTitle: CommonStrings.unsaveTitle, shareActionTitle: CommonStrings.shareMenuTitle, deleteSwipeActionLabel: CommonStrings.deleteActionTitle)
        let viewModel = WMFHistoryViewModel(emptyViewImage: UIImage(named: "history-blank"), localizedStrings: localizedStrings, historyDataController: historyDataController)
        return viewModel
    }()

    lazy var historyViewController: UIViewController = {
        let historyView = WMFHistoryView(viewModel: historyViewModel)
        return UIHostingController(rootView: historyView)
    }()

    // MARK: - Reading lists hint controller

    private func setupReadingListsHelpers() {
        guard let dataStore else { return }
        hintController = ReadingListHintController(dataStore: dataStore)
        hintController?.apply(theme: theme)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(userDidSaveOrUnsaveArticle(_:)),
                                               name: WMFReadingListsController.userDidSaveOrUnsaveArticleNotification,
                                               object: nil)
    }

    @objc private func userDidSaveOrUnsaveArticle(_ notification: Notification) {
        guard let article = notification.object as? WMFArticle else {
            return
        }

        showReadingListHint(for: article)
    }

    private func showReadingListHint(for article: WMFArticle) {

        guard let presentingVC = visibleHintPresentingViewController() else {
            return
        }

        let context: [String: Any] = [ReadingListHintController.ContextArticleKey: article]
        toggleHint(hintController, context: context, presentingIn: presentingVC)
    }

    func visibleHintPresentingViewController() -> (UIViewController & HintPresenting)? {
        if let nav = self.tabBarController?.selectedViewController as? UINavigationController {
            return nav.topViewController as? (UIViewController & HintPresenting)
        }
        return nil
    }

    private func toggleHint(_ hintController: HintController?, context: [String: Any], presentingIn presentingVC: UIViewController) {

        if let presenting = presentingVC as? (UIViewController & HintPresenting) {
            hintController?.toggle(presenter: presenting, context: context, theme: theme)
        }
    }

    // MARK: - Recent Search Saving

    func saveLastSearch() {
        guard
            let term = resultsViewController.resultsInfo?.searchTerm,
            let url = resultsViewController.searchSiteURL,
            let entry = MWKRecentSearchEntry(url: url, searchTerm: term),
            let dataStore
        else {
            return
        }
        dataStore.recentSearchList.addEntry(entry)
        dataStore.recentSearchList.save()
        reloadRecentSearches()
    }

    @objc func makeSearchBarBecomeFirstResponder() {
        if !(navigationItem.searchController?.searchBar.isFirstResponder ?? false) {
            navigationItem.searchController?.searchBar.becomeFirstResponder()
        }
    }

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
            self.recentSearches?.entries.indices.contains(index) ?? false,
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

    lazy var selectAction: (WMFRecentlySearchedViewModel.RecentSearchTerm) -> Void = { [weak self] term in
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

    private lazy var recentSearchTerms: [WMFRecentlySearchedViewModel.RecentSearchTerm] = {
        guard let recent = recentSearches else { return [] }
        return recent.entries.map {
            WMFRecentlySearchedViewModel.RecentSearchTerm(text: $0.searchTerm)
        }
    }()


    private func reloadRecentSearches() {
        let entries = recentSearches?.entries ?? []
        let terms = entries.map { entry in
            WMFRecentlySearchedViewModel.RecentSearchTerm(text: entry.searchTerm)
        }

        recentSearchesViewModel.recentSearchTerms = terms
        updateRecentlySearchedVisibility(
            searchText: navigationItem.searchController?.searchBar.text
        )
    }

    public func updateRecentlySearchedVisibility(searchText: String?) {
        guard let searchText = searchText else {
            resultsViewController.view.isHidden = true
            return
        }

        resultsViewController.view.isHidden = searchText.isEmpty
    }

    // MARK: - Theme

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }

        searchLanguageBarViewController?.apply(theme: theme)
        resultsViewController.apply(theme: theme)
        view.backgroundColor = theme.colors.paperBackground
        themeTopSafeAreaOverlay()
        updateProfileButton()
        profileCoordinator?.theme = theme
    }

}


extension SearchViewController: SearchLanguagesBarViewControllerDelegate {
    func searchLanguagesBarViewController(_ controller: SearchLanguagesBarViewController, didChangeSelectedSearchContentLanguageCode contentLanguageCode: String) {
        SearchFunnel.shared.logSearchLangSwitch(source: source.stringValue)
        search()
    }
}

extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text,
        !text.isEmpty else {
            searchTerm = nil
            updateRecentlySearchedVisibility(searchText: nil)
            return
        }

        if let lastSearchSiteURL,
           searchTerm == text && lastSearchSiteURL == siteURL {
            return
        }

        searchTerm = text
        updateRecentlySearchedVisibility(searchText: text)
        search(for: text, suggested: false)
    }
}

extension SearchViewController: UISearchControllerDelegate {
    func didPresentSearchController(_ searchController: UISearchController) {
        if shouldBecomeFirstResponder {
            DispatchQueue.main.async {[weak self] in
                self?.navigationItem.searchController?.searchBar.becomeFirstResponder()
            }
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

extension SearchViewController: UISearchBarDelegate {
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        navigationItem.searchController?.isActive = false
    }
}

extension SearchViewController: LogoutCoordinatorDelegate {
    func didTapLogout() {

        guard let dataStore else {
            return
        }

        wmf_showKeepSavedArticlesOnDevicePanelIfNeeded(triggeredBy: .logout, theme: theme) {
            dataStore.authenticationManager.logout(initiatedBy: .user)
        }
    }
}

extension SearchViewController: YearInReviewBadgeDelegate {
    func updateYIRBadgeVisibility() {
        updateProfileButton()
    }
}
