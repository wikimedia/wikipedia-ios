import UIKit

class SearchViewController: ArticleCollectionViewController, UISearchBarDelegate {
    var shouldAnimateSearchBar: Bool = true
    @objc var areRecentSearchesEnabled: Bool = true
    @objc var shouldBecomeFirstResponder: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.displayType = .largeTitle
        title = CommonStrings.searchTitle
        if !areRecentSearchesEnabled {
            navigationItem.titleView = UIView()
        }
        navigationBar.addUnderNavigationBarView(searchBarContainerView)
        navigationBar.isInteractiveHidingEnabled  = false
        view.bringSubview(toFront: resultsViewController.view)
        resultsViewController.view.isHidden = true
        layoutManager.register(CollectionViewHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: CollectionViewHeader.identifier, addPlaceholder: true)
        navigationBar.isShadowHidingEnabled = true
    }
    
    var isAnimatingSearchBarState: Bool = false
 
    override func viewWillAppear(_ animated: Bool) {
        updateLanguageBarVisibility()
        super.viewWillAppear(animated)
        reloadRecentSearches()
        if animated && shouldBecomeFirstResponder {
            searchBar.becomeFirstResponder()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        funnel.logSearchStart()
        NSUserActivity.wmf_makeActive(NSUserActivity.wmf_searchView())
        if !animated && shouldBecomeFirstResponder {
            searchBar.becomeFirstResponder()
        }
        shouldAnimateSearchBar = true
    }
    
    var nonSearchAlpha: CGFloat = 1 {
        didSet {
            collectionView.alpha = nonSearchAlpha
            resultsViewController.view.alpha = nonSearchAlpha
            navigationBar.backgroundAlpha = nonSearchAlpha
        }
    }
    
    @objc var searchTerm: String? {
        set {
            searchBar.text = searchTerm
        }
        get {
            return searchBar.text
        }
    }
    
    var siteURL: URL? {
        return searchLanguageBarViewController?.currentlySelectedSearchLanguage?.siteURL() ?? NSURL.wmf_URLWithDefaultSiteAndCurrentLocale()
    }
    
    @objc func search() {
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
        
        guard (searchTerm as NSString).character(at: 0) != NSAttachmentCharacter else {
            return
        }
        
        let start = Date()
        
        AFNetworkActivityIndicatorManager.shared().incrementActivityCount()
        fakeProgressController.start()
        
        let commonCompletion = {
            AFNetworkActivityIndicatorManager.shared().decrementActivityCount()
        }
        let failure = { (error: Error, type: WMFSearchType) in
            DispatchQueue.main.async {
                commonCompletion()
                self.fakeProgressController.stop()
                guard searchTerm == self.searchBar.text else {
                    return
                }
                self.resultsViewController.wmf_showEmptyView(of: WMFEmptyViewType.noSearchResults, theme: self.theme, frame: self.resultsViewController.view.bounds)
                WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: false, dismissPreviousAlerts: true, tapCallBack: nil)
                self.funnel.logShowSearchError(withTypeOf: type, elapsedTime: Date().timeIntervalSince(start))
            }
        }
        
        let sucess = { (results: WMFSearchResults, type: WMFSearchType) in
            DispatchQueue.main.async {
                commonCompletion()
                self.fakeProgressController.finish()
                guard
                    let resultsArray = results.results,
                    resultsArray.count > 0
                else {
                    self.resultsViewController.wmf_showEmptyView(of: WMFEmptyViewType.noSearchResults, theme: self.theme, frame: self.resultsViewController.view.bounds)
                    return
                }
                self.resultsViewController.wmf_hideEmptyView()
                self.resultsViewController.resultsInfo = results
                self.resultsViewController.searchSiteURL = siteURL
                self.resultsViewController.results = resultsArray
                guard !suggested else {
                    return
                }
                self.funnel.logSearchResults(withTypeOf: type, resultCount: UInt(resultsArray.count), elapsedTime: Date().timeIntervalSince(start))

            }
        }
        
        fetcher.fetchArticles(forSearchTerm: searchTerm, siteURL: siteURL, resultLimit: WMFMaxSearchResultLimit, failure: { (error) in
            failure(error, .prefix)
        }) { (results) in
            DispatchQueue.main.async {
                guard searchTerm == self.searchBar.text else {
                    commonCompletion()
                    return
                }
                NSUserActivity.wmf_makeActive(NSUserActivity.wmf_searchResultsActivitySearchSiteURL(siteURL, searchTerm: searchTerm))
                sucess(results, .prefix)
                guard let resultsArray = results.results, resultsArray.count < 12 else {
                    return
                }
                self.fetcher.fetchArticles(forSearchTerm: searchTerm, siteURL: siteURL, resultLimit: WMFMaxSearchResultLimit, fullTextSearch: true, appendToPreviousResults: results, failure: { (error) in
                    failure(error, .full)
                }) { (results) in
                    sucess(results, .full)
                }
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
        let showLanguageBar = UserDefaults.wmf_userDefaults().wmf_showSearchLanguageBar()
        if  showLanguageBar && searchLanguageBarViewController == nil { // check this before accessing the view
            let searchLanguageBarViewController = setupLanguageBarViewController()
            addChildViewController(searchLanguageBarViewController)
            searchLanguageBarViewController.view.translatesAutoresizingMaskIntoConstraints = false
            navigationBar.addExtendedNavigationBarView(searchLanguageBarViewController.view)
            searchLanguageBarViewController.didMove(toParentViewController: self)
            searchLanguageBarViewController.view.isHidden = false
        } else if !showLanguageBar && searchLanguageBarViewController != nil {
            searchLanguageBarViewController?.willMove(toParentViewController: nil)
            navigationBar.removeExtendedNavigationBarView()
            searchLanguageBarViewController?.removeFromParentViewController()
            searchLanguageBarViewController = nil
        }
    }

    // MARK - Search
    
    lazy var fetcher: WMFSearchFetcher = {
       return WMFSearchFetcher()
    }()
    
    lazy var funnel: WMFSearchFunnel = {
        return WMFSearchFunnel()
    }()
    
    
    func didCancelSearch() {
        resultsViewController.results = []
        resultsViewController.wmf_hideEmptyView()
        searchBar.text = nil
        fakeProgressController.stop()
    }
    
    @objc func clear() {
        didCancelSearch()
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
    
    var searchLanguageBarViewController: SearchLanguagesBarViewController?
    
    func setSearchVisible(_ visible: Bool, animated: Bool) {
        let completion = { (finished: Bool) in
            self.resultsViewController.view.isHidden = !visible
            self.isAnimatingSearchBarState = false
        }
        let animations = {
            self.navigationBar.isBarHidingEnabled = true
            self.navigationBar.setNavigationBarPercentHidden(visible ? 1 : 0, underBarViewPercentHidden: 0, extendedViewPercentHidden: 0, animated: false)
            self.navigationBar.isBarHidingEnabled = false
            self.resultsViewController.view.alpha = visible ? 1 : 0
            self.searchBar.setShowsCancelButton(visible, animated: animated)
        }
        guard animated else {
            animations()
            completion(true)
            return
        }
        isAnimatingSearchBarState = true
        self.resultsViewController.view.alpha = visible ? 0 : 1
        self.resultsViewController.view.isHidden = false
        UIView.animate(withDuration: 0.3, animations: animations, completion: completion)
    }
    
    lazy var resultsViewController: SearchResultsViewController = {
        let resultsViewController = SearchResultsViewController()
        resultsViewController.dataStore = dataStore
        resultsViewController.apply(theme: theme)
        resultsViewController.delegate = self
        addChildViewController(resultsViewController)
        view.wmf_addSubviewWithConstraintsToEdges(resultsViewController.view)
        resultsViewController.didMove(toParentViewController: self)
        return resultsViewController
    }()
    
    lazy var fakeProgressController: FakeProgressController = {
        return FakeProgressController(progress: navigationBar, delegate: navigationBar)
    }()
    
    // MARK - Recent Search Saving
    
    
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

    // MARK - UISearchBarDelegate
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        guard !isAnimatingSearchBarState else {
            return false
        }
        setSearchVisible(true, animated: shouldAnimateSearchBar)
        return true
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        guard !isAnimatingSearchBarState && shouldAnimateSearchBar else {
            return false
        }
        setSearchVisible(false, animated: shouldAnimateSearchBar)
        return true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        search(for: searchBar.text, suggested: false)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        saveLastSearch()
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
    }
    
    @objc func makeSearchBarBecomeFirstResponder() {
        searchBar.becomeFirstResponder()
    }

    // MARK - Theme
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        searchBar.apply(theme: theme)
        searchBarContainerView.backgroundColor = theme.colors.paperBackground
        searchLanguageBarViewController?.apply(theme: theme)
        resultsViewController.apply(theme: theme)
        view.backgroundColor = .clear
        collectionView.backgroundColor = theme.colors.paperBackground
    }
    
    // Recent

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
    
    func configure(header: CollectionViewHeader, forSectionAt sectionIndex: Int, layoutOnly: Bool) {
        header.style = .recentSearches
        header.apply(theme: theme)
        header.title = WMFLocalizedString("search-recent-title", value: "Recently searched", comment: "Title for list of recent search terms")
        header.buttonTitle = countOfRecentSearches > 0 ? WMFLocalizedString("search-clear-title", value: "Clear", comment: "Text of the button shown to clear recent search terms") : nil
        header.delegate = self
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionElementKindSectionHeader else {
            return UICollectionReusableView()
        }
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CollectionViewHeader.identifier, for: indexPath)
        guard let header = view as? CollectionViewHeader else {
            return view
        }
        configure(header: header, forSectionAt: indexPath.section, layoutOnly: false)
        return header
    }
    
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForHeaderInSection section: Int, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        guard
            self.collectionView(collectionView, numberOfItemsInSection: 0) > 0,
            let header = layoutManager.placeholder(forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: CollectionViewHeader.identifier) as? CollectionViewHeader
        else {
            return ColumnarCollectionViewLayoutHeightEstimate(precalculated: true, height: 0)
        }
        configure(header: header, forSectionAt: section, layoutOnly: true)
        let size = header.sizeThatFits(CGSize(width: columnWidth, height: UIViewNoIntrinsicMetric), apply: false)
        return ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: size.height)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let recentSearch = recentSearches?.entry(at: UInt(indexPath.item)) else {
            return
        }
        searchBar.text = recentSearch.searchTerm
        searchBar.becomeFirstResponder()
        search()
    }
}

extension SearchViewController: CollectionViewHeaderDelegate {
    func collectionViewHeaderButtonWasPressed(_ collectionViewHeader: CollectionViewHeader) {
        let dialog = UIAlertController(title: WMFLocalizedString("search-recent-clear-confirmation-heading", value: "Delete all recent searches?", comment: "Heading text of delete all confirmation dialog"), message: WMFLocalizedString("search-recent-clear-confirmation-sub-heading", value: "This action cannot be undone!", comment: "Sub-heading text of delete all confirmation dialog"), preferredStyle: .alert)
        dialog.addAction(UIAlertAction(title: WMFLocalizedString("search-recent-clear-cancel", value: "Cancel", comment: "Button text for cancelling delete all action\n{{Identical|Cancel}}"), style: .cancel, handler: nil))
        dialog.addAction(UIAlertAction(title: WMFLocalizedString("search-recent-clear-delete-all", value: "Delete All", comment: "Button text for confirming delete all action\n{{Identical|Delete all}}"), style: .destructive, handler: { (action) in
            self.didCancelSearch()
            self.dataStore.recentSearchList.removeAllEntries()
            self.dataStore.recentSearchList.save()
            self.reloadRecentSearches()
        }))
        present(dialog, animated: true)
    }
}

extension SearchViewController: ArticleCollectionViewControllerDelegate {
    func articleCollectionViewController(_ articleCollectionViewController: ArticleCollectionViewController, didSelectArticleWithURL: URL) {
        saveLastSearch()
        funnel.logSearchResultTap()
    }
}

extension SearchViewController: SearchLanguagesBarViewControllerDelegate {
    func searchLanguagesBarViewController(_ controller: SearchLanguagesBarViewController, didChangeCurrentlySelectedSearchLanguage language: MWKLanguageLink) {
        search()
    }
}

// Keep
// WMFLocalizedStringWithDefaultValue(@"search-did-you-mean", nil, nil, @"Did you mean %1$@?", @"Button text for searching for an alternate spelling of the search term. Parameters:\n* %1$@ - alternate spelling of the search term the user entered - ie if user types 'thunk' the API can suggest the alternate term 'think'")

