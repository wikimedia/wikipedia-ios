import UIKit
import WMFComponents
import WMFData
import SwiftUI
import CocoaLumberjackSwift
import WMF

class SearchViewController: ThemeableViewController, WMFNavigationBarConfiguring, WMFNavigationBarHiding, MEPEventsProviding {
    var eventLoggingCategory: EventCategoryMEP {
        return .history
    }

   var eventLoggingLabel: EventLabelMEP? {
        return nil
    }

    @objc var dataStore: MWKDataStore?
    
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
    
    // Assign if you don't want search result selection to do default navigation, and instead want to perform your own custom logic upon search result selection.
    var navigateToSearchResultAction: ((URL) -> Void)?
    
    // Set so that the correct search bar will have it's field populated once a "recently searched" term is selected. If this is missing, logic will default to navigationController?.searchController.searchBar for population.
    var populateSearchBarWithTextAction: ((String) -> Void)?
    
    var customTitle: String?
    @objc var needsCenteredTitle: Bool = false
    
    private var searchLanguageBarViewController: SearchLanguagesBarViewController?
    private var needsAnimateLanguageBarMovement = false
    
    var topSafeAreaOverlayView: UIView?
    var topSafeAreaOverlayHeightConstraint: NSLayoutConstraint?

    var readingListHintController: ReadingListHintController?

    // TODO: Reference A/B test source PR instead
    var isSearchTab: Bool {
        if let navigationController,
           navigationController.viewControllers.count == 1 {
            // Indicates this is the root view, so likely the Search tab.
            return true
        }
        
        return false
    }
    
    // TODO: Reference A/B test source PR instead
    var isEditLinkOrArticleSearchButtonSearch: Bool {
        return !isSearchTab && navigationController != nil
    }
    
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
            _profileCoordinator = ProfileCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore, donateSouce: .savedProfile, logoutDelegate: self, sourcePage: ProfileCoordinatorSource.saved, yirCoordinator: yirCoordinator)
            _profileCoordinator?.badgeDelegate = self
            return _profileCoordinator
        }
        
        return existingProfileCoordinator
    }
    
    private var yirDataController: WMFYearInReviewDataController? {
        return try? WMFYearInReviewDataController()
    }
    
    private let source: EventLoggingSource
    
    // MARK: - Funcs
    
    @objc required init(source: EventLoggingSource) {
        self.source = source
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isSearchTab {
            embedHistoryViewController()
        } else if !isEditLinkOrArticleSearchButtonSearch { // Edit link & article magnifying glass add results via the navigation bar search controller, so no need to embed in those cases.
            embedResultsViewController()
        }
        setupTopSafeAreaOverlay(scrollView: nil)
        setupReadingListsHelpers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
        updateLanguageBarVisibility()
        reloadRecentSearches()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        SearchFunnel.shared.logSearchStart(source: source.stringValue, assignment: articleSearchBarExperimentAssignment)
        NSUserActivity.wmf_makeActive(NSUserActivity.wmf_searchView())
        
        if shouldBecomeFirstResponder {
            navigationItem.searchController?.isActive = true
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let searchLanguageBarViewController {
            historyViewModel.topPadding = searchLanguageBarViewController.view.frame.height
            if !isSearchTab && !isEditLinkOrArticleSearchButtonSearch {
                resultsViewController.collectionView.contentInset.top = searchLanguageBarViewController.view.frame.height
                resultsViewController.recentlySearchedTopPadding = searchLanguageBarViewController.view.frame.height
            }
        } else {
            historyViewModel.topPadding = 0
            resultsViewController.collectionView.contentInset.top = 0
            resultsViewController.recentlySearchedTopPadding = 0
        }
    }
    
    // TODO: This is old logic that only worked with a UIKit collection view for displaying the navigation bar upon scroll.
    // It fixed these bugs:
    // 1. When there are many items, if you scroll up very very slowly, you can get to a state where you are scrolled to the top and the navigation bar is not shown.
    // 2. When there are very few items, scrolling causes a bounce, and the navigation bar would hide and not reappear. This would listen for that content offset back to zero and force it to reappear.
    
    // Try to accomplish these fixes with SwiftUI in these ways:
    // 1. For bug 1, listen for first section onAppear / onDisappear events from History SwiftUI view. When onAppear is triggered, ensure nav bar is revealed via navigationController?.setNavigationBarHidden(false, animated: true)
    // 2. For bug 2, in viewDidLayoutSubviews, check and see the both first and last items are on screen using SwiftUI onAppear/onDisappear modifiers. If they are displaying, disable nav bar hiding via navigationController?.hidesBarsOnSwipe = false
    //
    //    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
    //        super.scrollViewDidScroll(scrollView)
    //
    //        let normalizedContentOffset = scrollView.contentOffset.y + (scrollView.safeAreaInsets.top + scrollView.contentInset.top)
    //        calculateNavigationBarHiddenState(scrollView: scrollView)
    //    }
    
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

    private var articleSearchBarExperimentAssignment: WMFNavigationExperimentsDataController.ArticleSearchBarExperimentAssignment? {
        
        guard let assignment = try? WMFNavigationExperimentsDataController.shared?.articleSearchBarExperimentAssignment() else {
            return nil
        }
        
        return assignment
    }

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
        
        var titleConfig: WMFNavigationBarTitleConfig = WMFNavigationBarTitleConfig(title: title, customView: nil, alignment: alignment)
        if #available(iOS 18, *) {
            if UIDevice.current.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .regular {
                titleConfig = WMFNavigationBarTitleConfig(title: CommonStrings.searchTitle, customView: nil, alignment: .leadingLarge)
            }
        }
        
        let profileButtonConfig: WMFNavigationBarProfileButtonConfig?
        let deleteButton = UIBarButtonItem(title: CommonStrings.clearTitle, style: .plain, target: self, action: #selector(deleteButtonPressed(_:)))
        deleteButton.isEnabled = !historyViewModel.isEmpty

        if let dataStore {
            profileButtonConfig = self.profileButtonConfig(target: self, action: #selector(userDidTapProfile), dataStore: dataStore, yirDataController: yirDataController, leadingBarButtonItem: deleteButton, trailingBarButtonItem: nil)
        } else {
            profileButtonConfig = nil
        }
        
        let searchBarConfig = WMFNavigationBarSearchConfig(searchResultsController: resultsViewController, searchControllerDelegate: self, searchResultsUpdater: self, searchBarDelegate: self, searchBarPlaceholder: WMFLocalizedString("search-field-placeholder-text", value: "Search Wikipedia", comment: "Search field placeholder text"), showsScopeBar: false, scopeButtonTitles: nil)
        
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: nil, profileButtonConfig: profileButtonConfig, searchBarConfig: searchBarConfig, hideNavigationBarOnScroll: true)
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
            historyViewModel.isEmpty = true

        } catch let error {
            showError(error)
        }

        Task {
            do {
                let dataController = try WMFPageViewsDataController()
                try await dataController.deleteAllPageViews()

            } catch {
                DDLogError("Failure deleting WMFData WMFPageViews: \(error)")
            }
        }
    }

    private func updateProfileButton() {
        
        guard let dataStore else {
            return
        }
        
        let config = self.profileButtonConfig(target: self, action: #selector(userDidTapProfile), dataStore: dataStore, yirDataController: yirDataController, leadingBarButtonItem: nil, trailingBarButtonItem: nil)
        updateNavigationBarProfileButton(needsBadge: config.needsBadge, needsBadgeLabel: CommonStrings.profileButtonBadgeTitle, noBadgeLabel: CommonStrings.profileButtonTitle)
    }
    
    @objc func userDidTapProfile() {
        
        guard let dataStore else {
            return
        }
        
        guard let languageCode = dataStore.languageLinkController.appLanguage?.languageCode,
              let metricsID = DonateCoordinator.metricsID(for: .savedProfile, languageCode: languageCode) else {
            return
        }
        
        // TODO: Do we need logging like this?
        // DonateFunnel.shared.logExploreProfile(metricsID: metricsID)
        
        profileCoordinator?.start()
    }
    
    private func embedHistoryViewController() {
        addChild(historyViewController)
        view.wmf_addSubviewWithConstraintsToEdges(historyViewController.view)
        historyViewController.didMove(toParent: self)
    }
    
    private func embedResultsViewController() {
        addChild(resultsViewController)
        view.wmf_addSubviewWithConstraintsToEdges(resultsViewController.view)
        resultsViewController.didMove(toParent: self)
        updateRecentlySearchedVisibility(searchText: nil)
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
    
    // MARK: - State
    
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
                SearchFunnel.shared.logShowSearchError(with: type, elapsedTime: Date().timeIntervalSince(start), source: self.source.stringValue, assignment: articleSearchBarExperimentAssignment)
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
                SearchFunnel.shared.logSearchResults(with: type, resultCount: Int(resultsArray.count), elapsedTime: Date().timeIntervalSince(start), source: self.source.stringValue, assignment: articleSearchBarExperimentAssignment)
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
    
    // MARK: - Search
    
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
        SearchFunnel.shared.logSearchCancel(source: source.stringValue, assignment: articleSearchBarExperimentAssignment)
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
            
            SearchFunnel.shared.logSearchResultTap(position: indexPath.item, source: source.stringValue, assignment: articleSearchBarExperimentAssignment)
            saveLastSearch()
            
            if let navigateToSearchResultAction {
                navigateToSearchResultAction(articleURL)
            } else {
                let userInfo: [AnyHashable : Any] = [RoutingUserInfoKeys.source: RoutingUserInfoSourceValue.search.rawValue]
                navigate(to: articleURL, userInfo: userInfo)
            }
        }
        
        resultsViewController.tappedSearchResultAction = tappedSearchResultAction
        
        return resultsViewController
    }()

    // MARK: - Embed search

    func tappedArticle(_ item: HistoryItem) -> Void? {
        // TODO: Swap for coordinator when available
        if let articleURL = item.url, let dataStore, let articleViewController = ArticleViewController(articleURL: articleURL, dataStore: dataStore, theme: theme) {
            return self.navigationController?.pushViewController(articleViewController, animated: true)
        }
        return nil
    }

    func share(_ item: HistoryItem) {

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
                            snippet: article.snippet
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
            // TODO: Delete from WMFPageviews
        }

        let saveArticleAction: WMFHistoryDataController.SaveRecordAction = { [weak self] historyItem in
            guard let self, let dataStore = self.dataStore, let articleURL = historyItem.url else { return }
            dataStore.savedPageList.addSavedPage(with: articleURL)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(userDidSaveOrUnsaveArticle(_:)),
                                                   name: WMFReadingListsController.userDidSaveOrUnsaveArticleNotification,
                                                   object: nil)
        }

        let unsaveArticleAction: WMFHistoryDataController.UnsaveRecordAction = { [weak self] historyItem in
            guard let self, let dataStore = self.dataStore, let articleURL = historyItem.url else { return }

            dataStore.savedPageList.removeEntry(with: articleURL)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(userDidSaveOrUnsaveArticle(_:)),
                                                   name: WMFReadingListsController.userDidSaveOrUnsaveArticleNotification,
                                                   object: nil)
        }

        let dataController = WMFHistoryDataController(
            recordsProvider: recordsProvider,
            deleteRecordAction: deleteRecordAction,
            saveArticleAction: saveArticleAction,
            unsaveArticleAction: unsaveArticleAction
        )
        return dataController
    }()

    lazy var historyViewModel: WMFHistoryViewModel = {

        let shareArticleAction: WMFHistoryViewModel.ShareRecordAction = { [weak self] historyItem in
            guard let self else { return }
            self.share(historyItem)

        }

        let onTapArticleAction: WMFHistoryViewModel.OnRecordTapAction = { [weak self] historyItem in
            guard let self else { return }
            self.tappedArticle(historyItem)
        }

        // TODO: check if accesibility labels need more info
        let localizedStrings = WMFHistoryViewModel.LocalizedStrings(title: CommonStrings.historyTabTitle, emptyViewTitle: CommonStrings.emptyNoHistoryTitle, emptyViewSubtitle: CommonStrings.emptyNoHistorySubtitle, readNowActionTitle: CommonStrings.readNowActionTitle, saveForLaterActionTitle: CommonStrings.saveTitle, unsaveActionTitle: CommonStrings.shortUnsaveTitle, shareActionTitle: CommonStrings.shareMenuTitle, deleteSwipeActionLabel: CommonStrings.deleteActionTitle)
        let viewModel = WMFHistoryViewModel(localizedStrings: localizedStrings, historyDataController: historyDataController, onTapRecord: onTapArticleAction, shareRecordAction: shareArticleAction)
        return viewModel
    }()

    lazy var historyViewController: UIViewController = {
        let historyView = WMFHistoryView(viewModel: historyViewModel)
        return UIHostingController(rootView: historyView)
    }()

    // MARK: - Reading lists hint controller

    private func setupReadingListsHelpers() {
        guard let dataStore else { return }
        readingListHintController = ReadingListHintController(dataStore: dataStore)
        readingListHintController?.apply(theme: theme)

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
        toggleHint(readingListHintController, context: context, presentingIn: presentingVC)
    }

    func visibleHintPresentingViewController() -> (UIViewController & HintPresenting)? {
        if let visibleVC = navigationController?.visibleViewController {
            return visibleVC as? (UIViewController & HintPresenting)
        }
        return nil
    }

    private func toggleHint(_ hintController: ReadingListHintController?, context: [String: Any], presentingIn presentingVC: UIViewController) {

        if let presenting = presentingVC as? (UIViewController & HintPresenting) {
            hintController?.toggle(presenter: presenting, context: context, theme: theme)
        }
    }

    // MARK: - Recent Search Saving
    
    func saveLastSearch() {
        guard
            let term = resultsViewController.resultsInfo?.searchTerm,
            let url = resultsViewController.searchSiteURL,
            let entry = MWKRecentSearchEntry(url: url, searchTerm: term)
        else {
            return
        }
        dataStore?.recentSearchList.addEntry(entry)
        dataStore?.recentSearchList.save()
        reloadRecentSearches()
    }
    
    @objc func makeSearchBarBecomeFirstResponder() {
        if !(navigationItem.searchController?.searchBar.isFirstResponder ?? false) {
            navigationItem.searchController?.searchBar.becomeFirstResponder()
        }
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
    
    // Recent
    
    func updateRecentlySearchedVisibility(searchText: String?) {
        resultsViewController.updateRecentlySearchedVisibility(searchText: searchText)
    }
    
    var recentSearches: MWKRecentSearchList? {
        return self.dataStore?.recentSearchList
    }
    
    func reloadRecentSearches() {
        // TODO: Update SwiftUI recent searches data. This was the old UIKit call.
        // collectionView.reloadData()
    }
    
    // Old UIKit code, keeping for WMFLocalizedStrings generation
    
    //    override func configure(cell: ArticleRightAlignedImageCollectionViewCell, forItemAt indexPath: IndexPath, layoutOnly: Bool) {
    //        cell.articleSemanticContentAttribute = .unspecified
    //        cell.configureForCompactList(at: indexPath.item)
    //        cell.isImageViewHidden = true
    //        cell.apply(theme: theme)
    //        editController.configureSwipeableCell(cell, forItemAt: indexPath, layoutOnly: layoutOnly)
    //        cell.topSeparator.isHidden = indexPath.item == 0
    //        cell.bottomSeparator.isHidden = indexPath.item == self.collectionView(collectionView, numberOfItemsInSection: indexPath.section) - 1
    //        cell.titleLabel.textColor = theme.colors.secondaryText
    //        guard
    //            indexPath.row < countOfRecentSearches,
    //            let entry = recentSearches?.entries[indexPath.item]
    //        else {
    //            cell.titleLabel.text = WMFLocalizedString("search-recent-empty", value: "No recent searches yet", comment: "String for no recent searches available")
    //            return
    //        }
    //        cell.titleLabel.text = entry.searchTerm
    //    }
    
//    override func configure(header: CollectionViewHeader, forSectionAt sectionIndex: Int, layoutOnly: Bool) {
//        header.style = .recentSearches
//        header.apply(theme: theme)
//        header.title = WMFLocalizedString("search-recent-title", value: "Recently searched", comment: "Title for list of recent search terms")
//        header.buttonTitle = countOfRecentSearches > 0 ? WMFLocalizedString("search-clear-title", value: "Clear", comment: "Text of the button shown to clear recent search terms") : nil
//        header.delegate = self
//    }
}

// extension SearchViewController: CollectionViewHeaderDelegate {
//    func collectionViewHeaderButtonWasPressed(_ collectionViewHeader: CollectionViewHeader) {
//        let dialog = UIAlertController(title: WMFLocalizedString("search-recent-clear-confirmation-heading", value: "Delete all recent searches?", comment: "Heading text of delete all confirmation dialog"), message: WMFLocalizedString("search-recent-clear-confirmation-sub-heading", value: "This action cannot be undone!", comment: "Sub-heading text of delete all confirmation dialog"), preferredStyle: .alert)
//        dialog.addAction(UIAlertAction(title: WMFLocalizedString("search-recent-clear-cancel", value: "Cancel", comment: "Button text for cancelling delete all action {{Identical|Cancel}}"), style: .cancel, handler: nil))
//        dialog.addAction(UIAlertAction(title: WMFLocalizedString("search-recent-clear-delete-all", value: "Delete All", comment: "Button text for confirming delete all action {{Identical|Delete all}}"), style: .destructive, handler: { (action) in
//            self.didCancelSearch()
//            self.dataStore.recentSearchList.removeAllEntries()
//            self.dataStore.recentSearchList.save()
//            self.reloadRecentSearches()
//        }))
//        present(dialog, animated: true)
//    }
// }

extension SearchViewController: SearchLanguagesBarViewControllerDelegate {
    func searchLanguagesBarViewController(_ controller: SearchLanguagesBarViewController, didChangeSelectedSearchContentLanguageCode contentLanguageCode: String) {
        SearchFunnel.shared.logSearchLangSwitch(source: source.stringValue, assignment: articleSearchBarExperimentAssignment)
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
        
        // Prevents unnecessary searching & flashing
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
        
        // There's an annoying jump on the history layout during the search bar display animation. Hiding it entirely before the animation starts looks a little better.
        if isSearchTab {
            historyViewController.view.isHidden = true
        }
        needsAnimateLanguageBarMovement = true
        navigationController?.hidesBarsOnSwipe = false
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        if isSearchTab {
            historyViewController.view.isHidden = false
        }
        needsAnimateLanguageBarMovement = true
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        needsAnimateLanguageBarMovement = false
        navigationController?.hidesBarsOnSwipe = true
    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        navigationController?.popViewController(animated: true)
    }
}

// Keep
// WMFLocalizedStringWithDefaultValue(@"search-did-you-mean", nil, nil, @"Did you mean %1$@?", @"Button text for searching for an alternate spelling of the search term. Parameters: * %1$@ - alternate spelling of the search term the user entered - ie if user types 'thunk' the API can suggest the alternate term 'think'")

// LogoutCoordinatorDelegate

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
