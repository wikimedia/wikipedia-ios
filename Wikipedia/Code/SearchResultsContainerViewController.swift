import UIKit
import WMFComponents
import WMFData
import CocoaLumberjackSwift
import SwiftUI

/// A container view controller that acts exclusively as a `UISearchController.searchResultsController`.
/// It listens for search text changes via `UISearchResultsUpdating`, showing either the recently-searched
/// view (empty text) or live search results (non-empty text). All article-tap navigation is delegated
/// outward via `articleTappedAction`; the class itself never pushes or presents.
class SearchResultsContainerViewController: ThemeableViewController, WMFNavigationBarConfiguring, HintPresenting, ShareableArticlesProvider {

    // MARK: - Event Logging Source

    enum EventLoggingSource {
        case searchTab
        case topOfFeed
        case article
        case unknown

        var stringValue: String {
            switch self {
            case .article: return "article"
            case .topOfFeed: return "top_of_feed"
            case .searchTab: return "search_tab"
            case .unknown: return "unknown"
            }
        }
    }

    // MARK: - HintPresenting

    var hintController: HintController?

    var eventLoggingCategory: EventCategoryMEP { .history }
    var eventLoggingLabel: EventLabelMEP? { nil }

    // MARK: - Public configuration

    /// Called whenever a search result row or long-press result is tapped. The caller is responsible
    /// for navigating to the given URL. Never nil in production; left optional for testability.
    var articleTappedAction: ((URL) -> Void)?

    /// Called when the user selects a recently-searched term so the parent can write the text into
    /// its own search bar and activate it.
    var populateSearchBarAction: ((String) -> Void)?

    /// Controls whether the language picker bar is shown at the top of this VC.
    /// Defaults to `true`. Set to `false` for contexts like InsertLinkViewController.
    var showLanguageBar: Bool = true {
        didSet {
            guard isViewLoaded else { return }
            updateLanguageBarVisibility()
        }
    }

    // MARK: - Private properties

    private let source: EventLoggingSource
    private let dataStore: MWKDataStore

    private let contentContainerView = UIView()
    private weak var currentEmbeddedViewController: UIViewController?

    private var searchLanguageBarViewController: SearchLanguagesBarViewController?
    private var needsAnimateLanguageBarMovement = false

    private var searchTerm: String?
    private var lastSearchSiteURL: URL?
    private var _siteURL: URL?
    private var searchTask: Task<Void, Never>?

    var siteURL: URL? {
        get {
            _siteURL ?? searchLanguageBarViewController?.selectedSiteURL ?? MWKDataStore.shared().primarySiteURL ?? NSURL.wmf_URLWithDefaultSiteAndCurrentLocale()
        }
        set { _siteURL = newValue }
    }

    var searchLanguageBarTopConstraint: NSLayoutConstraint?

    // MARK: - Init

    init(source: EventLoggingSource, dataStore: MWKDataStore) {
        self.source = source
        self.dataStore = dataStore
        super.init(nibName: nil, bundle: nil)
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        searchTask?.cancel()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(contentContainerView)
        contentContainerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            contentContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        setupReadingListsHelpers()
        updateLanguageBarVisibility()
        reloadRecentSearches()
        showRecentSearches(animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateLanguageBarVisibility()
        reloadRecentSearches()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let languagesBarHeight = searchLanguageBarViewController?.view.bounds.height ?? 0
        recentSearchesViewModel.topPadding = languagesBarHeight
        resultsViewController.collectionView.contentInset.top = languagesBarHeight
    }

    // MARK: - Embedded content container

    private func embedInContainer(_ vc: UIViewController, animated: Bool) {
        if currentEmbeddedViewController === vc { return }

        let oldVC = currentEmbeddedViewController
        oldVC?.willMove(toParent: nil)

        addChild(vc)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.addSubview(vc.view)
        NSLayoutConstraint.activate([
            vc.view.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
            vc.view.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            vc.view.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
            vc.view.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor)
        ])

        let finish = {
            oldVC?.view.removeFromSuperview()
            oldVC?.removeFromParent()
            vc.didMove(toParent: self)
            self.currentEmbeddedViewController = vc
        }

        guard animated, let oldView = oldVC?.view else {
            finish()
            return
        }

        vc.view.alpha = 0
        UIView.animate(withDuration: 0.2, animations: {
            vc.view.alpha = 1
            oldView.alpha = 0
        }, completion: { _ in
            oldView.alpha = 1
            finish()
        })
    }

    private func showSearchResults(animated: Bool) {
        embedInContainer(resultsViewController, animated: animated)
    }

    private func showRecentSearches(animated: Bool) {
        embedInContainer(recentSearchesViewController, animated: animated)
    }

    // MARK: - Language bar

    private func setupLanguageBarViewController() -> SearchLanguagesBarViewController {
        if let vc = self.searchLanguageBarViewController { return vc }
        let vc = SearchLanguagesBarViewController()
        vc.apply(theme: theme)
        vc.delegate = self
        self.searchLanguageBarViewController = vc
        return vc
    }

    private func updateLanguageBarVisibility() {
        let shouldShow = showLanguageBar && UserDefaults.standard.wmf_showSearchLanguageBar()

        if shouldShow && searchLanguageBarViewController == nil {
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
            vc.moveScrollViewToStart()
            vc.view.isHidden = false

        } else if !shouldShow, let vc = searchLanguageBarViewController {
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

    func search() {
        search(for: searchTerm, suggested: false)
    }

    private func search(for searchTerm: String?, suggested: Bool) {
        guard let siteURL else {
            assertionFailure("siteURL must not be nil")
            return
        }
        self.lastSearchSiteURL = siteURL

        guard let searchTerm, searchTerm.wmf_hasNonWhitespaceText else {
            didCancelSearch()
            return
        }

        guard (searchTerm as NSString).character(at: 0) != NSTextAttachment.character else { return }

        resetSearchResults()
        let start = Date()

        let failure = { (error: Error, type: WMFSearchType) in
            DispatchQueue.main.async { [weak self] in
                guard let self,
                      searchTerm == self.searchTerm else { return }
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
                self.resultsViewController.emptyViewType = resultsArray.isEmpty ? .noSearchResults : .none
                self.resultsViewController.resultsInfo = results
                self.resultsViewController.searchSiteURL = siteURL
                self.resultsViewController.results = resultsArray
                guard !suggested else { return }
                SearchFunnel.shared.logSearchResults(with: type, resultCount: resultsArray.count, elapsedTime: Date().timeIntervalSince(start), source: self.source.stringValue)
            }
        }

        fetcher.fetchArticles(forSearchTerm: searchTerm, siteURL: siteURL, resultLimit: WMFMaxSearchResultLimit, failure: { error in
            failure(error, .prefix)
        }, success: { [weak self] results in
            guard let self else { return }
            success(results, .prefix)
            guard let resultsArray = results.results, resultsArray.count < 12 else { return }
            self.fetcher.fetchArticles(forSearchTerm: searchTerm, siteURL: siteURL, resultLimit: WMFMaxSearchResultLimit, fullTextSearch: true, appendToPreviousResults: results, failure: { error in
                failure(error, .full)
            }, success: { [weak self] fullTextResults in
                guard self != nil else { return }
                success(fullTextResults, .full)
            })
        })
    }

    private lazy var fetcher = WMFSearchFetcher()

    func resetSearchResults() {
        fetcher.cancelAllFetches()
        resultsViewController.emptyViewType = .none
        resultsViewController.results = []
    }

    func didCancelSearch() {
        resetSearchResults()
    }

    /// Programmatically trigger a search for `term` and show results — used when the caller
    /// sets the search bar text internally without typing (e.g. NSUserActivity restoration).
    func searchAndMakeResultsVisible(for term: String?) {
        guard let term, term.wmf_hasNonWhitespaceText else { return }
        searchTerm = term
        showSearchResults(animated: false)
        search(for: term, suggested: false)
    }

    // MARK: - Recent Search Saving

    func saveLastSearch() {
        guard
            let term = resultsViewController.resultsInfo?.searchTerm,
            let url = resultsViewController.searchSiteURL,
            let entry = MWKRecentSearchEntry(url: url, searchTerm: term)
        else { return }
        dataStore.recentSearchList.addEntry(entry)
        dataStore.recentSearchList.save()
        reloadRecentSearches()
    }

    // MARK: - Child VCs

    lazy var resultsViewController: SearchResultsViewController = {
        let vc = SearchResultsViewController()
        vc.dataStore = dataStore
        vc.apply(theme: theme)

        vc.tappedSearchResultAction = { [weak self] articleURL, indexPath in
            guard let self else { return }
            SearchFunnel.shared.logSearchResultTap(position: indexPath.item, source: self.source.stringValue)
            self.saveLastSearch()
            self.articleTappedAction?(articleURL)
        }

        vc.longPressSearchResultAndCommitAction = { [weak self] articleURL in
            self?.articleTappedAction?(articleURL)
        }

        vc.longPressOpenInNewTabAction = { [weak self] articleURL in
            self?.articleTappedAction?(articleURL)
        }

        return vc
    }()

    private lazy var recentSearchesViewController: UIViewController = {
        let root = WMFRecentlySearchedView(viewModel: recentSearchesViewModel)
        return UIHostingController(rootView: root)
    }()

    // MARK: - Recently Searched

    private var recentSearches: MWKRecentSearchList? { dataStore.recentSearchList }

    private lazy var didPressClearRecentSearches: () -> Void = { [weak self] in
        let dialog = UIAlertController(
            title: CommonStrings.clearRecentSearchesDialogTitle,
            message: CommonStrings.clearRecentSearchesDialogSubtitle,
            preferredStyle: .alert)
        dialog.addAction(UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel))
        dialog.addAction(UIAlertAction(title: CommonStrings.deleteAllTitle, style: .destructive) { _ in
            self?.deleteAllRecentSearches()
        })
        self?.present(dialog, animated: true)
    }

    private func deleteAllRecentSearches() {
        dataStore.recentSearchList.removeAllEntries()
        dataStore.recentSearchList.save()
        reloadRecentSearches()
    }

    private lazy var deleteItemAction: (Int) -> Void = { [weak self] index in
        guard
            let self,
            self.recentSearches?.entries.indices.contains(index) ?? false,
            let entry = self.recentSearches?.entries[index]
        else { return }
        Task {
            self.dataStore.recentSearchList.removeEntry(entry)
            self.dataStore.recentSearchList.save()
            self.reloadRecentSearches()
        }
    }

    private lazy var selectAction: (WMFRecentlySearchedViewModel.RecentSearchTerm) -> Void = { [weak self] term in
        guard let self else { return }
        self.resetSearchResults()
        if let pop = self.populateSearchBarAction {
            pop(term.text)
        }
        self.searchTerm = term.text
        self.search(for: term.text, suggested: false)
    }

    private lazy var recentSearchesViewModel: WMFRecentlySearchedViewModel = {
        let strings = WMFRecentlySearchedViewModel.LocalizedStrings(
            title: CommonStrings.recentlySearchedTitle,
            noSearches: CommonStrings.recentlySearchedEmpty,
            clearAll: CommonStrings.clearTitle,
            deleteActionAccessibilityLabel: CommonStrings.deleteActionTitle,
            editButtonTitle: CommonStrings.editContextMenuTitle
        )
        return WMFRecentlySearchedViewModel(
            recentSearchTerms: currentRecentSearchTerms(),
            topPadding: 0,
            localizedStrings: strings,
            deleteAllAction: didPressClearRecentSearches,
            deleteItemAction: deleteItemAction,
            selectAction: selectAction
        )
    }()

    private func currentRecentSearchTerms() -> [WMFRecentlySearchedViewModel.RecentSearchTerm] {
        (recentSearches?.entries ?? []).map {
            WMFRecentlySearchedViewModel.RecentSearchTerm(text: $0.searchTerm)
        }
    }

    private func reloadRecentSearches() {
        recentSearchesViewModel.recentSearchTerms = currentRecentSearchTerms()
    }

    // MARK: - Reading Lists Hint

    private func setupReadingListsHelpers() {
        hintController = ReadingListHintController(dataStore: dataStore)
        hintController?.apply(theme: theme)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDidSaveOrUnsaveArticle(_:)),
            name: WMFReadingListsController.userDidSaveOrUnsaveArticleNotification,
            object: nil
        )
    }

    @objc private func userDidSaveOrUnsaveArticle(_ notification: Notification) {
        guard let article = notification.object as? WMFArticle else { return }
        guard let presentingVC = visibleHintPresentingViewController() else { return }
        let context: [String: Any] = [ReadingListHintController.ContextArticleKey: article]
        toggleHint(hintController, context: context, presentingIn: presentingVC)
    }

    func visibleHintPresentingViewController() -> (UIViewController & HintPresenting)? {
        if let nav = tabBarController?.selectedViewController as? UINavigationController {
            return nav.topViewController as? (UIViewController & HintPresenting)
        }
        return nil
    }

    private func toggleHint(_ hintController: HintController?, context: [String: Any], presentingIn presentingVC: UIViewController) {
        if let presenting = presentingVC as? (UIViewController & HintPresenting) {
            hintController?.toggle(presenter: presenting, context: context, theme: theme)
        }
    }

    // MARK: - Theme

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else { return }
        view.backgroundColor = theme.colors.paperBackground
        contentContainerView.backgroundColor = theme.colors.paperBackground
        recentSearchesViewController.view.backgroundColor = theme.colors.paperBackground
        searchLanguageBarViewController?.apply(theme: theme)
        resultsViewController.apply(theme: theme)
        hintController?.apply(theme: theme)
    }
}

// MARK: - UISearchResultsUpdating

extension SearchResultsContainerViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let text = searchController.searchBar.text ?? ""
        needsAnimateLanguageBarMovement = false

        if text.wmf_hasNonWhitespaceText {
            showSearchResults(animated: false)

            if let lastSearchSiteURL,
               searchTerm == text,
               lastSearchSiteURL == siteURL {
                return
            }
            searchTerm = text

            searchTask?.cancel()
            searchTask = Task { @MainActor [weak self] in
                guard let self else { return }
                try? await Task.sleep(for: .milliseconds(100))
                guard !Task.isCancelled else { return }
                search(for: text, suggested: false)
            }
        } else {
            searchTask?.cancel()
            searchTask = nil
            searchTerm = nil
            resetSearchResults()
            showRecentSearches(animated: false)
        }
    }
}

// MARK: - SearchLanguagesBarViewControllerDelegate

extension SearchResultsContainerViewController: SearchLanguagesBarViewControllerDelegate {
    func searchLanguagesBarViewController(_ controller: SearchLanguagesBarViewController, didChangeSelectedSearchContentLanguageCode contentLanguageCode: String) {
        SearchFunnel.shared.logSearchLangSwitch(source: source.stringValue)
        search()
    }
}
