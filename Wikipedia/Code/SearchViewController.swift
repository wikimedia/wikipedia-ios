import UIKit

class SearchViewController: ArticleCollectionViewController, UISearchBarDelegate {
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.displayType = displayType
        if !areRecentSearchesEnabled, shouldSetTitleViewWhenRecentSearchesAreDisabled {
            navigationItem.titleView = UIView()
            title = CommonStrings.searchTitle
        }
        navigationBar.isTitleShrinkingEnabled = true
        navigationBar.isShadowHidingEnabled = false
        navigationBar.isBarHidingEnabled = false
        navigationBar.addUnderNavigationBarView(searchBarContainerView)
        view.bringSubviewToFront(resultsViewController.view)
        resultsViewController.view.isHidden = true
        useNavigationBarVisibleHeightForScrollViewInsets = true
    }

    override func viewWillAppear(_ animated: Bool) {
        updateLanguageBarVisibility()
        super.viewWillAppear(animated)
        reloadRecentSearches()
        if animated && shouldBecomeFirstResponder {
            if shouldAdjustNavigationBarInsetHidingOnAppearance {
                navigationBar.isAdjustingHidingFromContentInsetChangesEnabled = false
            }
            searchBar.becomeFirstResponder()
        }

        // Terrible hack to make back button text appropriate for iOS 14 - need to set the title on `WMFAppViewController`. For all app tabs, this is set in `viewWillAppear`.
        if let appVC = parent as? WMFAppViewController {
            appVC.navigationItem.backButtonTitle = title
        } else {
            // If the parent isn't `WMFAppViewController`, then its being presented from an articleVC and we need to set the back button title in the typical way.
            self.navigationItem.backButtonTitle = CommonStrings.searchTitle
            self.navigationItem.backButtonDisplayMode = .generic
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        SearchFunnel.shared.logSearchStart(source: source)
        NSUserActivity.wmf_makeActive(NSUserActivity.wmf_searchView())
        if !animated && shouldBecomeFirstResponder {
            searchBar.becomeFirstResponder()
        }
        navigationBar.isAdjustingHidingFromContentInsetChangesEnabled = true
        shouldAnimateSearchBar = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationBar.isAdjustingHidingFromContentInsetChangesEnabled = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        navigationBar.isAdjustingHidingFromContentInsetChangesEnabled = true
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { (context) in
            self.view.setNeedsLayout()
            self.resultsViewController.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        })
    }
    
    // MARK: - State
    
    var shouldAnimateSearchBar: Bool = true
    var isAnimatingSearchBarState: Bool = false
    
    @objc var areRecentSearchesEnabled: Bool = true
    @objc var shouldBecomeFirstResponder: Bool = false

    var displayType: NavigationBarDisplayType = .largeTitle
    var shouldSetSearchVisible: Bool = true
    var shouldSetTitleViewWhenRecentSearchesAreDisabled: Bool = true
    var shouldScrollToTopOnVisibilityChange = true
    var shouldAdjustNavigationBarInsetHidingOnAppearance = true
    var shouldDisplayIncomingTransitionOverlay: Bool = false {
        didSet {
            incomingTransitionOverlay.isHidden = !shouldDisplayIncomingTransitionOverlay
        }
    }

    var shouldShowCancelButton: Bool = true
    var delegatesSelection: Bool = false {
        didSet {
            resultsViewController.delegatesSelection = delegatesSelection
        }
    }

    var doResultsShowArticlePreviews = true {
        didSet {
            resultsViewController.doesShowArticlePreviews = doResultsShowArticlePreviews
        }
    }

    var showLanguageBar: Bool?

    var searchTerm: String? {
        get {
            return searchBar.text
        }
        set {
            searchBar.text = newValue
        }
    }

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
        shouldAnimateSearchBar = animated
        searchTerm = term
        search(for: searchTerm, suggested: false)
        searchBar.becomeFirstResponder()
    }

    func search() {
        search(for: searchTerm, suggested: false)
    }
    
    private func search(for searchTerm: String?, suggested: Bool) {
        guard let siteURL = siteURL else {
            assert(false)
            return
        }
        
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
        
        let start = Date()
        
        fakeProgressController.start()
    
        let failure = { (error: Error, type: WMFSearchType) in
            DispatchQueue.main.async {
                self.fakeProgressController.stop()
                guard searchTerm == self.searchBar.text else {
                    return
                }
                self.resultsViewController.emptyViewType = (error as NSError).wmf_isNetworkConnectionError() ? .noInternetConnection : .noSearchResults
                self.resultsViewController.results = []
                SearchFunnel.shared.logShowSearchError(with: type, elapsedTime: Date().timeIntervalSince(start), source: self.source)
            }
        }
        
        let success = { (results: WMFSearchResults, type: WMFSearchType) in
            DispatchQueue.main.async {
                guard searchTerm == self.searchBar.text else {
                    return
                }
                NSUserActivity.wmf_makeActive(NSUserActivity.wmf_searchResultsActivitySearchSiteURL(siteURL, searchTerm: searchTerm))
                let resultsArray = results.results ?? []
                self.resultsViewController.emptyViewType = .noSearchResults
                self.fakeProgressController.finish()
                self.resultsViewController.resultsInfo = results
                self.resultsViewController.searchSiteURL = siteURL
                self.resultsViewController.results = resultsArray
                guard !suggested else {
                    return
                }
                SearchFunnel.shared.logSearchResults(with: type, resultCount: Int(resultsArray.count), elapsedTime: Date().timeIntervalSince(start), source: self.source)
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

    private func updateLanguageBarVisibility() {
        let showLanguageBar = self.showLanguageBar ?? UserDefaults.standard.wmf_showSearchLanguageBar()
        if  showLanguageBar && searchLanguageBarViewController == nil { // check this before accessing the view
            let searchLanguageBarViewController = setupLanguageBarViewController()
            addChild(searchLanguageBarViewController)
            searchLanguageBarViewController.view.translatesAutoresizingMaskIntoConstraints = false
            navigationBar.addExtendedNavigationBarView(searchLanguageBarViewController.view)
            searchLanguageBarViewController.didMove(toParent: self)
            searchLanguageBarViewController.view.isHidden = false
        } else if !showLanguageBar && searchLanguageBarViewController != nil {
            searchLanguageBarViewController?.willMove(toParent: nil)
            navigationBar.removeExtendedNavigationBarView()
            searchLanguageBarViewController?.removeFromParent()
            searchLanguageBarViewController = nil
        }
    }
    
    override var headerStyle: ColumnarCollectionViewController.HeaderStyle {
        return .sections
    }

    // MARK: - Search
    
    lazy var fetcher: WMFSearchFetcher = {
       return WMFSearchFetcher()
    }()
    
    func didCancelSearch() {
        resultsViewController.emptyViewType = .none
        resultsViewController.results = []
        searchBar.text = nil
        fakeProgressController.stop()
        SearchFunnel.shared.logSearchCancel(source: source)
    }
    
    @objc func clear() {
        didCancelSearch()
        updateRecentlySearchedVisibility(searchText: searchBar.text)
    }
    
    lazy var searchBarContainerView: UIView = {
        let searchContainerView = UIView()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchContainerView.addSubview(searchBar)
        let leading = searchContainerView.layoutMarginsGuide.leadingAnchor.constraint(equalTo: searchBar.leadingAnchor)
        let trailing = searchContainerView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: searchBar.trailingAnchor)
        let top = searchContainerView.topAnchor.constraint(equalTo: searchBar.topAnchor)
        let bottom = searchContainerView.bottomAnchor.constraint(equalTo: searchBar.bottomAnchor)
        searchContainerView.addConstraints([leading, trailing, top, bottom])
        return searchContainerView
    }()
    
    lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.returnKeyType = .search
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder =  WMFLocalizedString("search-field-placeholder-text", value: "Search Wikipedia", comment: "Search field placeholder text")
        return searchBar
    }()

    let incomingTransitionOverlay = UIView()

    var nonSearchAlpha: CGFloat = 1 {
        didSet {
            incomingTransitionOverlay.alpha = nonSearchAlpha
            resultsViewController.view.alpha = nonSearchAlpha
            navigationBar.backgroundAlpha = nonSearchAlpha
        }
    }

    // used to match the transition with explore
    
    func prepareForIncomingTransition(with incomingNavigationBar: NavigationBar) {
        // Add overlay to hide jarring transition
        view.insertSubview(incomingTransitionOverlay, aboveSubview: resultsViewController.view)
        view.wmf_addConstraintsToEdgesOfView(incomingTransitionOverlay)
        incomingTransitionOverlay.isHidden = true

        navigationBarTopSpacingPercentHidden = incomingNavigationBar.topSpacingPercentHidden
        navigationBarTopSpacing = incomingNavigationBar.barTopSpacing
        navigationBar.isTopSpacingHidingEnabled = true
        navigationBar.barTopSpacing = navigationBarTopSpacing
        navigationBar.topSpacingPercentHidden = navigationBarTopSpacingPercentHidden
        navigationBar.isTopSpacingHidingEnabled = !_isSearchVisible
        navigationBarShadowAlpha = incomingNavigationBar.shadowAlpha
        navigationBar.shadowAlpha = navigationBarShadowAlpha

        shouldDisplayIncomingTransitionOverlay = true
        collectionView.alpha = 0
        view.backgroundColor = .clear
    }
    
    func prepareForOutgoingTransition(with outgoingNavigationBar: NavigationBar) {
        navigationBarTopSpacingPercentHidden = outgoingNavigationBar.topSpacingPercentHidden
        navigationBarShadowAlpha = outgoingNavigationBar.shadowAlpha
        navigationBarTopSpacing = outgoingNavigationBar.barTopSpacing
    }

    func beginTransitionFromExploreFeed(enteringSearch: Bool) {
        nonSearchAlpha = enteringSearch ? 1 : 0
        view.backgroundColor = enteringSearch ? theme.colors.paperBackground : .clear
    }

    func completeTransitionFromExploreFeed(enteringSearch: Bool) {
        collectionView.alpha = 1
        UIView.animate(withDuration: 0.1, animations: {
            if enteringSearch {
                self.incomingTransitionOverlay.alpha = 0
            } else {
                self.incomingTransitionOverlay.alpha = 1
            }
        })
    }
    
    private var navigationBarShadowAlpha: CGFloat = 0
    private var navigationBarTopSpacingPercentHidden: CGFloat = 0
    private var navigationBarTopSpacing: CGFloat = 0

    var searchLanguageBarViewController: SearchLanguagesBarViewController?
    
    override var shouldAnimateWhileUpdatingScrollViewInsets: Bool {
        return isAnimatingSearchBarState
    }

    private var _isSearchVisible: Bool = false
    private func setSearchVisible(_ visible: Bool, animated: Bool) {
        _isSearchVisible = visible
        navigationBar.isAdjustingHidingFromContentInsetChangesEnabled  = false
        let completion = { (finished: Bool) in
            if self.shouldScrollToTopOnVisibilityChange {
                self.collectionView.setContentOffset(.init(x: 0, y: -self.navigationBar.visibleHeight), animated: false)
                UIView.animate(withDuration: 0.1, animations: {
                    self.collectionView.alpha = 1
                })
            }
            self.isAnimatingSearchBarState = false
            self.navigationBar.isTitleShrinkingEnabled = true
            self.navigationBar.isAdjustingHidingFromContentInsetChangesEnabled  = true
        }
        if searchLanguageBarViewController != nil {
            navigationBar.shadowAlpha = 0
        }
        if visible {
            navigationBarTopSpacingPercentHidden = navigationBar.topSpacingPercentHidden
            navigationBarShadowAlpha = navigationBar.shadowAlpha
            navigationBarTopSpacing = navigationBar.barTopSpacing
        }
        let animations = {
            if self.shouldScrollToTopOnVisibilityChange {
                self.collectionView.alpha = 0
            }
            self.navigationBar.isBarHidingEnabled = true
            self.navigationBar.isTopSpacingHidingEnabled = true
            self.navigationBar.isTitleShrinkingEnabled = false
            self.navigationBar.barTopSpacing = self.navigationBarTopSpacing
            self.navigationBar.setNavigationBarPercentHidden(visible ? 1 : 0, underBarViewPercentHidden: 0, extendedViewPercentHidden: 0, topSpacingPercentHidden: visible ? 1 : self.navigationBarTopSpacingPercentHidden, animated: false)
            self.navigationBar.isBarHidingEnabled = false
            self.navigationBar.isTopSpacingHidingEnabled = !visible
            self.navigationBar.shadowAlpha = visible ? 1 : self.searchLanguageBarViewController != nil ? 0 : self.navigationBarShadowAlpha
            if self.shouldShowCancelButton {
                self.searchBar.setShowsCancelButton(visible, animated: animated)
            }
            self.view.layoutIfNeeded()
        }
        guard animated else {
            animations()
            completion(true)
            return
        }
        isAnimatingSearchBarState = true
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.3, animations: animations, completion: completion)
    }
    
    lazy var resultsViewController: SearchResultsViewController = {
        let resultsViewController = SearchResultsViewController()
        resultsViewController.dataStore = dataStore
        resultsViewController.apply(theme: theme)
        resultsViewController.delegate = self
        addChild(resultsViewController)
        view.wmf_addSubviewWithConstraintsToEdges(resultsViewController.view)
        resultsViewController.didMove(toParent: self)
        return resultsViewController
    }()
    
    lazy var fakeProgressController: FakeProgressController = {
        return FakeProgressController(progress: navigationBar, delegate: navigationBar)
    }()
    
    // MARK: - Recent Search Saving
    
    
    func saveLastSearch() {
        guard
            let term = resultsViewController.resultsInfo?.searchTerm,
            let url = resultsViewController.searchSiteURL,
            let entry = MWKRecentSearchEntry(url: url, searchTerm: term)
        else {
            return
        }
        dataStore.recentSearchList.addEntry(entry)
        dataStore.recentSearchList.save()
        reloadRecentSearches()
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        guard !isAnimatingSearchBarState else {
            return false
        }
        if shouldSetSearchVisible {
            setSearchVisible(true, animated: shouldAnimateSearchBar)
        }
        return true
    }

    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        guard !isAnimatingSearchBarState else {
            return false
        }
        
        guard shouldAnimateSearchBar else {
            didClickSearchButton = false
            return true
        }
        
        if didClickSearchButton {
            didClickSearchButton = false
        } else if shouldSetSearchVisible {
            setSearchVisible(false, animated: shouldAnimateSearchBar)
        }
        
        return true
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        updateRecentlySearchedVisibility(searchText: searchText)
        search(for: searchBar.text, suggested: false)
    }

    private var didClickSearchButton = false

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        saveLastSearch()
        didClickSearchButton = true
        searchBar.endEditing(true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if let navigationController = navigationController, navigationController.viewControllers.count > 1 {
            if shouldAnimateSearchBar {
                searchBar.text = nil
            }
            navigationController.popViewController(animated: true)
        } else {
            searchBar.endEditing(true)
            didCancelSearch()
        }
        deselectAll(animated: true)
		updateRecentlySearchedVisibility(searchText: searchBar.text)
    }
    
    @objc func makeSearchBarBecomeFirstResponder() {
        if !searchBar.isFirstResponder {
            searchBar.becomeFirstResponder()
        }
    }

    // MARK: - Theme
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        searchBar.apply(theme: theme)
        searchBarContainerView.backgroundColor = theme.colors.paperBackground
        searchLanguageBarViewController?.apply(theme: theme)
        resultsViewController.apply(theme: theme)
        view.backgroundColor = theme.colors.paperBackground
        collectionView.backgroundColor = theme.colors.paperBackground
        incomingTransitionOverlay.backgroundColor = theme.colors.paperBackground
    }
    
    // Recent

    func updateRecentlySearchedVisibility(searchText: String?) {
		guard let searchText = searchText else {
			resultsViewController.view.isHidden = true
			return
		}

        resultsViewController.view.isHidden = searchText.isEmpty
    }

    var recentSearches: MWKRecentSearchList? {
        return self.dataStore.recentSearchList
    }
    
    func reloadRecentSearches() {
        guard areRecentSearchesEnabled else {
            return
        }
        collectionView.reloadData()
    }

    func deselectAll(animated: Bool) {
        guard let selected = collectionView.indexPathsForSelectedItems else {
            return
        }
        for indexPath in selected {
            collectionView.deselectItem(at: indexPath, animated: animated)
        }
    }
    
    override func articleURL(at indexPath: IndexPath) -> URL? {
        return nil
    }
    
    override func article(at indexPath: IndexPath) -> WMFArticle? {
        return nil
    }
    
    override func canDelete(at indexPath: IndexPath) -> Bool {
        return indexPath.row < countOfRecentSearches // ensures user can't delete the empty state row
    }
    
    override func willPerformAction(_ action: Action) -> Bool {
        return self.editController.didPerformAction(action)
    }
    
    override func delete(at indexPath: IndexPath) {
        guard
            let entries = recentSearches?.entries,
            entries.indices.contains(indexPath.item) else {
            return
        }
        let entry = entries[indexPath.item]
        recentSearches?.removeEntry(entry)
        recentSearches?.save()
        guard countOfRecentSearches > 0 else {
            collectionView.reloadData() // reload instead of deleting the row to get to empty state
            return
        }
        collectionView.performBatchUpdates({
            self.collectionView.deleteItems(at: [indexPath])
        }) { (finished) in
            self.collectionView.reloadData()
        }
    }
    
    var countOfRecentSearches: Int {
        return recentSearches?.entries.count ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard areRecentSearchesEnabled else {
            return 0
        }
        return max(countOfRecentSearches, 1) // 1 for empty state
    }
    
    override func configure(cell: ArticleRightAlignedImageCollectionViewCell, forItemAt indexPath: IndexPath, layoutOnly: Bool) {
        cell.articleSemanticContentAttribute = .unspecified
        cell.configureForCompactList(at: indexPath.item)
        cell.isImageViewHidden = true
        cell.apply(theme: theme)
        editController.configureSwipeableCell(cell, forItemAt: indexPath, layoutOnly: layoutOnly)
        cell.topSeparator.isHidden = indexPath.item == 0
        cell.bottomSeparator.isHidden = indexPath.item == self.collectionView(collectionView, numberOfItemsInSection: indexPath.section) - 1
        cell.titleLabel.textColor = theme.colors.secondaryText
        guard
            indexPath.row < countOfRecentSearches,
            let entry = recentSearches?.entries[indexPath.item]
        else {
            cell.titleLabel.text = WMFLocalizedString("search-recent-empty", value: "No recent searches yet", comment: "String for no recent searches available")
            return
        }
        cell.titleLabel.text = entry.searchTerm
    }
    
    override func configure(header: CollectionViewHeader, forSectionAt sectionIndex: Int, layoutOnly: Bool) {
        header.style = .recentSearches
        header.apply(theme: theme)
        header.title = WMFLocalizedString("search-recent-title", value: "Recently searched", comment: "Title for list of recent search terms")
        header.buttonTitle = countOfRecentSearches > 0 ? WMFLocalizedString("search-clear-title", value: "Clear", comment: "Text of the button shown to clear recent search terms") : nil
        header.delegate = self
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let recentSearch = recentSearches?.entry(at: UInt(indexPath.item)) else {
            return
        }
        updateRecentlySearchedVisibility(searchText: recentSearch.searchTerm)
        collectionView.deselectItem(at: indexPath, animated: true)
        searchBar.text = recentSearch.searchTerm
        searchBar.becomeFirstResponder()
        search()
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let recentSearches = recentSearches, recentSearches.countOfEntries() > 0 else {
            return false
        }
        return true
    }
}

extension SearchViewController: CollectionViewHeaderDelegate {
    func collectionViewHeaderButtonWasPressed(_ collectionViewHeader: CollectionViewHeader) {
        let dialog = UIAlertController(title: WMFLocalizedString("search-recent-clear-confirmation-heading", value: "Delete all recent searches?", comment: "Heading text of delete all confirmation dialog"), message: WMFLocalizedString("search-recent-clear-confirmation-sub-heading", value: "This action cannot be undone!", comment: "Sub-heading text of delete all confirmation dialog"), preferredStyle: .alert)
        dialog.addAction(UIAlertAction(title: WMFLocalizedString("search-recent-clear-cancel", value: "Cancel", comment: "Button text for cancelling delete all action {{Identical|Cancel}}"), style: .cancel, handler: nil))
        dialog.addAction(UIAlertAction(title: WMFLocalizedString("search-recent-clear-delete-all", value: "Delete All", comment: "Button text for confirming delete all action {{Identical|Delete all}}"), style: .destructive, handler: { (action) in
            self.didCancelSearch()
            self.dataStore.recentSearchList.removeAllEntries()
            self.dataStore.recentSearchList.save()
            self.reloadRecentSearches()
        }))
        present(dialog, animated: true)
    }
}

extension SearchViewController: ArticleCollectionViewControllerDelegate {
    func articleCollectionViewController(_ articleCollectionViewController: ArticleCollectionViewController, didSelectArticleWith articleURL: URL, at indexPath: IndexPath) {
        SearchFunnel.shared.logSearchResultTap(position: indexPath.item, source: source)
        saveLastSearch()
        guard delegatesSelection else {
            return
        }
        delegate?.articleCollectionViewController(self, didSelectArticleWith: articleURL, at: indexPath)
    }
}

extension SearchViewController: SearchLanguagesBarViewControllerDelegate {
    func searchLanguagesBarViewController(_ controller: SearchLanguagesBarViewController, didChangeSelectedSearchContentLanguageCode contentLanguageCode: String) {
        SearchFunnel.shared.logSearchLangSwitch(source: source)
        search()
    }
}

// MARK: - Event logging
extension SearchViewController {
    private var source: String {
        guard let navigationController = navigationController, !navigationController.viewControllers.isEmpty else {
            return "unknown"
        }
        let viewControllers = navigationController.viewControllers
        let viewControllersCount = viewControllers.count
        if viewControllersCount == 1 {
            return "search_tab"
        } else if viewControllersCount == 2 {
            return "top_of_feed"
        } else {
            return "article"
        }
    }
}

// Keep
// WMFLocalizedStringWithDefaultValue(@"search-did-you-mean", nil, nil, @"Did you mean %1$@?", @"Button text for searching for an alternate spelling of the search term. Parameters: * %1$@ - alternate spelling of the search term the user entered - ie if user types 'thunk' the API can suggest the alternate term 'think'")

