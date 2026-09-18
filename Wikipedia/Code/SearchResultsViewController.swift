import UIKit
import WMF
import WMFNativeLocalizations
import WMFComponents
import WMFData
import CocoaLumberjackSwift
import SwiftUI

// Protocol that any parent view controller that sets SearchResultsViewController as its navigationItem.searchResultsController should conform to. It ensures search cancel logging happens properly.
// Conformers to this class should properly set this flag in their viewWillDisappear methods.
protocol SearchResultsHosting {
    var disableSearchCancelLogging: Bool { get }
}

/// This class is designed to be used exclusively as a `UISearchController.searchResultsController`.
class SearchResultsViewController: ThemeableViewController, WMFNavigationBarConfiguring, MEPEventsProviding, ShareableArticlesProvider {

    // MARK: - Event Logging Source

    @objc enum EventLoggingSource: Int {
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

    var eventLoggingCategory: EventCategoryMEP { .history }
    var eventLoggingLabel: EventLabelMEP? { nil }

    // MARK: - Public configuration

    typealias NeedsNewTab = Bool
    
    /// Called whenever a search result row or long-press result is tapped. Caller is responsible
    /// for navigating to the given URL.
    var articleTappedAction: ((URL, NeedsNewTab) -> Void)?

    /// Called when the user selects a recently-searched term so the parent can write the text into
    /// its own search bar and activate it.
    var populateSearchBarAction: ((String) -> Void)?

    /// Controls whether the language picker bar is shown at the top of this VC.
    var showLanguageBar: Bool = true {
        didSet {
            guard isViewLoaded else { return }
            updateLanguageBarVisibility()
        }
    }

    // MARK: - Private properties

    let source: EventLoggingSource
    let dataStore: MWKDataStore

    /// Parent view controllers that need their own `UISearchControllerDelegate` callbacks should set
    /// this property. `SearchResultsViewController` will handle all iPad 26 search-UI workarounds
    /// and then forward every delegate call to the parent.
    weak var parentSearchControllerDelegate: UISearchControllerDelegate?

    private lazy var searchBarIPadCustomizer: SearchBarIPadCustomizer = {
        let customizer = SearchBarIPadCustomizer(theme: theme)
        customizer.onClearTapped = { [weak self] _ in self?.resetSearchResults() }
        customizer.onWillDismiss = { [weak self] in
            guard let self else { return }
            resetSearchResults()
        }
        return customizer
    }()

    private let contentContainerView = UIView()
    private weak var currentEmbeddedViewController: UIViewController?

    private var searchLanguageBarViewController: SearchLanguagesBarViewController?
    private var needsAnimateLanguageBarMovement = false

    private var searchTerm: String?
    private var lastSearchSiteURL: URL?
    private var _siteURL: URL?
    private var searchTask: Task<Void, Never>?

    var focusesFirstResultWhenKeyboardHides = false
    var displayedSearchTerm: String?
    var displayedSiteURL: URL?
    var searchResultsByArticleURL: [String: MWKSearchResult] = [:]

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

        updateLanguageBarVisibility()
        reloadRecentSearches()
        showRecentSearches(animated: false)
        NotificationCenter.default.addObserver(self, selector: #selector(articleWasUpdated(_:)), name: .WMFArticleUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(_:)), name: UIResponder.keyboardDidHideNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateLanguageBarVisibility()
        reloadRecentSearches()
        SearchFunnel.shared.logSearchStart(source: source.stringValue)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let languagesBarHeight = searchLanguageBarViewController?.view.bounds.height ?? 0
        recentSearchesViewModel.topPadding = languagesBarHeight
        resultsViewModel.topPadding = languagesBarHeight
        resultsViewModel.horizontalPadding = max(view.layoutMargins.left, round((view.bounds.width - view.readableContentGuide.layoutFrame.width) / 2))
        applyScrollEdgeEffect(isLanguageBarVisible: searchLanguageBarViewController != nil, to: contentScrollViews)
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

    // MARK: - Language bar scroll edge fade

    private var contentScrollViews: [UIScrollView] {
        // Both children are SwiftUI hosting controllers; fish out their inner scroll views.
        [resultsViewController, recentSearchesViewController].compactMap {
            $0.view.firstDescendant(ofType: UIScrollView.self)
        }
    }

    /// On iOS 26+ this uses the system `UIScrollEdgeEffect` which integrates natively
    /// with Liquid Glass. On older OS versions it is a no-op.
    private func applyScrollEdgeEffect(isLanguageBarVisible: Bool, to scrollViews: [UIScrollView]) {
        guard #available(iOS 26, *) else { return }
        let style: UIScrollEdgeEffect.Style = isLanguageBarVisible ? .hard : .automatic
        for scrollView in scrollViews {
            scrollView.topEdgeEffect.style = style
        }
    }

    // MARK: - Language bar

    // VoiceOver orders sibling views by frame origin. The content container starts at the top edge
    // and covers the language bar, so without an explicit order the bar comes after the last result.
    private func updateAccessibilityElements() {
        guard let languageBarView = searchLanguageBarViewController?.view else {
            view.accessibilityElements = nil
            return
        }
        view.accessibilityElements = [languageBarView, contentContainerView]
    }

    private func setupLanguageBarViewController() -> SearchLanguagesBarViewController {
        if let vc = self.searchLanguageBarViewController { return vc }
        let vc = SearchLanguagesBarViewController()
        vc.apply(theme: theme)
        vc.delegate = self
        self.searchLanguageBarViewController = vc
        return vc
    }

    private func updateLanguageBarVisibility() {
        let shouldShow = showLanguageBar && WMFSettingsDataController.shared.showSearchLanguageBar()

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
            applyScrollEdgeEffect(isLanguageBarVisible: true, to: contentScrollViews)
            updateAccessibilityElements()

        } else if !shouldShow, let vc = searchLanguageBarViewController {
            vc.willMove(toParent: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParent()
            self.searchLanguageBarViewController = nil
            self.searchLanguageBarTopConstraint = nil
            applyScrollEdgeEffect(isLanguageBarVisible: false, to: contentScrollViews)
            updateAccessibilityElements()
        }

        view.setNeedsLayout()
        
        MoreLanguagesTip.searchLanguagesBarIsVisible = shouldShow
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
        hideEntryPointIfLanguageChanged(for: siteURL)
        searchTask = Task { [weak self] in
            await self?.performSearch(for: searchTerm, siteURL: siteURL, suggested: suggested)
        }
    }

    private func performSearch(for searchTerm: String, siteURL: URL, suggested: Bool) async {
        guard !Task.isCancelled else { return }
        
        let start = Date()
        do {
            let (results, type) = try await resultsLoader.fetchResults(for: searchTerm, siteURL: siteURL)
            guard !Task.isCancelled else { return }
            NSUserActivity.wmf_makeActive(NSUserActivity.wmf_searchResultsActivitySearchSiteURL(siteURL, searchTerm: searchTerm))
            displaySearchResults(results, siteURL: siteURL)
            guard !suggested else { return }
            SearchFunnel.shared.logSearchResults(with: type, resultCount: results.results?.count ?? 0, elapsedTime: Date().timeIntervalSince(start), source: source.stringValue)
        } catch is CancellationError {
            return
        } catch let SearchResultsLoader.Failure.fetch(error, type) {
            guard !Task.isCancelled, !(error as NSError).wmf_isCancelledError() else { return }
            displaySearchError(error)
            SearchFunnel.shared.logShowSearchError(with: type, elapsedTime: Date().timeIntervalSince(start), source: source.stringValue)
        } catch {
            assertionFailure("Unexpected search error: \(error)")
        }
    }

    private lazy var fetcher = WMFSearchFetcher()
    private lazy var resultsLoader = SearchResultsLoader(fetcher: fetcher)

    func resetSearchResults() {
        searchTask?.cancel()
        searchTask = nil
        fetcher.cancelAllFetches()
        resultsViewModel.reset()
    }

    func didCancelSearch() {
        resetSearchResults()
        resultsViewModel.hideEntryPoint()
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
            let term = displayedSearchTerm,
            let url = displayedSiteURL,
            let entry = MWKRecentSearchEntry(url: url, searchTerm: term)
        else { return }
        dataStore.recentSearchList.addEntry(entry)
        dataStore.recentSearchList.save()
        reloadRecentSearches()
    }

    // MARK: - Child VCs

    lazy var resultsViewModel: WMFSearchResultsViewModel = makeResultsViewModel()

    private lazy var resultsViewController: UIViewController = {
        let root = WMFSearchResultsView(viewModel: resultsViewModel)
        return UIHostingController(rootView: root)
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
        let deleteAction = UIAlertAction(title: CommonStrings.deleteAllTitle, style: .destructive) { _ in
            self?.deleteAllRecentSearches()
        }
        deleteAction.accessibilityIdentifier = AccessibilityIdentifiers.Search.clearRecentSearchesConfirmButton
        dialog.addAction(deleteAction)
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

    // MARK: - Theme

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        searchBarIPadCustomizer.theme = theme
        overrideUserInterfaceStyle = theme.isDark ? .dark : .light
        guard viewIfLoaded != nil else { return }
        view.backgroundColor = theme.colors.paperBackground
        contentContainerView.backgroundColor = theme.colors.paperBackground
        recentSearchesViewController.view.backgroundColor = theme.colors.paperBackground
        searchLanguageBarViewController?.apply(theme: theme)
        resultsViewController.view.backgroundColor = theme.colors.paperBackground
    }
}

// MARK: - UISearchResultsUpdating

extension SearchResultsViewController: UISearchResultsUpdating {
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
            searchTerm = nil
            resetSearchResults()
            resultsViewModel.hideEntryPoint()
            showRecentSearches(animated: true)
        }

        // iPad 26 (regular width): keep the custom clear button in sync with text presence.
        searchBarIPadCustomizer.updateClearButtonVisibility(text: text, for: searchController)
    }
}

// MARK: - UISearchControllerDelegate

/// `SearchResultsViewController` owns the `UISearchControllerDelegate` conformance so that every
/// caller automatically gets the iPad 26 workarounds (custom back / clear buttons, search-field
/// reset on dismiss) without duplicating the logic. Parent view controllers that need their own
/// delegate callbacks should assign themselves to `parentSearchControllerDelegate`.
extension SearchResultsViewController: UISearchControllerDelegate {

    func willPresentSearchController(_ searchController: UISearchController) {
        searchBarIPadCustomizer.willPresentSearchController(searchController)
        parentSearchControllerDelegate?.willPresentSearchController?(searchController)
    }

    func willDismissSearchController(_ searchController: UISearchController) {
        searchBarIPadCustomizer.willDismissSearchController(searchController)
        parentSearchControllerDelegate?.willDismissSearchController?(searchController)
        if let searchHoster = self.presentingViewController as? SearchResultsHosting {
            if !searchHoster.disableSearchCancelLogging { // Avoid cancel logging if search dismissal is due to navigating away
                SearchFunnel.shared.logSearchCancel(source: source.stringValue)
            }
        }
    }

    func didPresentSearchController(_ searchController: UISearchController) {
        searchBarIPadCustomizer.didPresentSearchController(searchController)
        parentSearchControllerDelegate?.didPresentSearchController?(searchController)
    }

    func didDismissSearchController(_ searchController: UISearchController) {
        searchBarIPadCustomizer.didDismissSearchController(searchController)
        parentSearchControllerDelegate?.didDismissSearchController?(searchController)
    }
}

// MARK: - SearchLanguagesBarViewControllerDelegate

extension SearchResultsViewController: SearchLanguagesBarViewControllerDelegate {
    func searchLanguagesBarViewController(_ controller: SearchLanguagesBarViewController, didChangeSelectedSearchContentLanguageCode contentLanguageCode: String) {
        SearchFunnel.shared.logSearchLangSwitch(source: source.stringValue)
        search()
    }
}
