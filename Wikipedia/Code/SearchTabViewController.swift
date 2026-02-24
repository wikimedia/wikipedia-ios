import UIKit
import WMFComponents
import WMFData
import CocoaLumberjackSwift
import SwiftUI
import Combine

/// Root view controller for the Search tab. It owns a `WMFHistoryHostingController` which is shown
/// when the search controller is inactive, and uses `SearchResultsViewController` as its
/// `navigationItem.searchController.searchResultsController`.
class SearchTabViewController: ThemeableViewController, WMFNavigationBarConfiguring, MEPEventsProviding, HintPresenting, ShareableArticlesProvider {

    // MARK: - MEP / Hint

    var hintController: HintController?
    var eventLoggingCategory: EventCategoryMEP { .history }
    var eventLoggingLabel: EventLabelMEP? { nil }

    // MARK: - Dependencies

    @objc var dataStore: MWKDataStore? {
        didSet {
            searchResultsContainer.resultsViewController.dataStore = dataStore
        }
    }

    // MARK: - Private state

    private var isSearchActive = false
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Coordinators

    private var _yirCoordinator: YearInReviewCoordinator?
    private var yirCoordinator: YearInReviewCoordinator? {
        guard let navigationController, let yirDataController, let dataStore else { return nil }
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
        guard let navigationController, let yirCoordinator, let dataStore else { return nil }
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
        guard let self, let nav = navigationController, let dataStore else { return nil }
        return TabsOverviewCoordinator(navigationController: nav, theme: theme, dataStore: dataStore)
    }()

    private var yirDataController: WMFYearInReviewDataController? { try? WMFYearInReviewDataController() }

    // MARK: - Delete button (shown leading when history is visible)

    private lazy var deleteButton: UIBarButtonItem = {
        UIBarButtonItem(
            title: CommonStrings.clearTitle,
            style: .plain,
            target: self,
            action: #selector(deleteButtonPressed(_:))
        )
    }()

    // MARK: - Search results container

    lazy var searchResultsContainer: SearchResultsViewController = {
        let container = SearchResultsViewController(source: .searchTab, dataStore: dataStore ?? MWKDataStore.shared())
        container.apply(theme: theme)
        container.parentSearchControllerDelegate = self
        container.populateSearchBarAction = { [weak self] searchTerm in
            self?.navigationItem.searchController?.searchBar.text = searchTerm
            self?.navigationItem.searchController?.searchBar.becomeFirstResponder()
        }
        container.articleTappedAction = { [weak self] articleURL in
            guard let self, let dataStore, let navVC = navigationController else { return }
            let coordinator = LinkCoordinator(
                navigationController: navVC,
                url: articleURL,
                dataStore: dataStore,
                theme: theme,
                articleSource: .search,
                tabConfig: .appendArticleAndAssignCurrentTab
            )
            if !coordinator.start() {
                navigate(to: articleURL)
            }
        }
        return container
    }()

    // MARK: - History

    lazy var historyDataController: WMFHistoryDataController = {
        let recordsProvider: WMFHistoryDataController.RecordsProvider = { [weak self] in
            guard let self, let dataStore else { return [] }

            let request: NSFetchRequest<WMFArticle> = WMFArticle.fetchRequest()
            request.predicate = NSPredicate(format: "viewedDate != NULL")
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \WMFArticle.viewedDateWithoutTime, ascending: false),
                NSSortDescriptor(keyPath: \WMFArticle.viewedDate, ascending: false)
            ]
            request.fetchLimit = 1000

            do {
                return try dataStore.viewContext.fetch(request).compactMap { article -> HistoryRecord? in
                    guard let viewedDate = article.viewedDate, let pageID = article.pageID else { return nil }
                    let thumbnailWidth = ImageUtils.listThumbnailWidth()
                    return HistoryRecord(
                        id: Int(truncating: pageID),
                        title: article.displayTitle ?? article.displayTitleHTML,
                        descriptionOrSnippet: article.capitalizedWikidataDescriptionOrSnippet,
                        shortDescription: article.snippet,
                        articleURL: article.url,
                        imageURL: article.imageURL(forWidth: thumbnailWidth)?.absoluteString,
                        viewedDate: viewedDate,
                        isSaved: article.isSaved,
                        snippet: article.snippet,
                        variant: article.variant
                    )
                }
            } catch {
                DDLogError("Error fetching history: \(error)")
                return []
            }
        }

        let deleteRecordAction: WMFHistoryDataController.DeleteRecordAction = { [weak self] historyItem in
            guard let self, let dataStore else { return }
            guard let databaseKey = historyItem.url?.wmf_databaseKey else { return }
            let request: NSFetchRequest<WMFArticle> = WMFArticle.fetchRequest()
            request.predicate = NSPredicate(format: "key == %@", databaseKey)
            request.fetchLimit = 1
            do {
                if let article = try dataStore.viewContext.fetch(request).first {
                    try article.removeFromReadHistory()
                }
            } catch {
                showError(error)
            }

            guard let title = historyItem.url?.wmf_title,
                  let languageCode = historyItem.url?.wmf_languageCode else { return }
            let project = WMFProject.wikipedia(WMFLanguage(languageCode: languageCode, languageVariantCode: historyItem.variant))
            Task {
                do {
                    let dc = try WMFPageViewsDataController()
                    try await dc.deletePageView(title: title, namespaceID: 0, project: project)
                } catch {
                    DDLogError("Failure deleting WMFData WMFPageViews: \(error)")
                }
            }
        }

        let saveArticleAction: WMFHistoryDataController.SaveRecordAction = { [weak self] historyItem in
            guard let self, let dataStore, let articleURL = historyItem.url else { return }
            dataStore.savedPageList.addSavedPage(with: articleURL)
            NotificationCenter.default.addObserver(self, selector: #selector(userDidSaveOrUnsaveArticle(_:)),
                                                   name: WMFReadingListsController.userDidSaveOrUnsaveArticleNotification, object: nil)
            historyItem.isSaved = true
        }

        let unsaveArticleAction: WMFHistoryDataController.UnsaveRecordAction = { [weak self] historyItem in
            guard let self, let dataStore, let articleURL = historyItem.url else { return }
            dataStore.savedPageList.removeEntry(with: articleURL)
            NotificationCenter.default.addObserver(self, selector: #selector(userDidSaveOrUnsaveArticle(_:)),
                                                   name: WMFReadingListsController.userDidSaveOrUnsaveArticleNotification, object: nil)
            historyItem.isSaved = false
        }

        let dc = WMFHistoryDataController(recordsProvider: recordsProvider)
        dc.deleteRecordAction = deleteRecordAction
        dc.saveRecordAction = saveArticleAction
        dc.unsaveRecordAction = unsaveArticleAction
        return dc
    }()

    lazy var historyViewModel: WMFHistoryViewModel = {
        let strings = WMFHistoryViewModel.LocalizedStrings(
            emptyViewTitle: CommonStrings.emptyNoHistoryTitle,
            emptyViewSubtitle: CommonStrings.emptyNoHistorySubtitle,
            todayTitle: CommonStrings.todayTitle,
            yesterdayTitle: CommonStrings.yesterdayTitle,
            openArticleActionTitle: "Open article",
            saveForLaterActionTitle: CommonStrings.saveTitle,
            unsaveActionTitle: CommonStrings.unsaveTitle,
            shareActionTitle: CommonStrings.shareMenuTitle,
            deleteSwipeActionLabel: CommonStrings.deleteActionTitle,
            historyHeaderTitle: CommonStrings.historyTabTitle
        )
        let vm = WMFHistoryViewModel(
            emptyViewImage: UIImage(named: "history-blank"),
            localizedStrings: strings,
            historyDataController: historyDataController
        )
        vm.onTapArticle = { [weak self] historyItem in
            self?.tappedHistoryArticle(historyItem)
        }
        vm.shareRecordAction = { [weak self] frame, historyItem in
            self?.share(item: historyItem, frame: frame)
        }
        return vm
    }()

    private func tappedHistoryArticle(_ item: HistoryItem) {
        guard let articleURL = item.url, let dataStore, let navVC = navigationController else { return }
        let coordinator = ArticleCoordinator(navigationController: navVC, articleURL: articleURL, dataStore: dataStore, theme: theme, source: .history)
        coordinator.start()
    }

    private func share(item: HistoryItem, frame: CGRect?) {
        guard let dataStore, let url = item.url else { return }
        let article = dataStore.fetchArticle(with: url)
        let dummyView = UIView(frame: frame ?? .zero)
        _ = share(article: article, articleURL: url, dataStore: dataStore, theme: theme, eventLoggingCategory: eventLoggingCategory, eventLoggingLabel: eventLoggingLabel, sourceView: dummyView)
    }

    lazy var historyViewController: WMFHistoryHostingController = {
        WMFHistoryHostingController(rootView: WMFHistoryView(viewModel: historyViewModel))
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Embed history as the background view (always present, shown/hidden via alpha or isHidden)
        addChild(historyViewController)
        historyViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(historyViewController.view)
        NSLayoutConstraint.activate([
            historyViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            historyViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            historyViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            historyViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        historyViewController.disableContentInsetAdjustments()
        historyViewController.didMove(toParent: self)

        setupReadingListsHelpers()

        historyViewModel.$isEmpty
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                Task { @MainActor in self?.refreshDeleteButtonState() }
            }
            .store(in: &cancellables)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NSUserActivity.wmf_makeActive(NSUserActivity.wmf_searchView())
        SearchFunnel.shared.logSearchStart(source: SearchResultsViewController.EventLoggingSource.searchTab.stringValue)
        ArticleTabsFunnel.shared.logIconImpression(interface: .search, project: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let topSafeAreaHeight = view.safeAreaInsets.top
        let bottomSafeAreaHeight = view.safeAreaInsets.bottom
        historyViewModel.topPadding = topSafeAreaHeight
        historyViewModel.bottomPadding = bottomSafeAreaHeight
    }

    // MARK: - Navigation Bar

    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: CommonStrings.searchTitle, customView: nil, alignment: .leadingCompact)

        var profileButtonConfig: WMFNavigationBarProfileButtonConfig? = nil
        var tabsButtonConfig: WMFNavigationBarTabsButtonConfig? = nil

        if let dataStore {
            profileButtonConfig = self.profileButtonConfig(target: self, action: #selector(userDidTapProfile), dataStore: dataStore, yirDataController: yirDataController, leadingBarButtonItem: nil)

            let leadingItem: UIBarButtonItem? = isSearchActive ? nil : deleteButton
            tabsButtonConfig = self.tabsButtonConfig(target: self, action: #selector(userDidTapTabs), dataStore: dataStore, leadingBarButtonItem: leadingItem)
        }

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
            profileButtonConfig: profileButtonConfig,
            tabsButtonConfig: tabsButtonConfig,
            searchBarConfig: searchConfig,
            hideNavigationBarOnScroll: !isSearchActive
        )
    }

    @MainActor
    private func refreshDeleteButtonState() {
        let enabled = !isSearchActive && !historyViewModel.isEmpty
        deleteButton.isEnabled = enabled
        configureNavigationBar()
    }

    private func updateProfileButton() {
        guard let dataStore else { return }
        let config = self.profileButtonConfig(target: self, action: #selector(userDidTapProfile), dataStore: dataStore, yirDataController: yirDataController, leadingBarButtonItem: nil)
        updateNavigationBarProfileButton(needsBadge: config.needsBadge, needsBadgeLabel: CommonStrings.profileButtonBadgeTitle, noBadgeLabel: CommonStrings.profileButtonTitle)
    }

    @objc private func userDidTapProfile() {
        guard let dataStore else { return }
        guard let languageCode = dataStore.languageLinkController.appLanguage?.languageCode,
              let metricsID = DonateCoordinator.metricsID(for: .searchProfile, languageCode: languageCode) else { return }
        DonateFunnel.shared.logSearchProfile(metricsID: metricsID)
        profileCoordinator?.start()
    }

    @objc private func userDidTapTabs() {
        tabsCoordinator?.start()
        ArticleTabsFunnel.shared.logIconClick(interface: .search, project: nil)
    }

    @objc private func deleteButtonPressed(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(
            title: WMFLocalizedString("history-clear-confirmation-heading", value: "Are you sure you want to delete all your recent items?", comment: "Heading text of delete all confirmation dialog"),
            message: nil,
            preferredStyle: .actionSheet
        )
        alertController.addAction(UIAlertAction(
            title: WMFLocalizedString("history-clear-delete-all", value: "Yes, delete all", comment: "Button text for confirming delete all action"),
            style: .destructive) { [weak self] _ in self?.deleteAll() }
        )
        alertController.addAction(UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel))
        alertController.popoverPresentationController?.barButtonItem = sender
        alertController.popoverPresentationController?.permittedArrowDirections = .any
        present(alertController, animated: true)
    }

    private func deleteAll() {
        guard let dataStore else { return }
        do {
            try dataStore.viewContext.clearReadHistory()
            historyViewModel.sections = []
        } catch {
            showError(error)
        }
        Task {
            do {
                let dc = try WMFPageViewsDataController()
                try await dc.deleteAllPageViewsAndCategories()
            } catch {
                DDLogError("Failure deleting WMFData WMFPageViews: \(error)")
            }
        }
    }

    // MARK: - Public interface for WMFAppViewController

    @objc func makeSearchBarBecomeFirstResponder() {
        guard !(navigationItem.searchController?.searchBar.isFirstResponder ?? false) else { return }
        navigationItem.searchController?.searchBar.becomeFirstResponder()
    }

    @objc func searchAndMakeResultsVisibleForSearchTerm(_ term: String?, animated: Bool) {
        navigationItem.searchController?.isActive = true
        navigationItem.searchController?.searchBar.text = term
        searchResultsContainer.searchAndMakeResultsVisible(for: term)
        navigationItem.searchController?.searchBar.becomeFirstResponder()
    }

    // MARK: - Reading Lists Hint

    private func setupReadingListsHelpers() {
        guard let dataStore else { return }
        hintController = ReadingListHintController(dataStore: dataStore)
        hintController?.apply(theme: theme)
        NotificationCenter.default.addObserver(self, selector: #selector(userDidSaveOrUnsaveArticle(_:)),
                                               name: WMFReadingListsController.userDidSaveOrUnsaveArticleNotification, object: nil)
    }

    @objc private func userDidSaveOrUnsaveArticle(_ notification: Notification) {
        guard let article = notification.object as? WMFArticle else { return }
        guard let presentingVC = visibleHintPresentingViewController() else { return }
        let context: [String: Any] = [ReadingListHintController.ContextArticleKey: article]
        hintController?.toggle(presenter: presentingVC, context: context, theme: theme)
    }

    func visibleHintPresentingViewController() -> (UIViewController & HintPresenting)? {
        if let nav = tabBarController?.selectedViewController as? UINavigationController {
            return nav.topViewController as? (UIViewController & HintPresenting)
        }
        return nil
    }

    // MARK: - Theme

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else { return }
        view.backgroundColor = theme.colors.paperBackground
        historyViewController.view.backgroundColor = theme.colors.paperBackground
        searchResultsContainer.apply(theme: theme)
        updateProfileButton()
        profileCoordinator?.theme = theme
        yirCoordinator?.theme = theme
    }
}

// MARK: - UISearchControllerDelegate

extension SearchTabViewController: UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
        isSearchActive = true
        navigationController?.hidesBarsOnSwipe = false
        historyViewController.view.isHidden = true
        configureNavigationBar()
    }

    func didPresentSearchController(_ searchController: UISearchController) {
        // no-op; keyboard is managed by UISearchController automatically
    }

    func willDismissSearchController(_ searchController: UISearchController) {
        // no-op
    }

    func didDismissSearchController(_ searchController: UISearchController) {
        isSearchActive = false
        navigationController?.hidesBarsOnSwipe = true
        historyViewController.view.isHidden = false
        searchResultsContainer.resetSearchResults()
        SearchFunnel.shared.logSearchCancel(source: SearchResultsViewController.EventLoggingSource.searchTab.stringValue)
        Task { @MainActor in refreshDeleteButtonState() }
        configureNavigationBar()
    }
}

// MARK: - LogoutCoordinatorDelegate

extension SearchTabViewController: LogoutCoordinatorDelegate {
    func didTapLogout() {
        guard let dataStore else { return }
        wmf_showKeepSavedArticlesOnDevicePanelIfNeeded(triggeredBy: .logout, theme: theme) {
            dataStore.authenticationManager.logout(initiatedBy: .user)
        }
    }
}

// MARK: - YearInReviewBadgeDelegate

extension SearchTabViewController: YearInReviewBadgeDelegate {
    func updateYIRBadgeVisibility() {
        updateProfileButton()
    }
}
