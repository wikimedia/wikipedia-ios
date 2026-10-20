import WMFComponents
import CocoaLumberjackSwift
import WMFData
import WMFNativeLocalizations
import WMFTestKitchen

// Wrapper for accessing View in Objective-C
@objc class WMFSavedViewControllerView: NSObject {
    @objc static let readingListsViewRawValue = SavedViewController.View.readingLists.rawValue
}

@objc(WMFSavedViewController)
class SavedViewController: ThemeableViewController, WMFNavigationBarConfiguring, WMFNavigationBarHiding {

    // MARK: - Segment coordinators

    private var allArticlesCoordinator: SavedAllArticlesCoordinator?
    private weak var allArticlesHostingController: UIViewController?
    private var allArticlesSortType: SortActionType = .byRecentlyAdded

    private var readingListsCoordinator: ReadingListsCoordinator?
    private weak var readingListsHostingController: UIViewController?

    @objc weak var tabBarDelegate: AppTabBarDelegate?

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var progressContainerView: UIView!

    fileprivate lazy var savedProgressViewController: SavedProgressViewController? = SavedProgressViewController.wmf_initialViewControllerFromClassStoryboard()

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

    private lazy var tabsCoordinator: TabsOverviewCoordinator? = { [weak self] in
        guard let self, let nav = self.navigationController, let dataStore else { return nil }
        return TabsOverviewCoordinator(
            navigationController: nav,
            theme: self.theme,
            dataStore: dataStore
        )
    }()

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
            guard dataStore != nil else {
                assertionFailure("cannot set dataStore to nil")
                return
            }
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
                removeReadingListsContent()
                setupAllArticlesContent()
                ReadingListsFunnel.shared.logTappedAllArticlesTab()
                if let searchBar = navigationItem.searchController?.searchBar {
                    searchBar.placeholder = allArticlesSearchBarPlaceholder
                }
            case .readingLists:
                removeAllArticlesContent()
                setupReadingListsContent()
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

    // MARK: - All Articles Content

    private func setupAllArticlesContent() {
        guard let navigationController = navigationController,
              let dataStore = dataStore else {
            return
        }

        // if already exists, exit early
        guard allArticlesHostingController == nil else {
            return
        }

        let coordinator = SavedAllArticlesCoordinator(
            navigationController: navigationController,
            dataStore: dataStore,
            theme: theme
        )
        
        coordinator.exitEditingModeAction = { [weak self] in
            self?.configureNavigationBar()
        }
        
        self.allArticlesCoordinator = coordinator

        let allArticlesVC = coordinator.contentViewController
        addChild(allArticlesVC)
        containerView.wmf_addSubviewWithConstraintsToEdges(allArticlesVC.view)
        allArticlesVC.didMove(toParent: self)
        self.allArticlesHostingController = allArticlesVC
    }

    private func removeAllArticlesContent() {
        guard let allArticlesVC = allArticlesHostingController else {
            return
        }
        allArticlesVC.view.removeFromSuperview()
        allArticlesVC.willMove(toParent: nil)
        allArticlesVC.removeFromParent()
        self.allArticlesHostingController = nil
        self.allArticlesCoordinator = nil
    }

    // MARK: - Reading Lists Content

    private var readingListsViewModel: WMFReadingListsViewModel? {
        readingListsCoordinator?.contentViewController.viewModel
    }

    private func setupReadingListsContent() {
        guard let navigationController, let dataStore else {
            return
        }

        guard readingListsHostingController == nil else {
            return
        }

        let coordinator = ReadingListsCoordinator(navigationController: navigationController, dataStore: dataStore, theme: theme)
        self.readingListsCoordinator = coordinator

        let readingListsVC = coordinator.contentViewController
        readingListsVC.viewModel.didUpdateEditingMode = { [weak self] isEditing in
            if !isEditing {
                self?.configureNavigationBar()
            }
        }
        readingListsVC.viewModel.didChangeState = { [weak self] _ in
            self?.configureNavigationBar()
        }

        addChild(readingListsVC)
        containerView.wmf_addSubviewWithConstraintsToEdges(readingListsVC.view)
        readingListsVC.didMove(toParent: self)
        self.readingListsHostingController = readingListsVC
    }

    private func removeReadingListsContent() {
        guard let readingListsVC = readingListsHostingController else {
            return
        }
        readingListsVC.view.removeFromSuperview()
        readingListsVC.willMove(toParent: nil)
        readingListsVC.removeFromParent()
        self.readingListsHostingController = nil
        self.readingListsCoordinator = nil
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
        view.accessibilityIdentifier = AccessibilityIdentifiers.Saved.view
        progressContainerView.accessibilityIdentifier = AccessibilityIdentifiers.Saved.progressView

        currentView = .savedArticles
        
        allArticlesSortType = getDefaultReadingListSortType() ?? .byRecentlyAdded

        registerForTraitChanges([UITraitPreferredContentSizeCategory.self, UITraitHorizontalSizeClass.self, UITraitVerticalSizeClass.self]) { [weak self] (viewController: Self, previousTraitCollection: UITraitCollection) in
            guard let self else { return }


            if #available(iOS 18, *) {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    if previousTraitCollection.horizontalSizeClass != self.traitCollection.horizontalSizeClass {
                        self.configureNavigationBar()
                    }
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if currentView == .savedArticles && allArticlesHostingController == nil {
            currentView = .savedArticles
        }

        configureNavigationBar()

        if navigationItem.searchController?.isActive == true {
            hideCustomLeadingLargeTitleLabel()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if !isMovingFromParent {
            navigationItem.searchController?.isActive = false
            hideCustomLeadingLargeTitleLabel()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ArticleTabsFunnel.shared.logIconImpression(interface: .saved, project: nil)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.calculateTopSafeAreaOverlayHeight()
        }
    }

    private lazy var searchBarIPadCustomizer = SearchBarIPadCustomizer(theme: theme)

    private func configureNavigationBar() {

        let titleConfig: WMFNavigationBarTitleConfig = WMFNavigationBarTitleConfig(title: CommonStrings.savedTabTitle, customView: nil, alignment: .customLeadingLarge)

        let profileButtonConfig: WMFNavigationBarProfileButtonConfig?
        let tabsButtonConfig: WMFNavigationBarTabsButtonConfig?
        if let dataStore {
            profileButtonConfig = self.profileButtonConfig(target: self, action: #selector(userDidTapProfile), dataStore: dataStore, yirDataController: yirDataController)
            tabsButtonConfig = self.tabsButtonConfig(target: self, action: #selector(userDidTapTabs), dataStore: dataStore, leadingBarButtonItem: moreBarButtonItem)
        } else {
            profileButtonConfig = nil
            tabsButtonConfig = nil
        }

        let allArticlesButtonTitle = WMFLocalizedString("saved-all-articles-title", value: "All articles", comment: "Title of the all articles button on Saved screen")
        let readingListsButtonTitle = WMFLocalizedString("saved-reading-lists-title", value: "Reading lists", comment: "Title of the reading lists button on Saved screen")

        let searchConfig = WMFNavigationBarSearchConfig(searchResultsController: nil, searchControllerDelegate: searchBarIPadCustomizer, searchResultsUpdater: nil, searchBarDelegate: self, searchBarPlaceholder: allArticlesSearchBarPlaceholder, showsScopeBar: true, scopeButtonTitles: [allArticlesButtonTitle, readingListsButtonTitle])

        var hidesNavigationBarOnScroll = true
        switch self.currentView {
        case .savedArticles:
            break
        case .readingLists:
            if readingListsViewModel?.state == .empty {
                hidesNavigationBarOnScroll = false
            }
        }

        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: nil, profileButtonConfig: profileButtonConfig, tabsButtonConfig: tabsButtonConfig, searchBarConfig: searchConfig, hideNavigationBarOnScroll: hidesNavigationBarOnScroll)
        
        searchBarIPadCustomizer.onClearTapped = { [weak self] searchController in
            guard let self,
            let searchBar = searchController?.searchBar else { return }
            self.searchBar(searchBar, textDidChange: "")
        }
        
        searchBarIPadCustomizer.onBackTapped = { [weak self] searchController in
            guard let self,
                  let searchBar = searchController?.searchBar else { return }
            self.searchBar(searchBar, textDidChange: "")
        }
    }

    @objc func userDidTapTabs() {
        tabsCoordinator?.start()
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
    
    @objc func userDidTapCancelEditing() {
        configureNavigationBar()

        switch currentView {
        case .savedArticles:
            if allArticlesCoordinator?.contentViewController.viewModel.isEditing == true {
                allArticlesCoordinator?.contentViewController.viewModel.toggleEditing()
            }
        case .readingLists:
            if readingListsViewModel?.isEditing == true {
                readingListsViewModel?.toggleEditing()
            }
        }
    }

    private func showCancelEditingButton() {
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(userDidTapCancelEditing))
        cancelButton.tintColor = theme.colors.primaryText
        cancelButton.accessibilityIdentifier = AccessibilityIdentifiers.Saved.editingCancelButton
        navigationItem.rightBarButtonItems = [cancelButton]
    }

    private func updateProfileButton() {

        guard let dataStore else {
            return
        }

        if currentView == .readingLists, readingListsViewModel?.isEditing == true {
            return
        }

        let config = self.profileButtonConfig(target: self, action: #selector(userDidTapProfile), dataStore: dataStore, yirDataController: yirDataController)
        updateNavigationBarProfileButton(needsBadge: config.needsBadge, needsBadgeLabel: CommonStrings.profileButtonBadgeTitle, noBadgeLabel: CommonStrings.profileButtonTitle)
    }

    // MARK: - Themeable

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        searchBarIPadCustomizer.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.chromeBackground

        savedProgressViewController?.apply(theme: theme)

        themeNavigationBarLeadingTitleView()
        themeNavigationBarCustomLeadingLargeTitle()
        themeTopSafeAreaOverlay()

        if let rightBarButtonItems = navigationItem.rightBarButtonItems {
            for barButtonItem in rightBarButtonItems {
                barButtonItem.tintColor = theme.colors.primaryText
            }
        }

        profileCoordinator?.theme = theme
        updateProfileButton()
        allArticlesCoordinator?.theme = theme
        readingListsCoordinator?.theme = theme
    }

    private lazy var moreBarButtonItem: UIBarButtonItem = {
        let button = UIBarButtonItem(image: WMFSFSymbolIcon.for(symbol: .ellipsis), primaryAction: nil, menu: overflowMenu)
        button.accessibilityLabel = CommonStrings.moreButton
        button.accessibilityIdentifier = AccessibilityIdentifiers.Saved.moreButton
        if #available(iOS 26.0, *) {
            button.sharesBackground = false
        }
        return button
    }()

    var overflowMenu: UIMenu {

        let sortAction = UIAction(title: CommonStrings.sortActionTitle, image: nil, handler: { _ in
            self.didTapSort()
        })

        let editAction = UIAction(title: CommonStrings.editContextMenuTitle, image: nil, handler: { [weak self] _ in
            
            guard let self else { return }
            
            switch self.currentView {
            case .savedArticles:
                self.allArticlesCoordinator?.contentViewController.viewModel.toggleEditing()
                if self.allArticlesCoordinator?.contentViewController.viewModel.isEditing == true {
                    self.showCancelEditingButton()
                    ReadingListsFunnel.shared.logTappedEditButton()
                } else {
                    self.configureNavigationBar()
                }
            case .readingLists:
                guard let readingListsViewModel = self.readingListsViewModel, readingListsViewModel.canEdit else {
                    return
                }
                readingListsViewModel.toggleEditing()
                if readingListsViewModel.isEditing {
                    self.showCancelEditingButton()
                } else {
                    self.configureNavigationBar()
                }
            }
        })


        let mainMenu = UIMenu(title: String(), options: .displayInline, children: [sortAction, editAction])

        return mainMenu
    }

    private lazy var fixedSpaceBarButtonItem: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        button.width = 20
        return button
    }()

    func didTapSort() {
        switch self.currentView {
        case .savedArticles:
            presentSortAlert(selected: allArticlesSortType) { [weak self] sortType in
                self?.allArticlesSortType = sortType
                self?.updateDefaultReadingListSortType(sortType: sortType)
                self?.allArticlesCoordinator?.contentViewController.viewModel.loadArticles()
            }
        case .readingLists:
            guard let readingListsViewModel else {
                return
            }
            let selected = SortActionType(rawValue: readingListsViewModel.sortOrder.rawValue) ?? .byTitle
            presentSortAlert(selected: selected) { [weak self] sortType in
                guard let sortOrder = WMFReadingListSortOrder(rawValue: sortType.rawValue) else {
                    return
                }
                self?.readingListsViewModel?.setSortOrder(sortOrder)
            }
        }
    }

    private func presentSortAlert(selected: SortActionType, onSelect: @escaping (SortActionType) -> Void) {
        let alert = UIAlertController(title: CommonStrings.sortAlertTitle, message: nil, preferredStyle: .actionSheet)
        alert.view.accessibilityIdentifier = AccessibilityIdentifiers.Saved.sortSheet

        let titleAction = UIAlertAction(title: CommonStrings.sortAlertOptionByTitle, style: .default) { _ in
            onSelect(.byTitle)
        }
        alert.addAction(titleAction)

        let recentlyAddedAction = UIAlertAction(title: CommonStrings.sortAlertOptionByRecentlyAdded, style: .default) { _ in
            onSelect(.byRecentlyAdded)
        }
        alert.addAction(recentlyAddedAction)

        let cancel = UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel)
        alert.addAction(cancel)

        if let popoverController = alert.popoverPresentationController {
            popoverController.barButtonItem = moreBarButtonItem
        }

        present(alert, animated: true)

        let checkedKey = "checked"
        switch selected {
        case .byRecentlyAdded:
            recentlyAddedAction.setValue(true, forKey: checkedKey)
        case .byTitle:
            titleAction.setValue(true, forKey: checkedKey)
        }
    }
    
    private func getDefaultReadingListSortType() -> SortActionType? {
        guard let readingList = dataStore?.viewContext.defaultReadingList,
              let sortOrder = readingList.sortOrder else {
            return nil
        }
        
        return SortActionType(rawValue: sortOrder.intValue)
    }
    
    private func updateDefaultReadingListSortType(sortType: SortActionType) {
        guard let dataStore,
              let readingList = dataStore.viewContext.defaultReadingList else {
            return
        }
        
        readingList.sortOrder = NSNumber(value: sortType.rawValue)
        if dataStore.viewContext.hasChanges {
            try? dataStore.viewContext.save()
        }
    }
}

// MARK: - UISearchBarDelegate

extension SavedViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        switch currentView {
        case .savedArticles:
            allArticlesCoordinator?.contentViewController.viewModel.searchText = searchText
        case .readingLists:
            readingListsViewModel?.searchText = searchText
            if searchText.isEmpty {
                searchBar.resignFirstResponder()
            }
        }
        if let sc = navigationItem.searchController {
            searchBarIPadCustomizer.updateClearButtonVisibility(text: searchText, for: sc)
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        hideCustomLeadingLargeTitleLabel()
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        showCustomLeadingLargeTitleLabel()
        switch currentView {
        case .savedArticles:
            allArticlesCoordinator?.contentViewController.viewModel.searchText = ""
            allArticlesCoordinator?.contentViewController.viewModel.loadArticles()
        case .readingLists:
            readingListsViewModel?.searchText = ""
        }
    }

    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        navigationItem.searchController?.isActive = false
        if selectedScope == 0 {
            currentView = .savedArticles
        } else {
            currentView = .readingLists
        }
        logTappedView(currentView)

        searchBar.text = nil
        searchBar.resignFirstResponder()
    }
}

extension SavedViewController: YearInReviewBadgeDelegate {
    func updateYIRBadgeVisibility() {
        updateProfileButton()
    }
}

// LogoutCoordinatorDelegate

extension SavedViewController: LogoutCoordinatorDelegate {
    func didTapLogout(authInstrument: InstrumentImpl) {

        guard let dataStore else {
            return
        }

        wmf_showKeepSavedArticlesOnDevicePanelIfNeeded(triggeredBy: .logout, theme: theme, authInstrument: authInstrument) {
            dataStore.authenticationManager.logout(initiatedBy: .user, authInstrument: authInstrument)
        }
    }
}
