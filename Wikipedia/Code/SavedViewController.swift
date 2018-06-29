import UIKit

protocol SavedViewControllerDelegate: NSObjectProtocol {
    func savedWillShowSortAlert(_ saved: SavedViewController, from button: UIButton)
    func saved(_ saved: SavedViewController, searchBar: UISearchBar, textDidChange searchText: String)
    func saved(_ saved: SavedViewController, searchBarSearchButtonClicked searchBar: UISearchBar)
    func saved(_ saved: SavedViewController, searchBarTextDidBeginEditing searchBar: UISearchBar)
    func saved(_ saved: SavedViewController, searchBarTextDidEndEditing searchBar: UISearchBar)
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
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet var toggleButtons: [UIButton]!
    @IBOutlet weak var progressContainerView: UIView!

    lazy var addReadingListBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .add, target: readingListsViewController.self, action: #selector(readingListsViewController?.presentCreateReadingListViewController))
    }()
    
    fileprivate lazy var savedProgressViewController: SavedProgressViewController? = SavedProgressViewController.wmf_initialViewControllerFromClassStoryboard()

    public weak var savedDelegate: SavedViewControllerDelegate?
    
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
                leftButtonType = .none
                isSearchBarHidden = isSavedArticlesEmpty
                scrollView = savedArticlesViewController.collectionView
                activeEditableCollection = savedArticlesViewController
            case .readingLists :
                readingListsViewController?.editController.navigationDelegate = self
                savedArticlesViewController.editController.navigationDelegate = nil
                removeChild(savedArticlesViewController)
                addChild(readingListsViewController)
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
        case none
    }
    
    private var leftButtonType: LeftButtonType = .none {
        didSet {
            guard oldValue != leftButtonType else {
                return
            }
            switch leftButtonType {
            case .add:
                navigationItem.leftBarButtonItems = [addReadingListBarButtonItem]
            default:
                navigationItem.leftBarButtonItems = []
            }
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
        navigationBar.isBarHidingEnabled = false
        navigationBar.isUnderBarViewHidingEnabled = false
        navigationBar.isExtendedViewHidingEnabled = true
        
        wmf_add(childController:savedProgressViewController, andConstrainToEdgesOfContainerView: progressContainerView)

        currentView = .savedArticles
        
        let allArticlesButtonTitle = WMFLocalizedString("saved-all-articles-title", value: "All articles", comment: "Title of the all articles button on Saved screen")
        allArticlesButton.setTitle(allArticlesButtonTitle, for: .normal)
        let readingListsButtonTitle = WMFLocalizedString("saved-reading-lists-title", value: "Reading lists", comment: "Title of the reading lists button on Saved screen")
        readingListsButton.setTitle(readingListsButtonTitle, for: .normal)

        searchBar.delegate = self
        searchBar.returnKeyType = .search
        searchBar.placeholder = WMFLocalizedString("saved-search-default-text", value:"Search", comment:"Placeholder text for the search bar in Saved")
        
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .all
        
        actionButtonType = .sort
        
        super.viewDidLoad()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        actionButton.titleLabel?.font = UIFont.wmf_font(.body, compatibleWithTraitCollection: traitCollection)
    }
    
    // MARK: - Sorting and searching
    
    private enum ActionButtonType {
        case sort
        case cancel
    }
    
    private var actionButtonType: ActionButtonType = .sort {
        didSet {
            switch actionButtonType {
            case .sort:
                actionButton.setTitle(CommonStrings.sortActionTitle, for: .normal)
            case .cancel:
                actionButton.setTitle(CommonStrings.cancelActionTitle, for: .normal)
            }
        }
    }
    
    @IBAction func actionButonPressed(_ sender: UIButton) {
        switch actionButtonType {
        case .sort:
            savedDelegate?.savedWillShowSortAlert(self, from: sender)
        case .cancel:
            searchBar.resignFirstResponder()
        }
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
        savedProgressViewController?.apply(theme: theme)
        
        for button in toggleButtons {
            button.setTitleColor(theme.colors.secondaryText, for: .normal)
            button.tintColor = theme.colors.link
        }
        
        underBarView.backgroundColor = theme.colors.chromeBackground
        extendedNavBarView.backgroundColor = theme.colors.chromeBackground
        searchBar.apply(theme: theme)
        separatorView.backgroundColor = theme.colors.border

        addReadingListBarButtonItem.tintColor = theme.colors.link
        
        navigationItem.rightBarButtonItem?.tintColor = theme.colors.link
    }
}

// MARK: - NavigationDelegate

extension SavedViewController: CollectionViewEditControllerNavigationDelegate {
    var currentTheme: Theme {
        return self.theme
    }
    
    func didChangeEditingState(from oldEditingState: EditingState, to newEditingState: EditingState, rightBarButton: UIBarButtonItem?, leftBarButton: UIBarButtonItem?) {
        navigationItem.rightBarButtonItem = rightBarButton
        navigationItem.rightBarButtonItem?.tintColor = theme.colors.link
        let editingStates: [EditingState] = [.swiping, .open, .editing]
        let isEditing = editingStates.contains(newEditingState)
        actionButton.isEnabled = !isEditing
        if isEditing {
            if searchBar.isFirstResponder {
                searchBar.resignFirstResponder()
            }
            leftButtonType = .none
        } else {
            leftButtonType = currentView == .savedArticles ? .none : .add
        }
    }
    
    func newEditingState(for currentEditingState: EditingState, fromEditBarButtonWithSystemItem systemItem: UIBarButtonSystemItem) -> EditingState {
        let newEditingState: EditingState
        
        switch currentEditingState {
        case .open:
            newEditingState = .closed
        default:
            newEditingState = .open
        }
        
        return newEditingState
    }
    
    func emptyStateDidChange(_ empty: Bool) {
        guard currentView != .readingLists else {
            return
        }
        isSearchBarHidden = empty
    }
}

// MARK: - UISearchBarDelegate

extension SavedViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        savedDelegate?.saved(self, searchBar: searchBar, textDidChange: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        savedDelegate?.saved(self, searchBarSearchButtonClicked: searchBar)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        actionButtonType = .cancel
        savedDelegate?.saved(self, searchBarTextDidBeginEditing: searchBar)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        actionButtonType = .sort
        savedDelegate?.saved(self, searchBarTextDidEndEditing: searchBar)
    }
}
