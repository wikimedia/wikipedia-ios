import UIKit
import WMFComponents

protocol SearchViewControllerBarDelegate: AnyObject {
    var searchBar: UISearchBar? { get }
}

protocol SearchViewControllerResultSelectionDelegate: AnyObject {
    func didSelectSearchResult(articleURL: URL, searchViewController: SearchViewController)
}

class SearchViewController: ArticleCollectionViewController2, UISearchBarDelegate {
    
    // Assign so that the correct search bar will have it's field populated once a "recently searched" term is selected
    weak var searchBarDelegate: SearchViewControllerBarDelegate?
    
    // Assign if you don't want search result selection to do default navigation, and instead want to perform your own custom logic upon selection.
    weak var searchResultSelectionDelegate: SearchViewControllerResultSelectionDelegate?
    
    @objc var prefersLargeTitles: Bool = true
    
    private var searchLanguageBarViewController: SearchLanguagesBarViewController?
    private var needsAnimateLanguageBarMovement = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        embedResultsViewController()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateLanguageBarVisibility()
        reloadRecentSearches()
        navigationController?.navigationBar.prefersLargeTitles = prefersLargeTitles
        navigationController?.hidesBarsOnSwipe = false
        
        let newAppearance = UINavigationBarAppearance()
        newAppearance.largeTitleTextAttributes = [.font: WMFFont.for(.boldTitle1)]
        newAppearance.configureWithOpaqueBackground()
        newAppearance.backgroundColor = theme.colors.chromeBackground
        newAppearance.backgroundImage = theme.navigationBarBackgroundImage
        newAppearance.shadowImage = UIImage()
        newAppearance.shadowColor = .clear
        navigationItem.scrollEdgeAppearance = newAppearance
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        SearchFunnel.shared.logSearchStart(source: source)
        NSUserActivity.wmf_makeActive(NSUserActivity.wmf_searchView())
        
        if shouldBecomeFirstResponder {
            navigationItem.searchController?.isActive = true
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let searchLanguageBarViewController {
            collectionView.contentInset.top = searchLanguageBarViewController.view.bounds.height
            resultsViewController.collectionView.contentInset.top = searchLanguageBarViewController.view.bounds.height
        } else {
            collectionView.contentInset.top = 0
            resultsViewController.collectionView.contentInset.top = 0
        }
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        
        let normalizedContentOffset = scrollView.contentOffset.y + (scrollView.safeAreaInsets.top + scrollView.contentInset.top)
        searchLanguageBarTopConstraint?.constant = scrollView.safeAreaInsets.top - normalizedContentOffset
    }
    
    private func setupNavBar() {
        
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.hidesSearchBarWhenScrolling = false
        if #available(iOS 16.0, *) {
            navigationItem.preferredSearchBarPlacement = .stacked
        } else {
            // Fallback on earlier versions
        }
        
        let search = UISearchController(searchResultsController: nil)
        search.obscuresBackgroundDuringPresentation = false
        search.searchResultsUpdater = self
        search.searchBar.delegate = self
        search.delegate = self
        search.searchBar.placeholder = "Type something here to search"
        search.automaticallyShowsCancelButton = true
        navigationItem.searchController = search
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
    
    var shouldShowCancelButton: Bool = true
    
    var doResultsShowArticlePreviews = true {
        didSet {
            resultsViewController.doesShowArticlePreviews = doResultsShowArticlePreviews
        }
    }
    
    var showLanguageBar: Bool?
    
    var searchTerm: String?
    var lastSearchSiteURL: URL?
    
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
                SearchFunnel.shared.logShowSearchError(with: type, elapsedTime: Date().timeIntervalSince(start), source: self.source)
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
        SearchFunnel.shared.logSearchCancel(source: source)
    }
    
    @objc func clear() {
        didCancelSearch()
        updateRecentlySearchedVisibility(searchText: navigationItem.searchController?.searchBar.text)
    }
    
    func prepareForOutgoingTransition(with outgoingNavigationBar: NavigationBar) {
        
    }
    
    lazy var resultsViewController: SearchResultsViewController = {
        let resultsViewController = SearchResultsViewController()
        resultsViewController.dataStore = dataStore
        resultsViewController.apply(theme: theme)
        resultsViewController.delegate = self
        return resultsViewController
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
        collectionView.backgroundColor = theme.colors.paperBackground
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
    
    // MARK: Collection View - related methods. Note: All of these affect the "Recently searched" list, NOT the actual search results. The actual search results are in the SearchResultsViewController, which SearchViewController embeds and displays depending on the length of the search bar text.
    
    override var headerStyle: ColumnarCollectionViewController2.HeaderStyle {
        return .sections
    }
    
    func reloadRecentSearches() {
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
    
    // This hook is when you select a recently searched term
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let recentSearch = recentSearches?.entry(at: UInt(indexPath.item)) else {
            return
        }
        updateRecentlySearchedVisibility(searchText: recentSearch.searchTerm)
        collectionView.deselectItem(at: indexPath, animated: true)
        
        let searchBar = searchBarDelegate?.searchBar ?? navigationItem.searchController?.searchBar
        searchBar?.text = recentSearch.searchTerm
        searchBar?.becomeFirstResponder()

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
        needsAnimateLanguageBarMovement = true
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        needsAnimateLanguageBarMovement = true
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        needsAnimateLanguageBarMovement = false
    }
}

extension SearchViewController: SearchResultsViewControllerDelegate {
    func didSelectSearchResult(articleURL: URL, indexPath: IndexPath,  searchResultsViewController: SearchResultsViewController) {
        
        SearchFunnel.shared.logSearchResultTap(position: indexPath.item, source: source)
        saveLastSearch()
        
        if let searchResultSelectionDelegate {
            searchResultSelectionDelegate.didSelectSearchResult(articleURL: articleURL, searchViewController: self)
        } else {
            let userInfo: [AnyHashable : Any] = [RoutingUserInfoKeys.source: RoutingUserInfoSourceValue.search.rawValue]
            navigate(to: articleURL, userInfo: userInfo)
        }
    }
}

// Keep
// WMFLocalizedStringWithDefaultValue(@"search-did-you-mean", nil, nil, @"Did you mean %1$@?", @"Button text for searching for an alternate spelling of the search term. Parameters: * %1$@ - alternate spelling of the search term the user entered - ie if user types 'thunk' the API can suggest the alternate term 'think'")

