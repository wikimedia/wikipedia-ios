import UIKit

protocol SavedViewControllerDelegate: NSObjectProtocol {
    func saved(_ saved: SavedViewController, shouldShowSortAlert: Bool)
}

@objc(WMFSavedViewController)
class SavedViewController: ViewController {

    private var savedArticlesViewController: SavedArticlesViewController!
    
    private lazy var readingListsViewController: ReadingListsViewController? = {
        guard let dataStore = dataStore else {
            assertionFailure("dataStore is nil")
            return nil
        }
        let readingListsCollectionViewController = ReadingListsViewController(with: dataStore)
        return readingListsCollectionViewController
    }()
    
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet var extendedNavBarView: UIView!
    @IBOutlet var underBarView: UIView!
    @IBOutlet var allArticlesButton: UIButton!
    @IBOutlet var readingListsButton: UIButton!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet var searchBarConstraints: [NSLayoutConstraint] = []
    @IBOutlet weak var sortButton: UIButton!
    
    @IBOutlet weak var separatorView: UIView!
    
    @IBOutlet var toggleButtons: [UIButton]!
    
    // MARK: - Initalization and setup
    
    @objc public var dataStore: MWKDataStore? {
        didSet {
            guard let newValue = dataStore else {
                assertionFailure("cannot set dataStore to nil")
                return
            }
            title = CommonStrings.savedTabTitle
            savedArticlesViewController.dataStore = newValue
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        savedArticlesViewController = SavedArticlesViewController()
    }
    
    // MARK: - Toggling views
    
    private enum View: Int {
        case savedArticles, readingLists
    }
    
    @IBAction func toggleButtonPressed(_ sender: UIButton) {
        toggleButtons.first { $0.tag != sender.tag }?.isSelected = false
        sender.isSelected = true
        currentView = View(rawValue: sender.tag) ?? .savedArticles
    }
    
    private var currentView: View = .savedArticles {
        didSet {
            searchBar.resignFirstResponder()
            switch currentView {
            case .savedArticles:
                removeChild(readingListsViewController)
                addChild(savedArticlesViewController)
                savedArticlesViewController.editController.navigationDelegate = self
                savedDelegate = savedArticlesViewController
                isAddButtonHidden = true
                isSearchBarHidden = savedArticlesViewController.isEmpty
                scrollView = savedArticlesViewController.collectionView
            case .readingLists :
                removeChild(savedArticlesViewController)
                addChild(readingListsViewController)
                readingListsViewController?.editController.navigationDelegate = self
                isAddButtonHidden = false
                scrollView = readingListsViewController?.collectionView
                isSearchBarHidden = true
            }
        }
    }
    
    private var isAddButtonHidden: Bool = true {
        didSet {
            let clearButtonTitle = WMFLocalizedString("saved-clear-all", value: "Clear", comment: "Text of the button shown at the top of saved pages which deletes all the saved pages\n{{Identical|Clear}}")
            let clearButton = UIBarButtonItem(title: clearButtonTitle, style: .plain, target: savedArticlesViewController.self, action: #selector(savedArticlesViewController?.clear))
            navigationItem.leftBarButtonItem = isAddButtonHidden ? clearButton : UIBarButtonItem(barButtonSystemItem: .add, target: readingListsViewController.self, action: #selector(readingListsViewController?.presentCreateReadingListViewController))
            navigationItem.leftBarButtonItem?.tintColor = theme.colors.link
        }
    }
    
    private var isSearchBarHidden: Bool = false {
        didSet {
            extendedNavBarView.isHidden = isSearchBarHidden
            if isSearchBarHidden {
                NSLayoutConstraint.deactivate(searchBarConstraints)
            } else {
                NSLayoutConstraint.activate(searchBarConstraints)
            }
            guard currentView != .readingLists else {
                return
            }
            navigationBar.setNavigationBarPercentHidden(0, extendedViewPercentHidden: isSearchBarHidden ? 1 : 0, animated: false)
            savedArticlesViewController?.updateScrollViewInsets()
            updateScrollViewInsets()
        }
    }
    
    private func addChild(_ vc: UIViewController?) {
        guard let vc = vc else {
            return
        }
        addChildViewController(vc)
        containerView.wmf_addSubviewWithConstraintsToEdges(vc.view)
        vc.didMove(toParentViewController: self)
    }
    
    private func removeChild(_ vc: UIViewController?) {
        guard let vc = vc else {
            return
        }
        vc.view.removeFromSuperview()
        vc.willMove(toParentViewController: nil)
        vc.removeFromParentViewController()
    }
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        navigationBar.addExtendedNavigationBarView(extendedNavBarView)
        navigationBar.addUnderNavigationBarView(underBarView)
        navigationBar.isBackVisible = false
        currentView = .savedArticles
        
        let allArticlesButtonTitle = WMFLocalizedString("saved-all-articles-title", value: "All articles", comment: "Title of the all articles button on Saved screen")
        allArticlesButton.setTitle(allArticlesButtonTitle, for: .normal)
        let readingListsButtonTitle = WMFLocalizedString("saved-reading-lists-title", value: "Reading lists", comment: "Title of the reading lists button on Saved screen")
        readingListsButton.setTitle(readingListsButtonTitle, for: .normal)

        searchBar.delegate = savedArticlesViewController
        searchBar.returnKeyType = .search
        searchBar.placeholder = WMFLocalizedString("saved-search-default-text", value:"Search ", comment:"tbd")
        
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .all
        
        super.viewDidLoad()
    }
    
    // MARK: - Sorting
    
    public weak var savedDelegate: SavedViewControllerDelegate?
    
    @IBAction func sortButonPressed() {
        savedDelegate?.saved(self, shouldShowSortAlert: true)
    }
    
    // MARK: - Themeable
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.chromeBackground
        
        savedArticlesViewController.apply(theme: theme)
        readingListsViewController?.apply(theme: theme)
        
        for button in toggleButtons {
            button.setTitleColor(theme.colors.secondaryText, for: .normal)
            button.tintColor = theme.colors.link
        }
        
        underBarView.backgroundColor = theme.colors.chromeBackground
        extendedNavBarView.backgroundColor = theme.colors.chromeBackground
        searchBar.setSearchFieldBackgroundImage(theme.searchBarBackgroundImage, for: .normal)
        searchBar.wmf_enumerateSubviewTextFields{ (textField) in
            textField.textColor = theme.colors.primaryText
            textField.keyboardAppearance = theme.keyboardAppearance
            textField.font = UIFont.systemFont(ofSize: 14)
        }
        searchBar.searchTextPositionAdjustment = UIOffset(horizontal: 7, vertical: 0)
        separatorView.backgroundColor = theme.colors.border
        
        navigationItem.leftBarButtonItem?.tintColor = theme.colors.link
        navigationItem.rightBarButtonItem?.tintColor = theme.colors.link
    }
}

// MARK: - BatchEditNavigationDelegate

extension SavedViewController: BatchEditNavigationDelegate {
    var currentTheme: Theme {
        return self.theme
    }
    
    func didChange(editingState: BatchEditingState, rightBarButton: UIBarButtonItem) {
        navigationItem.rightBarButtonItem = rightBarButton
        navigationItem.rightBarButtonItem?.tintColor = theme.colors.link
        sortButton.isEnabled = editingState == .cancelled || editingState == .none
        if editingState == .open && searchBar.isFirstResponder {
            searchBar.resignFirstResponder()
        }
    }
    
    func emptyStateDidChange(_ empty: Bool) {
        guard currentView != .readingLists else {
            return
        }
        isSearchBarHidden = empty
    }
}
