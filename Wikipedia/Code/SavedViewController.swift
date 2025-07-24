import WMFComponents
import WMFData

protocol SavedViewControllerDelegate: NSObjectProtocol {
    func savedWillShowSortAlert(_ saved: SavedViewController, from button: UIBarButtonItem)
    func saved(_ saved: SavedViewController, searchBar: UISearchBar, textDidChange searchText: String)
    func saved(_ saved: SavedViewController, searchBarSearchButtonClicked searchBar: UISearchBar)
    func saved(_ saved: SavedViewController, searchBarTextDidBeginEditing searchBar: UISearchBar)
    func saved(_ saved: SavedViewController, searchBarTextDidEndEditing searchBar: UISearchBar)
    func saved(_ saved: SavedViewController, scopeBarIndexDidChange searchBar: UISearchBar)
}

// Wrapper for accessing View in Objective-C
@objc class WMFSavedViewControllerView: NSObject {
    @objc static let readingListsViewRawValue = SavedViewController.View.readingLists.rawValue
}

@objc(WMFSavedViewController)
class SavedViewController: ThemeableViewController, WMFNavigationBarConfiguring, WMFNavigationBarHiding {

    private var savedArticlesViewController: SavedArticlesCollectionViewController?
    
    @objc weak var tabBarDelegate: AppTabBarDelegate?
    
    private lazy var readingListsViewController: ReadingListsViewController? = {
        guard let dataStore = dataStore else {
            assertionFailure("dataStore is nil")
            return nil
        }
        let readingListsCollectionViewController = ReadingListsViewController(with: dataStore)
        readingListsCollectionViewController.delegate = self
        return readingListsCollectionViewController
    }()

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var progressContainerView: UIView!

    lazy var addReadingListBarButtonItem: UIBarButtonItem = {
        return SystemBarButton(with: .add, target: readingListsViewController.self, action: #selector(readingListsViewController?.presentCreateReadingListViewController))
    }()
    
    fileprivate lazy var savedProgressViewController: SavedProgressViewController? = SavedProgressViewController.wmf_initialViewControllerFromClassStoryboard()

    public weak var savedDelegate: SavedViewControllerDelegate?
    
    var topSafeAreaOverlayView: UIView?
    var topSafeAreaOverlayHeightConstraint: NSLayoutConstraint?
    
    private var allArticlesSearchBarPlaceholder: String {
        WMFLocalizedString("saved-search-default-text", value:"Search saved articles", comment:"Placeholder text for the search bar in Saved. Displayed in All Articles list.")
    }
    
    // Properties needed for Profile Button
    
    private var _yirCoordinator: YearInReviewCoordinator?
    var yirCoordinator: YearInReviewCoordinator? {
        
        guard let navigationController,
              let yirDataController,
              let dataStore else {
            return nil
        }

        guard let existingYirCoordinator = _yirCoordinator else {
            _yirCoordinator = YearInReviewCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore, dataController: yirDataController)
            _yirCoordinator?.badgeDelegate = self
            return _yirCoordinator
        }
        
        return existingYirCoordinator
    }
    
    private var _tabsCoordinator: TabsOverviewCoordinator?
    private var tabsCoordinator: TabsOverviewCoordinator? {
        guard let navigationController, let dataStore else { return nil }
        _tabsCoordinator = TabsOverviewCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore)
        return _tabsCoordinator
    }
    
    private var _profileCoordinator: ProfileCoordinator?
    private var profileCoordinator: ProfileCoordinator? {
        
        guard let navigationController,
        let yirCoordinator = self.yirCoordinator,
            let dataStore else {
            return nil
        }
        
        guard let existingProfileCoordinator = _profileCoordinator else {
            _profileCoordinator = ProfileCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore, donateSouce: .savedProfile, logoutDelegate: self, sourcePage: ProfileCoordinatorSource.saved, yirCoordinator: yirCoordinator)
            _profileCoordinator?.badgeDelegate = self
            return _profileCoordinator
        }
        
        return existingProfileCoordinator
    }
    
    private var yirDataController: WMFYearInReviewDataController? {
        return try? WMFYearInReviewDataController()
    }

    // MARK: - Initalization and setup
    
    @objc public var dataStore: MWKDataStore? {
        didSet {
            guard let newValue = dataStore else {
                assertionFailure("cannot set dataStore to nil")
                return
            }
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

    private(set) var currentView: View = .savedArticles {
        didSet {
            switch currentView {
            case .savedArticles:
                removeChild(readingListsViewController)
                setSavedArticlesViewControllerIfNeeded()
                addSavedChildViewController(savedArticlesViewController)
                savedArticlesViewController?.editController.navigationDelegate = self
                readingListsViewController?.editController.navigationDelegate = nil
                savedDelegate = savedArticlesViewController
                activeEditableCollection = savedArticlesViewController
                evaluateEmptyState()
                ReadingListsFunnel.shared.logTappedAllArticlesTab()
                if let searchBar = navigationItem.searchController?.searchBar {
                    searchBar.placeholder = allArticlesSearchBarPlaceholder
                }
            case .readingLists :
                removeChild(savedArticlesViewController)
                addSavedChildViewController(readingListsViewController)
                savedArticlesViewController?.editController.navigationDelegate = nil
                readingListsViewController?.editController.navigationDelegate = self
                savedDelegate = readingListsViewController
                activeEditableCollection = readingListsViewController
                evaluateEmptyState()
                ReadingListsFunnel.shared.logTappedReadingListsTab()
                if let searchBar = navigationItem.searchController?.searchBar {
                    searchBar.placeholder = WMFLocalizedString("saved-reading-lists-search-placeholder", value: "Search reading lists", comment: "Search bar placeholder on Saved articles tab. Displayed in Reading Lists list.")
                }
            }
            
            configureNavigationBar()
        }
    }

    private enum ExtendedNavBarViewType {
        case none
        case search
        case createNewReadingList
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
        super.viewDidLoad()

        wmf_add(childController:savedProgressViewController, andConstrainToEdgesOfContainerView: progressContainerView)

        if activeEditableCollection == nil {
            currentView = .savedArticles
        }

        if let collectionView = savedArticlesViewController?.collectionView {
            setupTopSafeAreaOverlay(scrollView: collectionView)
        }
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
        
        configureNavigationBar()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        ArticleTabsFunnel.shared.logIconImpression(interface: .saved, project: nil)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 18, *) {
            if UIDevice.current.userInterfaceIdiom == .pad {
                if previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass {
                    configureNavigationBar()
                }
            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.calculateTopSafeAreaOverlayHeight()
        }
    }
    
    private func configureNavigationBar() {
        
        var titleConfig: WMFNavigationBarTitleConfig = WMFNavigationBarTitleConfig(title: CommonStrings.savedTabTitle, customView: nil, alignment: .leadingCompact)
        extendedLayoutIncludesOpaqueBars = false
        if #available(iOS 18, *) {
            if UIDevice.current.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .regular {
                titleConfig = WMFNavigationBarTitleConfig(title: CommonStrings.savedTabTitle, customView: nil, alignment: .leadingLarge)
                extendedLayoutIncludesOpaqueBars = true
            }
        }
        
        let profileButtonConfig: WMFNavigationBarProfileButtonConfig?
        let tabsButtonConfig: WMFNavigationBarTabsButtonConfig?
        if let dataStore {
            profileButtonConfig = self.profileButtonConfig(target: self, action: #selector(userDidTapProfile), dataStore: dataStore, yirDataController: yirDataController, leadingBarButtonItem: nil)
            tabsButtonConfig = self.tabsButtonConfig(target: self, action: #selector(userDidTapTabs), dataStore: dataStore, leadingBarButtonItem: moreBarButtonItem)
        } else {
            profileButtonConfig = nil
            tabsButtonConfig = nil
        }
        
        let allArticlesButtonTitle = WMFLocalizedString("saved-all-articles-title", value: "All articles", comment: "Title of the all articles button on Saved screen")
        let readingListsButtonTitle = WMFLocalizedString("saved-reading-lists-title", value: "Reading lists", comment: "Title of the reading lists button on Saved screen")
        
        let searchConfig = WMFNavigationBarSearchConfig(searchResultsController: nil, searchControllerDelegate: nil, searchResultsUpdater: nil, searchBarDelegate: self, searchBarPlaceholder: allArticlesSearchBarPlaceholder, showsScopeBar: true, scopeButtonTitles: [allArticlesButtonTitle, readingListsButtonTitle])
        
        var hidesNavigationBarOnScroll = true
        switch self.currentView {
        case .savedArticles:
            if let savedArticlesViewController, savedArticlesViewController.isEmpty {
                hidesNavigationBarOnScroll = false
            }
        case .readingLists:
            if let readingListsViewController, readingListsViewController.isEmpty {
                hidesNavigationBarOnScroll = false
            }
        }

        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: nil, profileButtonConfig: profileButtonConfig, tabsButtonConfig: tabsButtonConfig, searchBarConfig: searchConfig, hideNavigationBarOnScroll: hidesNavigationBarOnScroll)
    }
    
    @objc func userDidTapTabs() {
        _ = tabsCoordinator?.start()
        ArticleTabsFunnel.shared.logIconClick(interface: .saved, project: nil)
    }
    
    @objc func userDidTapProfile() {
        
        guard let dataStore else {
            return
        }
        
        guard let languageCode = dataStore.languageLinkController.appLanguage?.languageCode,
              let metricsID = DonateCoordinator.metricsID(for: .savedProfile, languageCode: languageCode) else {
            return
        }
        
        DonateFunnel.shared.logSavedProfile(metricsID: metricsID)
              
        profileCoordinator?.start()
    }
    
    private func updateProfileButton() {
        
        guard let dataStore else {
            return
        }
        
        let editController: CollectionViewEditController?
        switch self.currentView {
        case .savedArticles:
            editController = self.savedArticlesViewController?.editController
        case .readingLists:
            editController = self.readingListsViewController?.editController
        }
        
        guard let editController else {
            return
        }
        
        guard !editController.isBatchEditing else {
            return
        }
        
        let config = self.profileButtonConfig(target: self, action: #selector(userDidTapProfile), dataStore: dataStore, yirDataController: yirDataController, leadingBarButtonItem: nil)
        updateNavigationBarProfileButton(needsBadge: config.needsBadge, needsBadgeLabel: CommonStrings.profileButtonBadgeTitle, noBadgeLabel: CommonStrings.profileButtonTitle)
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

        addReadingListBarButtonItem.tintColor = theme.colors.link
        
        themeNavigationBarLeadingTitleView()
        themeTopSafeAreaOverlay()

        if let rightBarButtonItems = navigationItem.rightBarButtonItems {
            for barButtonItem in rightBarButtonItems {
                barButtonItem.tintColor = theme.colors.link
            }
        }
        
        profileCoordinator?.theme = theme
        updateProfileButton()
    }
    
    private lazy var moreBarButtonItem: UIBarButtonItem = {
        let button = UIBarButtonItem(image: WMFSFSymbolIcon.for(symbol: .ellipsisCircle), primaryAction: nil, menu: overflowMenu)
        button.accessibilityLabel = CommonStrings.moreButton
        return button
    }()
    
    var overflowMenu: UIMenu {
        
        let sortAction = UIAction(title: CommonStrings.sortActionTitle, image: nil, handler: { _ in
            self.didTapSort()
        })
        
        let editAction = UIAction(title: CommonStrings.editContextMenuTitle, image: nil, handler: { _ in
            switch self.currentView {
            case .savedArticles:
                self.savedArticlesViewController?.editController.changeEditingState(to: .open)
            case .readingLists:
                self.readingListsViewController?.editController.changeEditingState(to: .open)
            }
        })
        
        
        let mainMenu = UIMenu(title: String(), children: [sortAction, editAction])

        return mainMenu
    }
    
    private lazy var fixedSpaceBarButtonItem: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        button.width = 20
        return button
    }()
    
    func didTapSort() {
        savedDelegate?.savedWillShowSortAlert(self, from: moreBarButtonItem)
    }
}

// MARK: - NavigationDelegate

extension SavedViewController: CollectionViewEditControllerNavigationDelegate {
    var currentTheme: Theme {
        return self.theme
    }
    
    func didChangeEditingState(from oldEditingState: EditingState, to newEditingState: EditingState, rightBarButton: UIBarButtonItem?, leftBarButton: UIBarButtonItem?) {

        guard let editButton = rightBarButton else {
            return
        }
        
        let moreBarButtonItem = self.moreBarButtonItem
        if newEditingState == .open {
            navigationItem.rightBarButtonItems = [editButton]
        } else {
            configureNavigationBar() // Switches back to More and Profile
        }
        
        moreBarButtonItem.tintColor = theme.colors.link
        editButton.tintColor = theme.colors.link
        
        let editingStates: [EditingState] = [.swiping, .open, .editing]
        let isEditing = editingStates.contains(newEditingState)
        if newEditingState == .open,
            let batchEditToolbar = savedArticlesViewController?.editController.batchEditToolbarView,
            let contentView = containerView,
            let appTabBar = tabBarDelegate?.tabBar {
                accessibilityElements = [batchEditToolbar, contentView, appTabBar]
        } else {
            accessibilityElements = []
        }
        guard isEditing else {
            return
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
        // no-op
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
        savedDelegate?.saved(self, searchBarTextDidBeginEditing: searchBar)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        savedDelegate?.saved(self, searchBarTextDidEndEditing: searchBar)
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        if selectedScope == 0 {
            currentView = .savedArticles
        } else {
            currentView = .readingLists
        }
        logTappedView(currentView)
        
        searchBar.text = nil
        savedDelegate?.saved(self, scopeBarIndexDidChange: searchBar)
    }
    
    // Used in ReadingListEntryCollectionViewControllerDelegate & ReadingListsViewControllerDelegate
    func scrollViewDidScroll(scrollView: UIScrollView) {
        calculateNavigationBarHiddenState(scrollView: scrollView)
    }
}

extension SavedViewController: ReadingListEntryCollectionViewControllerDelegate {
    func setupReadingListDetailHeaderView(_ headerView: ReadingListDetailHeaderView) {
        assertionFailure("Unexpected")
    }
    
    func readingListEntryCollectionViewController(_ viewController: ReadingListEntryCollectionViewController, didUpdate collectionView: UICollectionView) {
    }
    
    func readingListEntryCollectionViewControllerDidChangeEmptyState(_ viewController: ReadingListEntryCollectionViewController) {
        configureNavigationBar()
    }
    
    func readingListEntryCollectionViewControllerDidSelectArticleURL(_ articleURL: URL, viewController: ReadingListEntryCollectionViewController) {
        
        guard let navigationController else {
            return
        }
        
        let coordinator = ArticleCoordinator(navigationController: navigationController, articleURL: articleURL, dataStore: dataStore ?? MWKDataStore.shared(), theme: theme, source: .undefined)
        coordinator.start()
    }
}

extension SavedViewController: ReadingListsViewControllerDelegate {
    func readingListsViewController(_ readingListsViewController: ReadingListsViewController, didAddArticles articles: [WMFArticle], to readingList: WMF.ReadingList) {
        // no-op
    }
    
    func readingListsViewControllerDidChangeEmptyState(_ readingListsViewController: ReadingListsViewController, isEmpty: Bool) {
        configureNavigationBar()
    }
    
}

extension SavedViewController: YearInReviewBadgeDelegate {
    func updateYIRBadgeVisibility() {
        updateProfileButton()
    }
}

// LogoutCoordinatorDelegate

extension SavedViewController: LogoutCoordinatorDelegate {
    func didTapLogout() {
        
        guard let dataStore else {
            return
        }
        
        wmf_showKeepSavedArticlesOnDevicePanelIfNeeded(triggeredBy: .logout, theme: theme) {
            dataStore.authenticationManager.logout(initiatedBy: .user)
        }
    }
}
