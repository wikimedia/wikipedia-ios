import UIKit
import WMFComponents

protocol InsertLinkViewControllerDelegate: AnyObject {
    func insertLinkViewController(_ insertLinkViewController: InsertLinkViewController, didTapCloseButton button: UIBarButtonItem)
    func insertLinkViewController(_ insertLinkViewController: InsertLinkViewController, didInsertLinkFor page: String, withLabel label: String?)
}

class InsertLinkViewController: UIViewController, WMFNavigationBarConfiguring {
    weak var delegate: InsertLinkViewControllerDelegate?
    private var theme = Theme.standard
    private let dataStore: MWKDataStore
    private let link: Link
    private let siteURL: URL?

    init(link: Link, siteURL: URL?, dataStore: MWKDataStore) {
        self.link = link
        self.siteURL = siteURL
        self.dataStore = dataStore
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        apply(theme: theme)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureNavigationBar()
    }
    
    func configureNavigationBar() {
        
        let titleConfig = WMFNavigationBarTitleConfig(title: CommonStrings.insertLinkTitle, customView: nil, alignment: .centerCompact)
        
        let closeButtonConfig = WMFNavigationBarCloseButtonConfig(accessibilityLabel: CommonStrings.closeButtonAccessibilityLabel, target: self, action: #selector(delegateCloseButtonTap(_:)), alignment: .trailing)

        let searchViewController = SearchViewController()
        searchViewController.showLanguageBar = false
        searchViewController.dataStore = dataStore
        searchViewController.recentlySearchedSelectionDelegate = self
        searchViewController.searchResultSelectionDelegate = self
        searchViewController.theme = theme
        
        let searchConfig = WMFNavigationBarSearchConfig(
            searchResultsController: searchViewController,
            searchControllerDelegate: nil,
            searchResultsUpdater: self,
            searchBarDelegate: nil,
            searchBarPlaceholder: WMFLocalizedString("search-field-placeholder-text", value: "Search Wikipedia", comment: "Search field placeholder text"),
            showsScopeBar: false,
            scopeButtonTitles: nil)
        
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: closeButtonConfig, profileButtonConfig: nil, searchBarConfig: searchConfig, hideNavigationBarOnScroll: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.async {[weak self] in
            self?.navigationItem.searchController?.searchBar.becomeFirstResponder()
        }
    }

    @objc private func delegateCloseButtonTap(_ sender: UIBarButtonItem) {
        navigationItem.searchController?.isActive = false
        
        delegate?.insertLinkViewController(self, didTapCloseButton: sender)
    }

    override func accessibilityPerformEscape() -> Bool {
        
        guard let leftBarButtonItem = navigationItem.leftBarButtonItem else {
            return false
        }
        
        delegate?.insertLinkViewController(self, didTapCloseButton: leftBarButtonItem)
        return true
    }
}

extension InsertLinkViewController: SearchViewControllerResultSelectionDelegate {
    func didSelectSearchResult(articleURL: URL, searchViewController: SearchViewController) {
        guard let title = articleURL.wmf_title else {
            return
        }
        navigationItem.searchController?.isActive = false
        delegate?.insertLinkViewController(self, didInsertLinkFor: title, withLabel: nil)
    }
}

extension InsertLinkViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.inputAccessoryBackground
        view.layer.shadowColor = theme.colors.shadow.cgColor
        
        if let searchVC = navigationItem.searchController?.searchResultsController as? SearchViewController {
            searchVC.theme = theme
            searchVC.apply(theme: theme)
        }
    }
}

extension InsertLinkViewController: EditingFlowViewController {
    
}

extension InsertLinkViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else {
            return
        }
        
        guard let searchViewController = navigationItem.searchController?.searchResultsController as? SearchViewController else {
            return
        }
        
        if text.isEmpty {
            searchViewController.searchTerm = nil
            searchViewController.updateRecentlySearchedVisibility(searchText: nil)
        } else {
            searchViewController.searchTerm = text
            searchViewController.updateRecentlySearchedVisibility(searchText: text)
            searchViewController.search()
        }
    }
}

extension InsertLinkViewController: SearchViewControllerRecentlySearchedSelectionDelegate {
    func didSelectRecentlySearchedTerm(_ searchTerm: String, searchViewController: SearchViewController) {
        navigationItem.searchController?.searchBar.text = searchTerm
        navigationItem.searchController?.searchBar.becomeFirstResponder()
    }
}
