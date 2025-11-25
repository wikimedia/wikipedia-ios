import WMFComponents

enum ReadingListDetailDisplayType {
    case modal, pushed
}

class ReadingListDetailViewController: ThemeableViewController, WMFNavigationBarConfiguring {
    let dataStore: MWKDataStore
    let readingList: ReadingList
    
    let readingListEntryCollectionViewController: ReadingListEntryCollectionViewController
    var readingListDetailHeaderView: ReadingListDetailHeaderView? {
        return readingListEntryCollectionViewController.readingListDetailHeaderView
    }
    
    private var searchBarExtendedViewController: SearchBarExtendedViewController?
    private var displayType: ReadingListDetailDisplayType = .pushed
    
    // Import shared reading list properties
    private let fromImport: Bool
    private var seenSurveyPrompt: Bool = false
    private weak var importSurveyPromptTimer: Timer?
    private let importSurveyPromptDelay = TimeInterval(5)
    
    private typealias LanguageCode = String
    private let importSurveyURLs: [LanguageCode: URL?] = [
        "en": URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSf7W1Hs20HcP-Ho4T_Rlr8hdpT4oKxYQJD3rdE5RCINl5l6RQ/viewform?usp=sf_link"),
        "ar": URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSeKCRBtnF4V1Gwv2aRsJi8GppfofbiECU6XseZbVRbYijynfg/viewform?usp=sf_link"),
        "bn": URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSeY25GeA8dFOKlVCNpHc5zTUIYUeB3W6fntTitTIQRjl7BCQw/viewform?usp=sf_link"),
        "fr": URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSe_EXLDJxk-9y0ux-c9LERNou7CqhzoSZfL952PKH8bqCGMpA/viewform?usp=sf_link"),
        "de": URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSfS2-gQJtCUnFMJl-C0BdrWNxpb-PeXjoDeCR4z80gSCoA-RA/viewform?usp=sf_link"),
        "hi": URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSdnjiMH4L9eIpwuk3JLdsjKirvQ5GvLwp_8aaLKiESf-zhtHA/viewform?usp=sf_link"),
        "pt": URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSfbRhbf-cqmZC-vn1S_OTdsJ0zpiVW7vfFpWQgZtzQbU0dZEw/viewform?usp=sf_link"),
        "es": URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSelTK2ZeuEOk2T9P-E5OeKZoE9VvmCXLx9v3lc-A-onWXSsog/viewform?usp=sf_link"),
        "ur": URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSdPcGIn049-8g-JgxJ8lFRa8UGg4xcWdL6Na18GuDCUD8iUXA/viewform?usp=sf_link")]
    
    @objc convenience init(for readingList: ReadingList, with dataStore: MWKDataStore, fromImport: Bool, theme: Theme) {
        self.init(for: readingList, with: dataStore, displayType: .pushed, fromImport: fromImport)
        self.theme = theme
    }
    
    init(for readingList: ReadingList, with dataStore: MWKDataStore, displayType: ReadingListDetailDisplayType = .pushed, fromImport: Bool = false) {
        self.readingList = readingList
        self.dataStore = dataStore
        self.displayType = displayType
        self.fromImport = fromImport
        readingListEntryCollectionViewController = ReadingListEntryCollectionViewController(for: readingList, with: dataStore)
        readingListEntryCollectionViewController.emptyViewType = .noSavedPagesInReadingList
        readingListEntryCollectionViewController.needsDetailHeaderView = true
        super.init(nibName: nil, bundle: nil)
        searchBarExtendedViewController = SearchBarExtendedViewController()
        searchBarExtendedViewController?.dataSource = self
        searchBarExtendedViewController?.delegate = self
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
        addChild(readingListEntryCollectionViewController)
        view.addSubview(readingListEntryCollectionViewController.view)
        readingListEntryCollectionViewController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate(
            [
                readingListEntryCollectionViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
                readingListEntryCollectionViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                readingListEntryCollectionViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                readingListEntryCollectionViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ]
        )
        readingListEntryCollectionViewController.didMove(toParent: self)
        readingListEntryCollectionViewController.delegate = self
        readingListEntryCollectionViewController.editController.navigationDelegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpArticlesViewController()
        apply(theme: theme)
    }
    
    @objc private func dismissController() {
        dismiss(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if !readingList.isDefault {
            readingListEntryCollectionViewController.editController.isTextEditing = false
        }
        
        importSurveyPromptTimer?.invalidate()
        importSurveyPromptTimer = nil
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        showImportSharedReadingListSurveyPromptIfNeeded()
    }
    
    private func configureNavigationBar() {
        
        let titleConfig = WMFNavigationBarTitleConfig(title: readingList.name ?? "", customView: nil, alignment: .centerCompact)
        
        let closeButtonConfig: WMFNavigationBarCloseButtonConfig? = displayType == .modal ? WMFNavigationBarCloseButtonConfig(text: CommonStrings.cancelActionTitle, target: self, action: #selector(dismissController), alignment: .leading) : nil

        let searchBarPlaceholder = WMFLocalizedString("reading-list-detail-search-placeholder", value: "Search reading list", comment: "Placeholder on search bar for reading list detail view.")
        let searchConfig = WMFNavigationBarSearchConfig(searchResultsController: nil, searchControllerDelegate: nil, searchResultsUpdater: self, searchBarDelegate: nil, searchBarPlaceholder: searchBarPlaceholder, showsScopeBar: false, scopeButtonTitles: nil)
        
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: closeButtonConfig, profileButtonConfig: nil,tabsButtonConfig: nil,  searchBarConfig: searchConfig, hideNavigationBarOnScroll: false)
    }
    
    // MARK: - Theme
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        readingListEntryCollectionViewController.apply(theme: theme)
        readingListDetailHeaderView?.apply(theme: theme)
        searchBarExtendedViewController?.apply(theme: theme)
        savedProgressViewController?.apply(theme: theme)
    }
    
    private lazy var sortBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(title: CommonStrings.sortActionTitle, style: .plain, target: self, action: #selector(didTapSort(_:)))
    }()
    
    @objc func didTapSort(_ sender: UIBarButtonItem) {
        readingListEntryCollectionViewController.presentSortAlert(from: sender)
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
        
        if let editButton = rightBarButton {
            navigationItem.rightBarButtonItems = [editButton, sortBarButtonItem]
            rightBarButton?.tintColor = theme.colors.link // no need to do a whole apply(theme:) pass
            sortBarButtonItem.tintColor = theme.colors.link
        }

        if let rightBarButton, newEditingState == .open {
            navigationItem.rightBarButtonItems = [rightBarButton]
            navigationItem.leftBarButtonItem = nil
        } else {
            configureNavigationBar()
        }


        switch newEditingState {
        case .editing:
            fallthrough
        case .open where readingListEntryCollectionViewController.isEmpty:
            readingListDetailHeaderView?.beginEditing()
        case .done:
            readingListDetailHeaderView?.finishEditing()
        case .closed where readingListEntryCollectionViewController.isEmpty:
            fallthrough
        case .cancelled:
            readingListDetailHeaderView?.cancelEditing()
        default:
            break
        }
    }
}

// MARK: - ReadingListDetailUnderBarViewControllerDelegate

extension ReadingListDetailViewController: ReadingListDetailHeaderViewDelegate {
    func readingListDetailHeaderView(_ headerView: ReadingListDetailHeaderView, didEdit name: String?, description: String?) {
        dataStore.readingListsController.updateReadingList(readingList, with: name, newDescription: description)
        title = name
    }
    
    func readingListDetailHeaderView(_ headerView: ReadingListDetailHeaderView, didBeginEditing textField: UITextField) {
        readingListEntryCollectionViewController.editController.isTextEditing = true
    }
    
    func readingListDetailHeaderView(_ headerView: ReadingListDetailHeaderView, titleTextFieldTextDidChange textField: UITextField) {
        navigationItem.rightBarButtonItems?.first?.isEnabled = textField.text?.wmf_hasNonWhitespaceText ?? false
    }
    
    func readingListDetailHeaderView(_ headerView: ReadingListDetailHeaderView, titleTextFieldWillClear textField: UITextField) {
        navigationItem.rightBarButtonItems?.first?.isEnabled = false
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
        readingListEntryCollectionViewController.updateSearchString(searchText)
        
        if searchText.isEmpty {
            makeSearchBarResignFirstResponder(searchBar)
        }
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        makeSearchBarResignFirstResponder(searchBar)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {

    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        makeSearchBarResignFirstResponder(searchBar)
    }
    
    private func makeSearchBarResignFirstResponder(_ searchBar: UISearchBar) {
        searchBar.text = ""
        readingListEntryCollectionViewController.updateSearchString("")
        searchBar.resignFirstResponder()
    }
    
    func textStyle(for button: UIButton) -> WMFFont {
        return .caption1
    }
    
    func buttonType(for button: UIButton, currentButtonType: SearchBarExtendedViewButtonType?) -> SearchBarExtendedViewButtonType? {
        switch currentButtonType {
        case nil:
            return .sort
        case .cancel?:
            return nil
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
            break
            // readingListEntryCollectionViewController.presentSortAlert(from: button)
        case .cancel:
            makeSearchBarResignFirstResponder(searchBar)
        }
    }
}

// MARK: - ReadingListEntryCollectionViewControllerDelegate

extension ReadingListDetailViewController: ReadingListEntryCollectionViewControllerDelegate {

    func setupReadingListDetailHeaderView(_ headerView: ReadingListDetailHeaderView) {
        headerView.delegate = self
        headerView.setup(for: readingList, listLimit: dataStore.viewContext.wmf_readingListsConfigMaxListsPerUser, entryLimit: dataStore.viewContext.wmf_readingListsConfigMaxEntriesPerList.intValue)
    }
    
    func readingListEntryCollectionViewController(_ viewController: ReadingListEntryCollectionViewController, didUpdate collectionView: UICollectionView) {
        let sections = IndexSet(integer: 0)
        viewController.collectionView.reloadSections(sections)
    }
    
    func readingListEntryCollectionViewControllerDidChangeEmptyState(_ viewController: ReadingListEntryCollectionViewController) {
        let isReadingListEmpty = readingList.countOfEntries == 0
        let isEmptyStateMatchingReadingListEmptyState = viewController.isEmpty == isReadingListEmpty
        if !isEmptyStateMatchingReadingListEmptyState {
            viewController.isEmpty = isReadingListEmpty
        }
        if viewController.isEmpty {
            title = readingList.name
        }
    }
    
    func readingListEntryCollectionViewControllerDidSelectArticleURL(_ articleURL: URL, viewController: ReadingListEntryCollectionViewController) {
        
        if displayType == .modal,
           let navVC = (presentingViewController as? WMFAppViewController)?.currentTabNavigationController {
            dismiss(animated: true) { [weak self] in
                
                guard let self else { return }
                
                let coordinator = ArticleCoordinator(navigationController: navVC, articleURL: articleURL, dataStore: dataStore, theme: theme, source: .undefined)
                coordinator.start()
            }
        } else {
            guard let navigationController else {
                return
            }
            
            let coordinator = ArticleCoordinator(navigationController: navigationController, articleURL: articleURL, dataStore: dataStore, theme: theme, source: .undefined)
            coordinator.start()
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        // no-op
    }
}


// MARK: - Import Shared Reading Lists

private extension ReadingListDetailViewController {
    private func  showImportSharedReadingListSurveyPromptIfNeeded() {
        guard fromImport else {
            return
        }
        
        // If they ever tapped "Take survey", never show the prompt again
        guard !UserDefaults.standard.wmf_tappedToImportSharedReadingListSurvey else {
            return
        }
        
        // Don't show survey prompt if they've already seen it on this particular view controller
        guard !seenSurveyPrompt else {
            return
        }
        
        guard let languageCode = dataStore.languageLinkController.appLanguage?.languageCode,
              let surveyURL = (importSurveyURLs[languageCode] ?? importSurveyURLs["en"]) else {
            return
        }

        self.importSurveyPromptTimer = Timer.scheduledTimer(withTimeInterval: importSurveyPromptDelay, repeats: false, block: { [weak self] timer in
            guard let self = self else {
                return
            }

            self.seenSurveyPrompt = true
            ReadingListsFunnel.shared.logPresentedSurveyPrompt()

            self.wmf_showReadingListImportSurveyPanel(primaryButtonTapHandler: { _, _ in
                ReadingListsFunnel.shared.logTappedTakeSurvey()
                UserDefaults.standard.wmf_tappedToImportSharedReadingListSurvey = true
                self.navigate(to: surveyURL, useSafari: true)
                // dismiss handler is called
            }, secondaryButtonTapHandler: { _, _ in
                // dismiss handler is called
            }, footerLinkAction: { (url) in
                 self.navigate(to: url, useSafari: true)
                // intentionally don't dismiss
            }, traceableDismissHandler: { lastAction in
                // Do nothing
            }, theme: self.theme, languageCode: languageCode)
        })
    }
}

extension ReadingListDetailViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else { return }
        readingListEntryCollectionViewController.updateSearchString(text)
    }
}
