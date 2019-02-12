import UIKit

enum ReadingListDetailDisplayType {
    case modal, pushed
}

class ReadingListDetailViewController: ViewController {
    let dataStore: MWKDataStore
    let readingList: ReadingList
    
    let articlesCollectionViewController: ReadingListEntryCollectionViewController
    
    var updater: ArticleURLProviderEditControllerUpdater?
    private let readingListDetailUnderBarViewController: ReadingListDetailUnderBarViewController
    private var searchBarExtendedViewController: SearchBarExtendedViewController?
    private var displayType: ReadingListDetailDisplayType = .pushed
    
    init(for readingList: ReadingList, with dataStore: MWKDataStore, displayType: ReadingListDetailDisplayType = .pushed) {
        self.readingList = readingList
        self.dataStore = dataStore
        self.displayType = displayType
        readingListDetailUnderBarViewController = ReadingListDetailUnderBarViewController()
        articlesCollectionViewController = ReadingListEntryCollectionViewController(for: readingList, with: dataStore)
        articlesCollectionViewController.emptyViewType = .noSavedPagesInReadingList
        super.init()
        searchBarExtendedViewController = SearchBarExtendedViewController()
        searchBarExtendedViewController?.dataSource = self
        searchBarExtendedViewController?.delegate = self
        readingListDetailUnderBarViewController.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
    
    var shouldShowEditButtonsForEmptyState: Bool {
        return !readingList.isDefault
    }
    
    private lazy var savedProgressViewController: SavedProgressViewController? = SavedProgressViewController.wmf_initialViewControllerFromClassStoryboard()
    
    private lazy var progressContainerView: UIView = {
        let containerView = UIView()
        containerView.isUserInteractionEnabled = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // reminder: this height constraint gets deactivated by "wmf_add:andConstrainToEdgesOfContainerView:"
        containerView.addConstraint(containerView.heightAnchor.constraint(equalToConstant: 1))
        
        view.addConstraints([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }()
    
    private func setUpArticlesViewController() {
        addChild(articlesCollectionViewController)
        view.addSubview(articlesCollectionViewController.view)
        articlesCollectionViewController.view.translatesAutoresizingMaskIntoConstraints = false
        articlesCollectionViewController.edgesForExtendedLayout = .all
        scrollView = articlesCollectionViewController.collectionView
        NSLayoutConstraint.activate(
            [
                articlesCollectionViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
                articlesCollectionViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                articlesCollectionViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                articlesCollectionViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ]
        )
        articlesCollectionViewController.didMove(toParent: self)
        articlesCollectionViewController.delegate = self
        articlesCollectionViewController.editController.navigationDelegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpArticlesViewController()
        
        navigationBar.title = readingList.name
        navigationBar.addUnderNavigationBarView(readingListDetailUnderBarViewController.view)
        navigationBar.underBarViewPercentHiddenForShowingTitle = 0.6
        navigationBar.isBarHidingEnabled = false
        navigationBar.isUnderBarViewHidingEnabled = true
        navigationBar.isExtendedViewHidingEnabled = true
        addExtendedView()
        
        if displayType == .modal {
            navigationItem.leftBarButtonItem = UIBarButtonItem.wmf_buttonType(WMFButtonType.X, target: self, action: #selector(dismissController))
            title = readingList.name
        }
        
        wmf_add(childController: savedProgressViewController, andConstrainToEdgesOfContainerView: progressContainerView)
        updater = ArticleURLProviderEditControllerUpdater(articleURLProvider: articlesCollectionViewController, collectionView: articlesCollectionViewController.collectionView, editController: articlesCollectionViewController.editController)
    }
    
    private func addExtendedView() {
        guard let extendedView = searchBarExtendedViewController?.view else {
            return
        }
        navigationBar.addExtendedNavigationBarView(extendedView)
    }
    
    @objc private func dismissController() {
        dismiss(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        readingListDetailUnderBarViewController.setup(for: readingList, listLimit: dataStore.viewContext.wmf_readingListsConfigMaxListsPerUser, entryLimit: dataStore.viewContext.wmf_readingListsConfigMaxEntriesPerList.intValue)
    }
    
    // MARK: - Theme
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        articlesCollectionViewController.apply(theme: theme)
        readingListDetailUnderBarViewController.apply(theme: theme)
        searchBarExtendedViewController?.apply(theme: theme)
        savedProgressViewController?.apply(theme: theme)
    }
}

// MARK: - NavigationDelegate

extension ReadingListDetailViewController: CollectionViewEditControllerNavigationDelegate {
    var currentTheme: Theme {
        return theme
    }
    
    func newEditingState(for currentEditingState: EditingState, fromEditBarButtonWithSystemItem systemItem: UIBarButtonItem.SystemItem) -> EditingState {
        let newEditingState: EditingState
        
        switch currentEditingState {
        case .open:
            newEditingState = .closed
        case .swiping:
            newEditingState = .open
        case .editing where systemItem == .cancel:
            newEditingState = .cancelled
        case .editing where systemItem == .done:
            newEditingState = .done
        case .empty:
            newEditingState = .editing
        default:
            newEditingState = .open
        }
        
        return newEditingState
    }
    
    func didChangeEditingState(from oldEditingState: EditingState, to newEditingState: EditingState, rightBarButton: UIBarButtonItem?, leftBarButton: UIBarButtonItem?) {
        navigationItem.rightBarButtonItem = rightBarButton
        navigationItem.rightBarButtonItem?.tintColor = theme.colors.link // no need to do a whole apply(theme:) pass
        
        if displayType == .pushed {
            navigationItem.leftBarButtonItem = leftBarButton
            navigationItem.leftBarButtonItem?.tintColor = theme.colors.link
        }
        
        switch newEditingState {
        case .editing:
            fallthrough
        case .open where articlesCollectionViewController.isEmpty:
            readingListDetailUnderBarViewController.beginEditing()
        case .done:
            readingListDetailUnderBarViewController.finishEditing()
        case .closed where articlesCollectionViewController.isEmpty:
            fallthrough
        case .cancelled:
            readingListDetailUnderBarViewController.cancelEditing()
        default:
            break
        }
    }
}

// MARK: - ReadingListDetailUnderBarViewControllerDelegate

extension ReadingListDetailViewController: ReadingListDetailUnderBarViewControllerDelegate {
    func readingListDetailUnderBarViewController(_ underBarViewController: ReadingListDetailUnderBarViewController, didEdit name: String?, description: String?) {
        dataStore.readingListsController.updateReadingList(readingList, with: name, newDescription: description)
        title = name
    }
    
    func readingListDetailUnderBarViewController(_ underBarViewController: ReadingListDetailUnderBarViewController, didBeginEditing textField: UITextField) {
        articlesCollectionViewController.editController.isTextEditing = true
    }
    
    func readingListDetailUnderBarViewController(_ underBarViewController: ReadingListDetailUnderBarViewController, titleTextFieldTextDidChange textField: UITextField) {
        navigationItem.rightBarButtonItem?.isEnabled = textField.text?.wmf_hasNonWhitespaceText ?? false
    }
    
    func readingListDetailUnderBarViewController(_ underBarViewController: ReadingListDetailUnderBarViewController, titleTextFieldWillClear textField: UITextField) {
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
}

// MARK: - SearchBarExtendedViewControllerDataSource

extension ReadingListDetailViewController: SearchBarExtendedViewControllerDataSource {
    func returnKeyType(for searchBar: UISearchBar) -> UIReturnKeyType {
        return .search
    }
    
    func placeholder(for searchBar: UISearchBar) -> String? {
        return WMFLocalizedString("search-reading-list-placeholder-text", value: "Search reading list", comment: "Placeholder text for the search bar in reading list detail view.")
    }
    
    func isSeparatorViewHidden(above searchBar: UISearchBar) -> Bool {
        return true
    }
}

// MARK: - SearchBarExtendedViewControllerDelegate

extension ReadingListDetailViewController: SearchBarExtendedViewControllerDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        articlesCollectionViewController.updateSearchString(searchText)
        
        if searchText.isEmpty {
            makeSearchBarResignFirstResponder(searchBar)
        }
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        makeSearchBarResignFirstResponder(searchBar)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        navigationBar.isExtendedViewHidingEnabled = false
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        makeSearchBarResignFirstResponder(searchBar)
    }
    
    private func makeSearchBarResignFirstResponder(_ searchBar: UISearchBar) {
        searchBar.text = ""
        articlesCollectionViewController.updateSearchString("")
        searchBar.resignFirstResponder()
        navigationBar.isExtendedViewHidingEnabled = true
    }
    
    func textStyle(for button: UIButton) -> DynamicTextStyle {
        return .body
    }
    
    func buttonType(for button: UIButton, currentButtonType: SearchBarExtendedViewButtonType?) -> SearchBarExtendedViewButtonType? {
        switch currentButtonType {
        case nil:
            return .sort
        case .cancel?:
            return .sort
        case .sort?:
            return .cancel
        }
    }
    
    func buttonWasPressed(_ button: UIButton, buttonType: SearchBarExtendedViewButtonType?, searchBar: UISearchBar) {
        guard let buttonType = buttonType else {
            return
        }
        switch buttonType {
        case .sort:
            articlesCollectionViewController.presentSortAlert(from: button)
        case .cancel:
            makeSearchBarResignFirstResponder(searchBar)
        }
    }
}

// MARK: - ReadingListEntryCollectionViewControllerDelegate

extension ReadingListDetailViewController: ReadingListEntryCollectionViewControllerDelegate {
    func articlesCollectionViewController(_ viewController: ReadingListEntryCollectionViewController, didUpdate collectionView: UICollectionView) {
        readingListDetailUnderBarViewController.reconfigureAlert(for: readingList)
        readingListDetailUnderBarViewController.updateArticleCount(readingList.countOfEntries)
    }
    
    func articlesCollectionViewControllerDidChangeEmptyState(_ viewController: ReadingListEntryCollectionViewController) {
        let isReadingListEmpty = readingList.countOfEntries == 0
        let isEmptyStateMatchingReadingListEmptyState = viewController.isEmpty == isReadingListEmpty
        if !isEmptyStateMatchingReadingListEmptyState {
            viewController.isEmpty = isReadingListEmpty
        }
        if viewController.isEmpty {
            title = readingList.name
            navigationBar.removeExtendedNavigationBarView()
        } else {
            addExtendedView()
        }
        viewController.updateScrollViewInsets()
    }
}
