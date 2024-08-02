import WMFComponents

protocol SavedViewControllerDelegate: NSObjectProtocol {
    func savedWillShowSortAlert(_ saved: SavedViewController, from button: UIButton)
    func saved(_ saved: SavedViewController, searchBar: UISearchBar, textDidChange searchText: String)
    func saved(_ saved: SavedViewController, searchBarSearchButtonClicked searchBar: UISearchBar)
    func saved(_ saved: SavedViewController, searchBarTextDidBeginEditing searchBar: UISearchBar)
    func saved(_ saved: SavedViewController, searchBarTextDidEndEditing searchBar: UISearchBar)
}

// Wrapper for accessing View in Objective-C
@objc class WMFSavedViewControllerView: NSObject {
    @objc static let readingListsViewRawValue = SavedViewController.View.readingLists.rawValue
}

@objc(WMFSavedViewController)
class SavedViewController: ViewController {

    private var savedArticlesViewController: SavedArticlesCollectionViewController?
    
    @objc weak var tabBarDelegate: AppTabBarDelegate?
    
    private lazy var readingListsViewController: ReadingListsViewController? = {
        guard let dataStore = dataStore else {
            assertionFailure("dataStore is nil")
            return nil
        }
        let readingListsCollectionViewController = ReadingListsViewController(with: dataStore)
        return readingListsCollectionViewController
    }()

    @IBOutlet weak var containerView: UIView!
    @IBOutlet var searchView: UIView!
    @IBOutlet var underBarView: UIView!
    @IBOutlet var allArticlesButton: UnderlineButton!
    @IBOutlet var readingListsButton: UnderlineButton!
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet var toggleButtons: [UIButton]!
    @IBOutlet weak var progressContainerView: UIView!

    lazy var addReadingListBarButtonItem: UIBarButtonItem = {
        return SystemBarButton(with: .add, target: readingListsViewController.self, action: #selector(readingListsViewController?.presentCreateReadingListViewController))
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
            savedArticlesViewController = SavedArticlesCollectionViewController(with: newValue)
            savedArticlesViewController?.delegate = self
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Toggling views
    
    enum View: Int {
        case savedArticles, readingLists
    }
    
    @IBAction func toggleButtonPressed(_ sender: UIButton) {
        toggleButtons.first { $0.tag != sender.tag }?.isSelected = false
        sender.isSelected = true
        currentView = View(rawValue: sender.tag) ?? .savedArticles
        logTappedView(currentView)
    }

    @objc func toggleCurrentView(_ newViewRawValue: Int) {
        toggleButtons.first { $0.tag != newViewRawValue }?.isSelected = false
        for button in toggleButtons {
            if button.tag == newViewRawValue {
                button.isSelected = true
            } else {
                button.isSelected = false
            }
        }
        currentView = View(rawValue: newViewRawValue) ?? .savedArticles
    }

    private(set) var currentView: View = .savedArticles {
        didSet {
            searchBar.resignFirstResponder()
            switch currentView {
            case .savedArticles:
                removeChild(readingListsViewController)
                setSavedArticlesViewControllerIfNeeded()
                addSavedChildViewController(savedArticlesViewController)
                savedArticlesViewController?.editController.navigationDelegate = self
                readingListsViewController?.editController.navigationDelegate = nil
                savedDelegate = savedArticlesViewController
                scrollView = savedArticlesViewController?.collectionView
                activeEditableCollection = savedArticlesViewController
                extendedNavBarViewType = isCurrentViewEmpty ? .none : .search
                evaluateEmptyState()
                ReadingListsFunnel.shared.logTappedAllArticlesTab()
            case .readingLists :
                readingListsViewController?.editController.navigationDelegate = self
                savedArticlesViewController?.editController.navigationDelegate = nil
                removeChild(savedArticlesViewController)
                addSavedChildViewController(readingListsViewController)
                scrollView = readingListsViewController?.collectionView
                extendedNavBarViewType = .createNewReadingList
                activeEditableCollection = readingListsViewController
                extendedNavBarViewType = isCurrentViewEmpty ? .none : .createNewReadingList
                evaluateEmptyState()
                ReadingListsFunnel.shared.logTappedReadingListsTab()
            }
        }
    }

    private enum ExtendedNavBarViewType {
        case none
        case search
        case createNewReadingList
    }

    private var extendedNavBarViewType: ExtendedNavBarViewType = .none {
        didSet {
            navigationBar.removeExtendedNavigationBarView()
            switch extendedNavBarViewType {
            case .search:
                navigationBar.addExtendedNavigationBarView(searchView)
            case .createNewReadingList:
                if let createNewReadingListButtonView = readingListsViewController?.createNewReadingListButtonView {
                    navigationBar.addExtendedNavigationBarView(createNewReadingListButtonView)
                    createNewReadingListButtonView.apply(theme: theme)
                }
            default:
                break
            }
        }
    }

    private var isCurrentViewEmpty: Bool {
        guard let activeEditableCollection = activeEditableCollection else {
            return true
        }
        return activeEditableCollection.editController.isCollectionViewEmpty
    }

    private var activeEditableCollection: EditableCollection?
    
    private func addSavedChildViewController(_ vc: UIViewController?) {
        guard let vc = vc else {
            return
        }
        addChild(vc)
        containerView.wmf_addSubviewWithConstraintsToEdges(vc.view)
        vc.didMove(toParent: self)
    }
    
    private func removeChild(_ vc: UIViewController?) {
        guard let vc = vc else {
            return
        }
        vc.view.removeFromSuperview()
        vc.willMove(toParent: nil)
        vc.removeFromParent()
    }

    private func logTappedView(_ view: View) {
        switch view {
        case .savedArticles:
            NavigationEventsFunnel.shared.logEvent(action: .savedAll)
        case .readingLists:
            NavigationEventsFunnel.shared.logEvent(action: .savedLists)
        }
    }
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        navigationBar.addExtendedNavigationBarView(searchView)
        navigationBar.addUnderNavigationBarView(underBarView)
        navigationBar.displayType = .largeTitle
        navigationBar.isBarHidingEnabled = false
        navigationBar.isUnderBarViewHidingEnabled = false
        navigationBar.isExtendedViewHidingEnabled = true
        navigationBar.isShadowHidingEnabled = false
        navigationBar.isShadowBelowUnderBarView = true
        
        wmf_add(childController:savedProgressViewController, andConstrainToEdgesOfContainerView: progressContainerView)

        if activeEditableCollection == nil {
            currentView = .savedArticles
        }
        
        let allArticlesButtonTitle = WMFLocalizedString("saved-all-articles-title", value: "All articles", comment: "Title of the all articles button on Saved screen")
        allArticlesButton.setTitle(allArticlesButtonTitle, for: .normal)
        let readingListsButtonTitle = WMFLocalizedString("saved-reading-lists-title", value: "Reading lists", comment: "Title of the reading lists button on Saved screen")
        readingListsButton.setTitle(readingListsButtonTitle, for: .normal)
        allArticlesButton.titleLabel?.numberOfLines = 1
        readingListsButton.titleLabel?.numberOfLines = 1
        allArticlesButton.titleLabel?.lineBreakMode = .byTruncatingTail
        readingListsButton.titleLabel?.lineBreakMode = .byTruncatingTail

        searchBar.delegate = self
        searchBar.returnKeyType = .search
        searchBar.placeholder = WMFLocalizedString("saved-search-default-text", value:"Search saved articles", comment:"Placeholder text for the search bar in Saved")
        
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .all
        
        actionButtonType = .sort
        
        super.viewDidLoad()

        updateFonts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let savedArticlesWasNil = savedArticlesViewController == nil
        setSavedArticlesViewControllerIfNeeded()
        if savedArticlesViewController != nil,
            currentView == .savedArticles,
            savedArticlesWasNil {
            // reassign so activeEditableCollection gets reset
            currentView = .savedArticles
        }

        // Terrible hack to make back button text appropriate for iOS 14 - need to set the title on `WMFAppViewController`. For all app tabs, this is set in `viewWillAppear`.
        (parent as? WMFAppViewController)?.navigationItem.backButtonTitle = title
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts()
    }

    private func updateFonts() {
        actionButton.titleLabel?.font = WMFFont.for(.callout, compatibleWith: traitCollection)
    }
    
    private func setSavedArticlesViewControllerIfNeeded() {
        if let dataStore = dataStore,
            savedArticlesViewController == nil {
            savedArticlesViewController = SavedArticlesCollectionViewController(with: dataStore)
            savedArticlesViewController?.delegate = self
            savedArticlesViewController?.apply(theme: theme)
        }
    }
    
    private func evaluateEmptyState() {
        if activeEditableCollection == nil {
            wmf_showEmptyView(of: .noSavedPages, theme: theme, frame: view.bounds)
        } else {
            wmf_hideEmptyView()
        }
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
        
        savedArticlesViewController?.apply(theme: theme)
        readingListsViewController?.apply(theme: theme)
        savedProgressViewController?.apply(theme: theme)

        for button in toggleButtons {
            button.setTitleColor(theme.colors.secondaryText, for: .normal)
            button.tintColor = theme.colors.link
        }
        
        underBarView.backgroundColor = theme.colors.paperBackground
        searchView.backgroundColor = theme.colors.paperBackground
        searchBar.apply(theme: theme)

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
        defer {
            navigationBar.updateNavigationItems()
        }
        navigationItem.rightBarButtonItem = rightBarButton
        navigationItem.rightBarButtonItem?.tintColor = theme.colors.link
        let editingStates: [EditingState] = [.swiping, .open, .editing]
        let isEditing = editingStates.contains(newEditingState)
        actionButton.isEnabled = !isEditing
        if newEditingState == .open,
            let batchEditToolbar = savedArticlesViewController?.editController.batchEditToolbarView,
            let contentView = containerView,
            let appTabBar = tabBarDelegate?.tabBar {
                accessibilityElements = [navigationBar, batchEditToolbar, contentView, appTabBar]
        } else {
            accessibilityElements = []
        }
        guard isEditing else {
            return
        }
        if searchBar.isFirstResponder {
            searchBar.resignFirstResponder()
        }
        ReadingListsFunnel.shared.logTappedEditButton()
    }
    
    func newEditingState(for currentEditingState: EditingState, fromEditBarButtonWithSystemItem systemItem: UIBarButtonItem.SystemItem) -> EditingState {
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
        if empty {
            extendedNavBarViewType = .none
        } else {
            extendedNavBarViewType = currentView == .savedArticles ? .search : .createNewReadingList
        }
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

extension SavedViewController: ReadingListEntryCollectionViewControllerDelegate {
    func readingListEntryCollectionViewController(_ viewController: ReadingListEntryCollectionViewController, didUpdate collectionView: UICollectionView) {
    }
    
    func readingListEntryCollectionViewControllerDidChangeEmptyState(_ viewController: ReadingListEntryCollectionViewController) {
    }
    
    func readingListEntryCollectionViewControllerDidSelectArticleURL(_ articleURL: URL, viewController: ReadingListEntryCollectionViewController) {
        navigate(to: articleURL)
    }
    
}
