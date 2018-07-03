import UIKit

class SearchViewController: ColumnarCollectionViewController, UISearchBarDelegate {
    @objc var dataStore: MWKDataStore!
    var shouldAnimateSearchBar: Bool = true
    @objc var shouldBecomeFirstResponder: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.isBackVisible = false
        title = CommonStrings.searchTitle
        navigationItem.titleView = UIView()
        navigationBar.addUnderNavigationBarView(searchBarContainerView)
        updateLanguageBarVisibility()
        navigationBar.isInteractiveHidingEnabled  = false
        view.bringSubview(toFront: resultsViewController.view)
        resultsViewController.view.isHidden = true
    }
    
    var isAnimatingSearchBarState: Bool = false
 
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
        return searchLanguageBarViewController.currentlySelectedSearchLanguage?.siteURL() ?? NSURL.wmf_URLWithDefaultSiteAndCurrentLocale()
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
    
    private func updateLanguageBarVisibility() {
        if UserDefaults.wmf_userDefaults().wmf_showSearchLanguageBar() { // check this before accessing the view
            navigationBar.addExtendedNavigationBarView(searchLanguageBarViewController.view)
            searchLanguageBarViewController.view.isHidden = false
        } else {
            navigationBar.removeExtendedNavigationBarView()
            searchLanguageBarViewController.view.isHidden = true
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
    
    lazy var searchLanguageBarViewController: SearchLanguagesBarViewController = {
        let searchLanguageBarViewController = SearchLanguagesBarViewController()
        searchLanguageBarViewController.apply(theme: theme)
        addChildViewController(searchLanguageBarViewController)
        searchLanguageBarViewController.view.isHidden = true
        view.addSubview(searchLanguageBarViewController.view)
        searchLanguageBarViewController.didMove(toParentViewController: self)
        return searchLanguageBarViewController
    }()
    
    func setSearchVisible(_ visible: Bool, animated: Bool) {
        let group = WMFTaskGroup()
        group.enter()
        let completion = { (finished: Bool) in
            self.resultsViewController.view.isHidden = !visible
            group.leave()
        }
        group.enter()
        group.enter()
        let animations = {
            self.navigationBar.isBarHidingEnabled = true
            self.navigationBar.setNavigationBarPercentHidden(visible ? 1 : 0, underBarViewPercentHidden: 0, extendedViewPercentHidden: 0, animated: false, additionalAnimations: {
                group.leave()
                self.updateScrollViewInsets()
            })
            self.navigationBar.isBarHidingEnabled = false
            self.resultsViewController.view.alpha = visible ? 1 : 0
            self.searchBar.setShowsCancelButton(visible, animated: animated)
            group.leave()
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
        group.waitInBackgroundAndNotify(on: DispatchQueue.main) {
            self.isAnimatingSearchBarState = false
        }
    }
    
    lazy var resultsViewController: SearchResultsViewController = {
        let resultsViewController = SearchResultsViewController()
        resultsViewController.dataStore = dataStore
        resultsViewController.apply(theme: theme)
        addChildViewController(resultsViewController)
        view.wmf_addSubviewWithConstraintsToEdges(resultsViewController.view)
        resultsViewController.didMove(toParentViewController: self)
        return resultsViewController
    }()
    
    lazy var fakeProgressController: FakeProgressController = {
        return FakeProgressController(progress: navigationBar, delegate: navigationBar)
    }()

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
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if let navigationController = navigationController, navigationController.viewControllers.count > 1 {
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
        searchLanguageBarViewController.apply(theme: theme)
        resultsViewController.apply(theme: theme)
        view.backgroundColor = .clear
        collectionView.backgroundColor = theme.colors.paperBackground
        updateLanguageBarVisibility()
    }
}

// Keep
// WMFLocalizedStringWithDefaultValue(@"search-recent-title", nil, nil, @"Recently searched", @"Title for list of recent search terms")
// WMFLocalizedStringWithDefaultValue(@"menu-trash-accessibility-label", nil, nil, @"Delete", @"Accessible label for trash button\n{{Identical|Delete}}")
// WMFLocalizedStringWithDefaultValue(@"search-did-you-mean", nil, nil, @"Did you mean %1$@?", @"Button text for searching for an alternate spelling of the search term. Parameters:\n* %1$@ - alternate spelling of the search term the user entered - ie if user types 'thunk' the API can suggest the alternate term 'think'")

//- (IBAction)clearRecentSearches:(id)sender {
//    UIAlertController *dialog = [UIAlertController alertControllerWithTitle:WMFLocalizedStringWithDefaultValue(@"search-recent-clear-confirmation-heading", nil, nil, @"Delete all recent searches?", @"Heading text of delete all confirmation dialog") message:WMFLocalizedStringWithDefaultValue(@"search-recent-clear-confirmation-sub-heading", nil, nil, @"This action cannot be undone!", @"Sub-heading text of delete all confirmation dialog") preferredStyle:UIAlertControllerStyleAlert];
//
//    [dialog addAction:[UIAlertAction actionWithTitle:WMFLocalizedStringWithDefaultValue(@"search-recent-clear-cancel", nil, nil, @"Cancel", @"Button text for cancelling delete all action\n{{Identical|Cancel}}") style:UIAlertActionStyleCancel handler:NULL]];
//
//    [dialog addAction:[UIAlertAction actionWithTitle:WMFLocalizedStringWithDefaultValue(@"search-recent-clear-delete-all", nil, nil, @"Delete All", @"Button text for confirming delete all action\n{{Identical|Delete all}}")
//        style:UIAlertActionStyleDestructive
//        handler:^(UIAlertAction *_Nonnull action) {
//        [self didCancelSearch];
//        [self.dataStore.recentSearchList removeAllEntries];
//        [self.dataStore.recentSearchList save];
//        [self updateRecentSearches];
//        [self updateRecentSearchesVisibility:YES];
//        }]];
//    [self presentViewController:dialog animated:YES completion:NULL];
//}
