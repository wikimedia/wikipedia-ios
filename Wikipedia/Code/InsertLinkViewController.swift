import UIKit

protocol InsertLinkViewControllerDelegate: AnyObject {
    func insertLinkViewController(_ insertLinkViewController: InsertLinkViewController, didTapCloseButton button: UIBarButtonItem)
    func insertLinkViewController(_ insertLinkViewController: InsertLinkViewController, didInsertLinkFor page: String, withLabel label: String?)
}

class InsertLinkViewController: UIViewController {
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

    private lazy var closeButton: UIBarButtonItem = {
        let closeButton = UIBarButtonItem.wmf_buttonType(.X, target: self, action: #selector(delegateCloseButtonTap(_:)))
        closeButton.accessibilityLabel = CommonStrings.closeButtonAccessibilityLabel
        return closeButton
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = CommonStrings.insertLinkTitle
        navigationItem.leftBarButtonItem = closeButton
//        let navigationController = WMFThemeableNavigationController(rootViewController: searchViewController)
//        navigationController.isNavigationBarHidden = true
//        wmf_add(childController: navigationController, andConstrainToEdgesOfContainerView: view)
        setupNavigationBar()
        apply(theme: theme)
    }
    
    func setupNavigationBar() {
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.hidesBarsOnSwipe = false
        navigationItem.largeTitleDisplayMode = .never
        
        navigationItem.hidesSearchBarWhenScrolling = false
        if #available(iOS 16.0, *) {
            navigationItem.preferredSearchBarPlacement = .stacked
        } else {
            // Fallback on earlier versions
        }
        
        let searchViewController = SearchViewController()
        searchViewController.dataStore = dataStore
        searchViewController.delegatesSearchResultSelection = true
        searchViewController.delegatesSearchTermSelection = true
        searchViewController.searchTermSelectDelegate = self
        searchViewController.delegate = self
        let search = UISearchController(searchResultsController: searchViewController)
        search.searchResultsUpdater = self
        search.searchBar.showsCancelButton = false
        search.hidesNavigationBarDuringPresentation = false
        // search.delegate = self
        search.searchBar.searchBarStyle = .minimal
        search.searchBar.placeholder = WMFLocalizedString("search-field-placeholder-text", value: "Search Wikipedia", comment: "Search field placeholder text")
        search.showsSearchResultsController = true
        search.searchBar.showsScopeBar = false

        // definesPresentationContext = true
        
        navigationItem.searchController = search
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
        delegate?.insertLinkViewController(self, didTapCloseButton: closeButton)
        return true
    }
}

extension InsertLinkViewController: ArticleCollectionViewControllerDelegate2 {
    func articleCollectionViewController(_ articleCollectionViewController: ArticleCollectionViewController2, didSelectArticleWith articleURL: URL, at indexPath: IndexPath) {
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
        closeButton.tintColor = theme.colors.primaryText
        // searchViewController.apply(theme: theme)
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

extension InsertLinkViewController: SearchTermSelectDelegate {
    var searchBarText: String? {
        navigationItem.searchController?.searchBar.text
    }
    
    func searchViewController(_ searchViewController: SearchViewController, didSelectSearchTerm searchTerm: String, at indexPath: IndexPath) {
        navigationItem.searchController?.searchBar.text = searchTerm
    }
}
