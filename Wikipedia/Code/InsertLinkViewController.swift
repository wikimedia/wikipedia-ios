import UIKit
import WMFComponents

protocol InsertLinkViewControllerDelegate: AnyObject {
    func insertLinkViewController(_ insertLinkViewController: InsertLinkViewController, didTapCloseButton button: UIBarButtonItem)
    func insertLinkViewController(_ insertLinkViewController: InsertLinkViewController, didInsertLinkFor page: String, withLabel label: String?)
}

class InsertLinkViewController: UIViewController, WMFNavigationBarConfiguring {
    weak var delegate: InsertLinkViewControllerDelegate?
    private var theme: Theme
    private let dataStore: MWKDataStore
    private let link: Link
    private let siteURL: URL?

    init(link: Link, siteURL: URL?, dataStore: MWKDataStore, theme: Theme) {
        self.link = link
        self.siteURL = siteURL
        self.dataStore = dataStore
        self.theme = theme
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
        
        let closeButtonConfig = WMFNavigationBarCloseButtonConfig(text: CommonStrings.cancelActionTitle, target: self, action: #selector(delegateCloseButtonTap(_:)), alignment: .leading)

        let searchResultsContainer = SearchResultsContainerViewController(source: .unknown, dataStore: dataStore)
        searchResultsContainer.showLanguageBar = false
        searchResultsContainer.apply(theme: theme)
        searchResultsContainer.populateSearchBarAction = { [weak self] searchTerm in
            self?.navigationItem.searchController?.searchBar.text = searchTerm
            self?.navigationItem.searchController?.searchBar.becomeFirstResponder()
        }
        searchResultsContainer.articleTappedAction = { [weak self] articleURL in
            guard let self, let title = articleURL.wmf_title else { return }
            navigationItem.searchController?.isActive = false
            self.delegate?.insertLinkViewController(self, didInsertLinkFor: title, withLabel: nil)
        }

        let searchConfig = WMFNavigationBarSearchConfig(
            searchResultsController: searchResultsContainer,
            searchControllerDelegate: nil,
            searchResultsUpdater: searchResultsContainer,
            searchBarDelegate: self,
            searchBarPlaceholder: CommonStrings.searchBarPlaceholder,
            showsScopeBar: false,
            scopeButtonTitles: nil)
        
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: closeButtonConfig, profileButtonConfig: nil, tabsButtonConfig: nil, searchBarConfig: searchConfig, hideNavigationBarOnScroll: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        DispatchQueue.main.async { [weak self] in
          if let page = self?.link.page, !page.isEmpty {
            self?.navigationItem.searchController?.searchBar.text = page
            self?.navigationItem.searchController?.searchBar.becomeFirstResponder()
          } else {
            self?.navigationItem.searchController?.searchBar.becomeFirstResponder()
          }
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

extension InsertLinkViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.inputAccessoryBackground
        view.layer.shadowColor = theme.colors.shadow.cgColor
        
        if let searchVC = navigationItem.searchController?.searchResultsController as? SearchResultsContainerViewController {
            searchVC.theme = theme
            searchVC.apply(theme: theme)
        }
    }
}

extension InsertLinkViewController: EditingFlowViewController {
    
}

extension InsertLinkViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        dismiss(animated: true)
    }
}
