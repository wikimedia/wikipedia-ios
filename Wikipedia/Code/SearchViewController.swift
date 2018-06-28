import UIKit

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

class SearchViewController: ColumnarCollectionViewController, UISearchBarDelegate {

    let dataStore: MWKDataStore
    @objc required init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
        super.init()
        title = WMFLocalizedString("search-title", value: "Search", comment: "Title for search interface.\n{{Identical|Search}}")
    }
    
    @objc var searchTerm: String? {
        set {
            searchBar.text = searchTerm
        }
        get {
            return searchBar.text
        }
    }
    
    @objc func search() {
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.addExtendedNavigationBarView(searchBarContainerView)
        navigationBar.isBackVisible = false
    }

    // MARK - Search
    let searchBarPadding = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
    
    lazy var searchBarContainerView: UIView = {
        let searchContainerView = UIView()
        searchContainerView.wmf_addSubview(searchBar, withConstraintsToEdgesWithInsets: searchBarPadding, priority: .required)
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
    
    // MARK - UISearchBarDelegate
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        navigationBar.setNavigationBarPercentHidden(1, underBarViewPercentHidden: 0, extendedViewPercentHidden: 0, animated: true)
        searchBar.showsCancelButton = true
        return true
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        navigationBar.setNavigationBarPercentHidden(0, underBarViewPercentHidden: 0, extendedViewPercentHidden: 0, animated: true)
        searchBar.showsCancelButton = false
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(false)
    }
}
