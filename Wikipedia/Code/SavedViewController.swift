import UIKit

@objc public protocol SavedViewControllerDelegate: NSObjectProtocol {
    @objc func didPressSortButton()
}

@objc(WMFSavedViewController)
class SavedViewController: UIViewController {

    fileprivate var savedArticlesCollectionViewController: SavedArticlesCollectionViewController!
    
    fileprivate lazy var readingListsCollectionViewController: ReadingListsCollectionViewController? = {
        guard let dataStore = dataStore else {
            assertionFailure("dataStore is nil")
            return nil
        }
        let readingListsCollectionViewController = ReadingListsCollectionViewController(with: dataStore)
        return readingListsCollectionViewController
    }()
    
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var extendedNavBarView: UIView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchBarHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var searchBarTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var searchBarBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var sortButton: UIButton!
    
    @IBOutlet var toggleButtons: [UIButton]!
    
    fileprivate var theme: Theme = Theme.standard
    
    // MARK: - Initalization and setup
    
    @objc public var dataStore: MWKDataStore? {
        didSet {
            guard let newValue = dataStore else {
                assertionFailure("cannot set dataStore to nil")
                return
            }
            title = WMFLocalizedString("saved-title", value: "Saved", comment: "Title of the saved screen shown on the saved tab\n{{Identical|Saved}}")
            savedArticlesCollectionViewController.dataStore = newValue
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        savedArticlesCollectionViewController = SavedArticlesCollectionViewController()
    }
    
    // MARK: - Toggling views
    
    fileprivate enum View: Int {
        case savedArticles, readingLists
    }
    
    @IBAction func toggleButtonPressed(_ sender: UIButton) {
        toggleButtons.first { $0.tag != sender.tag }?.isSelected = false
        sender.isSelected = true
        currentView = View(rawValue: sender.tag) ?? .savedArticles
    }
    
    fileprivate var currentView: View = .savedArticles {
        didSet {
            searchBar.resignFirstResponder()
            switch currentView {
            case .savedArticles:
                removeChild(readingListsCollectionViewController)
                savedArticlesCollectionViewController.editController.navigationDelegate = self
                savedDelegate = savedArticlesCollectionViewController
                
                navigationItem.leftBarButtonItem = nil
                isSearchBarHidden = savedArticlesCollectionViewController.isEmpty
                
                addChild(savedArticlesCollectionViewController)
                
            case .readingLists :
                removeChild(savedArticlesCollectionViewController)
                readingListsCollectionViewController?.editController.navigationDelegate = self
                
                navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: readingListsCollectionViewController.self, action: #selector(readingListsCollectionViewController?.presentCreateReadingListViewController))
                isSearchBarHidden = true
                
                addChild(readingListsCollectionViewController)
                
            }
        }
    }
    
    fileprivate var isSearchBarHidden: Bool = false {
        didSet {
            searchBar.isHidden = isSearchBarHidden
            sortButton.isHidden = isSearchBarHidden
            searchBarHeightConstraint.constant = isSearchBarHidden ? 0 : 36
            searchBarTopConstraint.constant = isSearchBarHidden ? 0 : 15
            searchBarBottomConstraint.constant = isSearchBarHidden ? 0 : 15
        }
    }
    
    fileprivate func addChild(_ vc: UICollectionViewController?) {
        guard let vc = vc else {
            return
        }
        addChildViewController(vc)
        vc.view.frame = containerView.bounds
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.addSubview(vc.view)
        vc.didMove(toParentViewController: self)
    }
    
    fileprivate func removeChild(_ vc: UICollectionViewController?) {
        guard let vc = vc else {
            return
        }
        vc.view.removeFromSuperview()
        vc.willMove(toParentViewController: nil)
        vc.removeFromParentViewController()
    }
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        currentView = .savedArticles
        
        searchBar.delegate = savedArticlesCollectionViewController
        searchBar.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        searchBar.returnKeyType = .search
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = WMFLocalizedString("saved-search-default-text", value:"Search ", comment:"tbd")
        
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .all
        
        apply(theme: self.theme)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        wmf_updateNavigationBar(removeUnderline: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        wmf_updateNavigationBar(removeUnderline: false)
    }
    
    // MARK: - Sorting
    
    public weak var savedDelegate: SavedViewControllerDelegate?
    
    @IBAction func sortButonPressed() {
        savedDelegate?.didPressSortButton()
    }
    
    // MARK: - Batch edit toolbar
    
    internal lazy var batchEditToolbar: UIToolbar = {
        let toolbarHeight: CGFloat = 50
        let toolbar = UIToolbar()
        updateBatchEditToolbarFrame(toolbar)
        toolbar.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        return toolbar
    }()
    
    fileprivate var isBatchEditToolbarVisible = false
    
    fileprivate func updateBatchEditToolbarFrame(_ toolbar: UIToolbar) {
        let toolbarHeight: CGFloat = 50
        toolbar.frame = CGRect(x: 0, y: view.bounds.height - toolbarHeight, width: view.bounds.width, height: toolbarHeight)
    }
    
    override func viewDidLayoutSubviews() {
        if isBatchEditToolbarVisible {
            updateBatchEditToolbarFrame(batchEditToolbar)
        }
    }
}

// MARK: - BatchEditNavigationDelegate

extension SavedViewController: BatchEditNavigationDelegate {

    func changeRightNavButton(to button: UIBarButtonItem) {
        navigationItem.rightBarButtonItem = button
    }
    
    func didSetIsBatchEditToolbarVisible(_ isVisible: Bool) {
        isBatchEditToolbarVisible = isVisible
        tabBarController?.tabBar.isHidden = isVisible
    }
    
    func createBatchEditToolbar(with items: [UIBarButtonItem], add: Bool) {
        if add {
            batchEditToolbar.items = items
            view.addSubview(batchEditToolbar)
        } else {
            batchEditToolbar.removeFromSuperview()
        }
    }
    
    func emptyStateDidChange(_ empty: Bool) {
        guard currentView != .readingLists else {
            isSearchBarHidden = true
            return
        }
        isSearchBarHidden = empty
    }
}

// MARK: - Themeable

extension SavedViewController: Themeable {
    
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.chromeBackground
        
        savedArticlesCollectionViewController.apply(theme: theme)
        readingListsCollectionViewController?.apply(theme: theme)
        
        for button in toggleButtons {
            button.setTitleColor(theme.colors.secondaryText, for: .normal)
            button.tintColor = theme.colors.link
        }
        
        batchEditToolbar.barTintColor = theme.colors.paperBackground
        batchEditToolbar.tintColor = theme.colors.link
        
        extendedNavBarView.backgroundColor = theme.colors.chromeBackground
        searchBar.setSearchFieldBackgroundImage(theme.searchBarBackgroundImage, for: .normal)
        searchBar.wmf_enumerateSubviewTextFields{ (textField) in
            textField.textColor = theme.colors.primaryText
            textField.keyboardAppearance = theme.keyboardAppearance
            textField.font = UIFont.systemFont(ofSize: 14)
        }
        searchBar.searchTextPositionAdjustment = UIOffset(horizontal: 7, vertical: 0)
        
    }
}
