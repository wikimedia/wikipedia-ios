import UIKit

protocol SavedViewControllerDelegate: NSObjectProtocol {
    func savedWillShowSortAlert(_ saved: SavedViewController, from button: UIButton)
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
    @IBOutlet var searchBar: UISearchBar!
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
            savedArticlesViewController = SavedArticlesViewController(with: newValue)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
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
    
    private var activeEditableCollection: EditableCollection?
    
    private var currentView: View = .savedArticles {
        didSet {
            searchBar.resignFirstResponder()
            switch currentView {
            case .savedArticles:
                removeChild(readingListsViewController)
                addChild(savedArticlesViewController)
                savedArticlesViewController.editController.navigationDelegate = self
                readingListsViewController?.editController.navigationDelegate = nil
                savedDelegate = savedArticlesViewController
                leftButtonType = .clear
                isSearchBarHidden = isSavedArticlesEmpty
                scrollView = savedArticlesViewController.collectionView
                activeEditableCollection = savedArticlesViewController
            case .readingLists :
                removeChild(savedArticlesViewController)
                addChild(readingListsViewController)
                readingListsViewController?.editController.navigationDelegate = self
                savedArticlesViewController.editController.navigationDelegate = nil
                leftButtonType = .add
                scrollView = readingListsViewController?.collectionView
                isSearchBarHidden = true
                activeEditableCollection = readingListsViewController
            }
        }
    }
    
    private var isSavedArticlesEmpty: Bool {
        return savedArticlesViewController.editController.isCollectionViewEmpty
    }
    
    private enum LeftButtonType {
        case add
        case clear
        case none
    }
    
    private var leftButtonType: LeftButtonType = .none {
        didSet {
            guard oldValue != leftButtonType else {
                return
            }
            switch leftButtonType {
            case .add:
                navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: readingListsViewController.self, action: #selector(readingListsViewController?.presentCreateReadingListViewController))
            case .clear:
                let clearButtonTitle = WMFLocalizedString("saved-clear-all", value: "Clear", comment: "Text of the button shown at the top of saved pages which deletes all the saved pages\n{{Identical|Clear}}")
                navigationItem.leftBarButtonItem = UIBarButtonItem(title: clearButtonTitle, style: .plain, target: savedArticlesViewController.self, action: #selector(savedArticlesViewController?.clear))
                navigationItem.leftBarButtonItem?.isEnabled = !isSavedArticlesEmpty
            default:
                navigationItem.leftBarButtonItem = nil
            }
            navigationItem.leftBarButtonItem?.tintColor = theme.colors.link
        }
    }

    private var isSearchBarHidden: Bool = false {
        didSet {
            if isSearchBarHidden {
                navigationBar.removeExtendedNavigationBarView()
            } else {
                navigationBar.addExtendedNavigationBarView(extendedNavBarView)
            }
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
        searchBar.placeholder = WMFLocalizedString("saved-search-default-text", value:"Search", comment:"Placeholder text for the search bar in Saved")
        
        sortButton.setTitle(CommonStrings.sortActionTitle, for: .normal)
        
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .all
        
        super.viewDidLoad()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        sortButton.titleLabel?.setFont(with: .system, style: .subheadline, traitCollection: traitCollection)
    }
    
    // MARK: - Sorting
    
    public weak var savedDelegate: SavedViewControllerDelegate?
    
    @IBAction func sortButonPressed(_ sender: UIButton) {
        savedDelegate?.savedWillShowSortAlert(self, from: sender)
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

// MARK: - NavigationDelegate

extension SavedViewController: CollectionViewEditControllerNavigationDelegate {
    var currentTheme: Theme {
        return self.theme
    }
    
    func didChangeEditingState(from oldEditingState: EditingState, to newEditingState: EditingState, rightBarButton: UIBarButtonItem, leftBarButton: UIBarButtonItem?) {
        navigationItem.rightBarButtonItem = rightBarButton
        navigationItem.rightBarButtonItem?.tintColor = theme.colors.link
        let editingStates: [EditingState] = [.swiping, .open, .editing]
        let isEditing = editingStates.contains(newEditingState)
        sortButton.isEnabled = !isEditing
        if isEditing {
            if searchBar.isFirstResponder {
                searchBar.resignFirstResponder()
            }
            leftButtonType = .none
        } else {
            leftButtonType = currentView == .savedArticles ? .clear : .add
        }
    }
    
    func willChangeEditingState(from oldEditingState: EditingState, to newEditingState: EditingState) {
        if newEditingState == .open {
            self.activeEditableCollection?.editController.changeEditingState(to: newEditingState)
        } else {
            self.activeEditableCollection?.editController.changeEditingState(to: newEditingState)
        }
    }
    
    func emptyStateDidChange(_ empty: Bool) {
        guard currentView != .readingLists else {
            return
        }
        isSearchBarHidden = empty
        navigationItem.leftBarButtonItem?.isEnabled = !isSavedArticlesEmpty
    }
}
