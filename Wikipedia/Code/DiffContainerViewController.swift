import UIKit
import WMF
import CocoaLumberjackSwift
import WMFData

struct StubRevisionModel {
    let revisionId: Int
    let summary: String
    let username: String
    let timestamp: Date
}

protocol DiffRevisionRetrieving: AnyObject {
    func retrievePreviousRevision(with sourceRevision: WMFPageHistoryRevision) -> WMFPageHistoryRevision?
    func retrieveNextRevision(with sourceRevision: WMFPageHistoryRevision) -> WMFPageHistoryRevision?
    func refreshRevisions()
}

class DiffContainerViewController: ViewController {
    
    struct NextPrevModel {
        let from: WMFPageHistoryRevision
        let to: WMFPageHistoryRevision
    }
    
    private var containerViewModel: DiffContainerViewModel
    private var headerExtendedView: DiffHeaderExtendedView?
    private var diffHeaderView: DiffHeaderView?
    private var scrollingEmptyViewController: EmptyViewController?
    private var diffListViewController: DiffListViewController?
    private var diffToolbarView: DiffToolbarView?
    private let diffController: DiffController
    
    internal lazy var watchlistController: WatchlistController = {
        return WatchlistController(delegate: self, context: .diff)
    }()
    
    private var fromModel: WMFPageHistoryRevision?
    private var fromModelRevisionID: Int?
    private var toModel: WMFPageHistoryRevision?
    private let toModelRevisionID: Int?
    private let siteURL: URL
    private let wikimediaProject: WikimediaProject?
    private var articleTitle: String?
    private let needsSetNavDelegate: Bool
    private let safeAreaBottomAlignView = UIView()
    
    private var type: DiffContainerViewModel.DiffType
    
    private let revisionRetrievingDelegate: DiffRevisionRetrieving?
    private var firstRevision: WMFPageHistoryRevision?
    
    var animateDirection: DiffRevisionTransition.Direction?
    
    private var wmfProject: WMFProject? {
        return wikimediaProject?.wmfProject
    }
    
    lazy private(set) var fakeProgressController: FakeProgressController = {
        let progressController = FakeProgressController(progress: navigationBar, delegate: navigationBar)
        progressController.delay = 0.0
        return progressController
    }()

    var hintController: HintController?

    private var prevModel: NextPrevModel? {
        didSet {
            diffToolbarView?.setPreviousButtonState(isEnabled: prevModel != nil)
        }
    }
    private var nextModel: NextPrevModel? {
        didSet {
            diffToolbarView?.setNextButtonState(isEnabled: nextModel != nil)
        }
    }
    
    private var isOnFirstRevisionInHistory: Bool {
        if let toModel = toModel,
           let firstRevision = firstRevision,
           fromModel == nil,
           toModel.revisionID == firstRevision.revisionID {
            return true
        }
        
        return false
    }
    
    private var isOnSecondRevisionInHistory: Bool {
        if toModel != nil,
           let fromModel = fromModel,
           let firstRevision = firstRevision,
           fromModel.revisionID == firstRevision.revisionID {
            return true
        }
        
        return false
    }
    
    private var byteDifference: Int? {
        return (toModel?.articleSizeAtRevision ?? 0) - (fromModel?.articleSizeAtRevision ?? 0)
    }
    
    private weak var undoAlertUndoAction: UIAlertAction?
    private weak var undoAlertSummaryTextField: UITextField?
    
    init(siteURL: URL, theme: Theme, fromRevisionID: Int?, toRevisionID: Int?, articleTitle: String?, needsSetNavDelegate: Bool = false, articleSummaryController: ArticleSummaryController, authenticationManager: WMFAuthenticationManager) {
        self.siteURL = siteURL
        let wikimediaProject = WikimediaProject(siteURL: siteURL)
        self.wikimediaProject = wikimediaProject
        self.type = .compare
        self.articleTitle = articleTitle
        self.toModelRevisionID = toRevisionID
        self.fromModelRevisionID = fromRevisionID
        
        self.diffController = DiffController(siteURL: siteURL, pageHistoryFetcher: nil, revisionRetrievingDelegate: nil, type: type, articleSummaryController: articleSummaryController, authenticationManager: authenticationManager)
        self.containerViewModel = DiffContainerViewModel(type: type, fromModel: nil, toModel: nil, listViewModel: nil, articleTitle: articleTitle, imageURL: nil, byteDifference: nil, theme: theme, project: wikimediaProject)
        
        self.firstRevision = nil
        self.revisionRetrievingDelegate = nil
        self.toModel = nil
        self.fromModel = nil
        self.needsSetNavDelegate = needsSetNavDelegate
        
        super.init()
        self.theme = theme
        
        self.containerViewModel.stateHandler = { [weak self] oldState in
            self?.evaluateState(oldState: oldState)
        }
    }
    
    init(articleTitle: String, siteURL: URL, fromModel: WMFPageHistoryRevision?, toModel: WMFPageHistoryRevision, pageHistoryFetcher: PageHistoryFetcher? = nil, theme: Theme, revisionRetrievingDelegate: DiffRevisionRetrieving?, firstRevision: WMFPageHistoryRevision?, needsSetNavDelegate: Bool = false, articleSummaryController: ArticleSummaryController, authenticationManager: WMFAuthenticationManager) {

        self.type = .compare
        
        self.fromModel = fromModel
        self.toModel = toModel
        self.toModelRevisionID = toModel.revisionID
        self.articleTitle = articleTitle
        self.revisionRetrievingDelegate = revisionRetrievingDelegate
        self.siteURL = siteURL
        let project = WikimediaProject(siteURL: siteURL)
        self.wikimediaProject = project
        self.firstRevision = firstRevision

        self.diffController = DiffController(siteURL: siteURL, pageHistoryFetcher: pageHistoryFetcher, revisionRetrievingDelegate: revisionRetrievingDelegate, type: type, articleSummaryController: articleSummaryController, authenticationManager: authenticationManager)

        self.containerViewModel = DiffContainerViewModel(type: type, fromModel: fromModel, toModel: toModel, listViewModel: nil, articleTitle: articleTitle, imageURL: nil, byteDifference: nil, theme: theme, project: project)
        
        self.needsSetNavDelegate = needsSetNavDelegate
        
        super.init()
        
        self.theme = theme
        
        self.containerViewModel.stateHandler = { [weak self] oldState in
            self?.evaluateState(oldState: oldState)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        WatchlistFunnel.shared.logDiffOpen(project: wikimediaProject)
        setupBackButton()

        let onLoad = { [weak self] in
            
            guard let self = self else { return }
            
            if self.isOnFirstRevisionInHistory {
                self.type = .single
            }
            
            if self.fromModel == nil {
                self.fetchFromModelAndFinishSetup()
            } else if self.toModel == nil {
                self.fetchToModelAndFinishSetup()
            } else {
                self.midSetup()
                self.completeSetup()
            }
        }
        
        startSetup()
        if toModel == nil {
            populateModelsFromDeepLink { [weak self] (error) in
                
                guard let self = self else { return }
                
                if let error = error {
                    self.containerViewModel.state = .error(error: error)
                    return
                }
                
                onLoad()
            }
        } else {
            onLoad()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let toolbarView = diffToolbarView {
            view.bringSubviewToFront(toolbarView)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        switch type {
        case .compare:
            self.showDiffPanelOnce()
        case .single:
            break
        }
        
        resetPrevNextAnimateState()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let emptyViewController = scrollingEmptyViewController {
            navigationBar.setNeedsLayout()
            navigationBar.layoutSubviews()
            let bottomSafeAreaHeight = safeAreaBottomAlignView.frame.height
            let bottomHeight = bottomSafeAreaHeight
            let targetRect = CGRect(x: 0, y: navigationBar.visibleHeight, width: emptyViewController.view.frame.width, height: emptyViewController.view.frame.height - navigationBar.visibleHeight - bottomHeight)

            let convertedTargetRect = view.convert(targetRect, to: emptyViewController.view)
            emptyViewController.centerEmptyView(within: convertedTargetRect)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // Upon rotation completion, recalculate more button popover position
        coordinator.animate(alongsideTransition: nil) { [weak self] (context) in
            
            guard let self,
                  let diffToolbarView = self.diffToolbarView else {
                return
            }
            
            watchlistController.calculatePopoverPosition(sender: diffToolbarView.moreButton, sourceView: diffToolbarView.moreButtonSourceView, sourceRect: diffToolbarView.moreButtonSourceRect)
        }
    }
    
    override func apply(theme: Theme) {
        
        super.apply(theme: theme)
        
        guard isViewLoaded else {
            return
        }
        
        switch containerViewModel.state {
        case .empty, .error:
            view.backgroundColor = theme.colors.midBackground
        default:
            view.backgroundColor = theme.colors.paperBackground
        }
        
        diffHeaderView?.apply(theme: theme)
        headerExtendedView?.apply(theme: theme)
        diffListViewController?.apply(theme: theme)
        scrollingEmptyViewController?.apply(theme: theme)
        diffToolbarView?.apply(theme: theme)
    }

    private func setupBackButton() {
        let buttonTitle: String
        switch type {
        case .compare: buttonTitle = CommonStrings.compareRevisionsTitle
        case .single:
            guard let toDate = toModel?.revisionDate as NSDate? else {
                return
            }
            let dateString = toDate.wmf_fullyLocalizedRelativeDateStringFromLocalDateToNow()
            buttonTitle = String.localizedStringWithFormat(CommonStrings.revisionMadeFormat, dateString.lowercased())
        }
        
        navigationItem.configureForEmptyNavBarTitle(backTitle: buttonTitle)
    }
}

// MARK: Private

private extension DiffContainerViewController {

    func fetchPageURL() -> URL? {
        guard let articleTitle = articleTitle, let url = siteURL.wmf_URL(withTitle: articleTitle) else {
            return nil
        }
        
        return url
    }

    func fetchEditHistoryURL() -> URL? {
        guard let articleTitle = articleTitle, let languageCode = siteURL.wmf_languageCode else {
            return nil
        }

        let namespaceAndTitle = articleTitle.namespaceAndTitleOfWikiResourcePath(with: languageCode)
        let namespace = namespaceAndTitle.namespace
        let title = namespaceAndTitle.title

        var requestedPageTitle: String

        if namespace.isTalkBased {
            // Direct user to actual article page instead of talk page
            let convertedCanonicalName = namespace.convertedPrimaryTalkPageNamespace.canonicalName
            requestedPageTitle = convertedCanonicalName.isEmpty ? title : "\(convertedCanonicalName):\(title)"
        } else {
            requestedPageTitle = articleTitle
        }

        guard let url = siteURL.wmf_URL(withTitle: requestedPageTitle) else {
            return nil
        }

        return url
    }

    func populateNewHeaderViewModel() {
        guard let toModel = toModel,
              let articleTitle = articleTitle else {
            assertionFailure("tomModel and articleTitle need to be in place for generating header.")
            return
        }
        
        self.containerViewModel.headerViewModel = DiffHeaderViewModel(diffType: type, fromModel: self.fromModel, toModel: toModel, articleTitle: articleTitle, imageURL: nil, byteDifference: byteDifference, theme: self.theme, project: wikimediaProject)
    }
    
    func resetPrevNextAnimateState() {
        animateDirection = nil
    }
    
    func populateModelsFromDeepLink(completion: @escaping (_ error: Error?) -> Void) {
        guard toModel == nil else {
            assertionFailure("Why are you calling this if you already have toModel?")
            return
        }
        
        diffController.populateModelsFromDeepLink(fromRevisionID: fromModelRevisionID, toRevisionID: toModelRevisionID, articleTitle: articleTitle) { (result) in
            switch result {
            case .success(let response):
                DispatchQueue.main.async {
                    self.fromModel = response.from
                    self.toModel = response.to
                    self.firstRevision = response.first
                    self.articleTitle = response.articleTitle
                    completion(nil)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
    }
    
    func fetchToModelAndFinishSetup() {
        guard let fromModel = fromModel,
              let articleTitle = articleTitle else {
            assertionFailure("fromModel and articleTitle must be populated for fetching toModel")
            return
        }
        
        diffController.fetchAdjacentRevisionModel(sourceRevision: fromModel, direction: .next, articleTitle: articleTitle) { (result) in
            switch result {
            case .success(let revision):
                DispatchQueue.main.async {
                    self.toModel = revision
                    self.midSetup()
                    self.completeSetup()
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.containerViewModel.state = .error(error: error)
                }
            }
        }
    }
    
    func fetchFromModelAndFinishSetup() {
        
        guard let toModel = toModel,
              let articleTitle = articleTitle else {
            assertionFailure("toModel and articleTitle must be populated for fetching fromModel")
            return
        }
        
        // early exit for first revision
        // there is no previous revision from toModel in this case
        if isOnFirstRevisionInHistory {
            midSetup()
            completeSetup()
            return
        }
        
        diffController.fetchAdjacentRevisionModel(sourceRevision: toModel, direction: .previous, articleTitle: articleTitle) { (result) in
            switch result {
            case .success(let revision):
                DispatchQueue.main.async {
                    self.fromModel = revision
                    
                    self.midSetup()
                    self.completeSetup()
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.containerViewModel.state = .error(error: error)
                }
            }
        }
    }
    
    func startSetup() {
        setupToolbarIfNeeded()
        containerViewModel.state = .loading
        
        // For some reason this is needed when coming from Article As A Living Document screens
        if needsSetNavDelegate {
            navigationController?.delegate = self
        }
    }
    
    func midSetup() {
        guard toModel != nil else {
            assertionFailure("Expecting at least toModel to be populated for this method.")
            return
        }
        
        populateNewHeaderViewModel()
        setupHeaderViewIfNeeded()
        setupDiffListViewControllerIfNeeded()
        fetchLeadImageIfNeeded()
        fetchWatchAndRollbackStatus()
        fetchEditCountIfNeeded()
        setupBackButton()
        apply(theme: theme)
    }
    
    func completeSetup() {
        
        guard toModel != nil,
              fromModel != nil || isOnFirstRevisionInHistory else {
            assertionFailure("Both models must be populated at this point or needs to be on the first revision.")
            return
        }
        
        if isOnFirstRevisionInHistory {
            fetchFirstDiff()
        } else {
            fetchDiff()
        }
        
        // Still need models for enabling/disabling prev/next buttons
        populatePrevNextModelsForToolbar()
        diffToolbarView?.undoButton.isEnabled = wmfProject != nil
    }
    
    func setThankAndMoreState(isEnabled: Bool) {
        diffToolbarView?.setThankButtonState(isEnabled: isEnabled)
        diffToolbarView?.setMoreButtonState(isEnabled: isEnabled)
        diffToolbarView?.apply(theme: theme)
    }
    
    func populatePrevNextModelsForToolbar() {
        
        guard let toModel = toModel,
              let articleTitle = articleTitle,
              fromModel != nil || isOnFirstRevisionInHistory else {
            assertionFailure("Both models and articleTitle must be populated at this point or needs to be on the first revision.")
            return
        }
        
        // populate nextModel for enabling previous/next button
        let nextFromModel = toModel
        var nextToModel: WMFPageHistoryRevision?
        diffController.fetchAdjacentRevisionModel(sourceRevision: nextFromModel, direction: .next, articleTitle: articleTitle) { [weak self] (result) in
            
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(let revision):
                DispatchQueue.main.async {
                    nextToModel = revision
                    if let nextToModel = nextToModel {
                        self.nextModel = NextPrevModel(from: nextFromModel, to: nextToModel)
                    }
                }
            case .failure:
                break
            }
        }
        
        // if on first or second revision, fromModel will be nil and attempting to fetch previous revision will fail.
        if isOnFirstRevisionInHistory {
            diffToolbarView?.setNextButtonState(isEnabled: true)
            return
        }
        
        if isOnSecondRevisionInHistory {
            diffToolbarView?.setPreviousButtonState(isEnabled: true)
            return
        }
        
        guard let fromModel = fromModel else {
            return
        }
        
        // populate prevModel for enabling previous/next button
        var prevFromModel: WMFPageHistoryRevision?
        let prevToModel = fromModel
        diffController.fetchAdjacentRevisionModel(sourceRevision: prevToModel, direction: .previous, articleTitle: articleTitle) { [weak self] (result) in
            
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(let revision):
                DispatchQueue.main.async {
                    prevFromModel = revision
                    if let prevFromModel = prevFromModel {
                        self.prevModel = NextPrevModel(from: prevFromModel, to: prevToModel)
                    }
                }
            case .failure(let error):
                DDLogError("error fetching revision: \(error)")
                break
            }
        }
    }
    
    func fullRevisionDiffURL() -> URL? {
        
        guard let toModel = toModel else {
            return nil
        }
        
        let oldID = fromModel?.revisionID ?? toModel.parentID
        
        var components = URLComponents(url: siteURL, resolvingAgainstBaseURL: false)
        components?.path = "/w/index.php"
        components?.queryItems = [
            URLQueryItem(name: "title", value: articleTitle),
            URLQueryItem(name: "diff", value: String(toModel.revisionID)),
            URLQueryItem(name: "oldid", value: String(oldID))
        ]
        return components?.url
    }
    
    func evaluateState(oldState: DiffContainerViewModel.State) {
        
        // need up update background color if state is error/empty or not
        switch containerViewModel.state {
        case .error, .empty:
            switch oldState {
            case .error, .empty:
                break
            default:
                apply(theme: theme)
                diffToolbarView?.parentViewState = containerViewModel.state
            }
        default:
            switch oldState {
            case .error, .empty:
                apply(theme: theme)
                diffToolbarView?.parentViewState = containerViewModel.state
            default:
                break
            }
        }
        
        switch containerViewModel.state {

        case .loading:
            fakeProgressController.start()
            scrollingEmptyViewController?.view.isHidden = true
            diffListViewController?.view.isHidden = true
            setThankAndMoreState(isEnabled: false)
        case .empty:
            fakeProgressController.stop()
            setupScrollingEmptyViewControllerIfNeeded()
            switch type {
            case .compare:
                scrollingEmptyViewController?.type = .diffCompare
            case .single:
                scrollingEmptyViewController?.type = .diffSingle
            }
            
            if let direction = animateDirection {
                animateInOut(viewController: scrollingEmptyViewController, direction: direction)
            } else {
                scrollingEmptyViewController?.view.isHidden = false
            }
            
            diffListViewController?.view.isHidden = true
            setThankAndMoreState(isEnabled: true)
        case .error(let error):
            fakeProgressController.stop()
            showNoInternetConnectionAlertOrOtherWarning(from: error)
            setupScrollingEmptyViewControllerIfNeeded()
            switch type {
            case .compare:
                scrollingEmptyViewController?.type = .diffErrorCompare
            case .single:
                scrollingEmptyViewController?.type = .diffErrorSingle
            }
            scrollingEmptyViewController?.view.isHidden = false
            diffListViewController?.view.isHidden = true
            setThankAndMoreState(isEnabled: false)
        case .data:
            fakeProgressController.stop()
            scrollingEmptyViewController?.view.isHidden = true
            
            if let direction = animateDirection {
                animateInOut(viewController: diffListViewController, direction: direction)
            } else {
                diffListViewController?.view.isHidden = false
            }
            
            setThankAndMoreState(isEnabled: true)
        }
    }
    
    func animateInOut(viewController: UIViewController?, direction: DiffRevisionTransition.Direction) {
        viewController?.view.alpha = 0
        viewController?.view.isHidden = false
        
        if let oldFrame = viewController?.view.frame {
            let newY = direction == .down ? oldFrame.maxY : oldFrame.minY - oldFrame.height
            let newFrame = CGRect(x: oldFrame.minX, y: newY, width: oldFrame.width, height: oldFrame.height)
            viewController?.view.frame = newFrame
            
            UIView.animate(withDuration: DiffRevisionTransition.duration, delay: 0.0, options: .curveEaseInOut, animations: {
                viewController?.view.alpha = 1
                viewController?.view.frame = oldFrame
            }, completion: nil)
        }
    }
    
    func fetchEditCountIfNeeded() {
        
        guard let toModel = toModel else {
            return
        }
        
        switch type {
        case .single:
            if let username = toModel.user {
                diffController.fetchEditCount(guiUser: username) { [weak self] (result) in
                    
                    guard let self = self else {
                        return
                    }
                    
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let editCount):
                            self.updateHeaderWithEditCount(editCount)
                        case .failure:
                            break
                        }
                    }
                }
            }
        case .compare:
            break
        }
    }
    
    func fetchWatchAndRollbackStatus() {
        
        guard let articleTitle, let wmfProject else {
            return
        }
        
        WMFWatchlistDataController().fetchWatchStatus(title: articleTitle, project: wmfProject, needsRollbackRights: true) { result in
            DispatchQueue.main.async { [weak self] in
                
                guard let self else {
                    return
                }
                
                switch result {
                case .success(let status):
                    
                    let needsWatchButton = !status.watched
                    let needsUnwatchHalfButton = status.watched && status.watchlistExpiry != nil
                    let needsUnwatchFullButton = status.watched && status.watchlistExpiry == nil
                    let needsArticleEditHistoryButton = true
                    
                    self.diffToolbarView?.updateMoreButton(needsRollbackButton: (status.userHasRollbackRights ?? false), needsWatchButton: needsWatchButton, needsUnwatchHalfButton: needsUnwatchHalfButton, needsUnwatchFullButton: needsUnwatchFullButton, needsArticleEditHistoryButton: needsArticleEditHistoryButton)
                case .failure:
                    break
                }
            }
            
        }
    }
    
    func fetchLeadImageIfNeeded() {
        
        guard let articleTitle else {
            return
        }

        diffController.fetchLeadImageURL(siteURL: siteURL, articleTitle: articleTitle) { [weak self] result in

            guard let self else {
                return
            }

            switch result {
            case .success(let leadImageURL):
                self.updateHeaderWithLeadImageURL(leadImageURL)
            default:
                break
            }
        }
    }

    func updateHeaderWithLeadImageURL(_ leadImageURL: URL) {
        guard let headerViewModel = containerViewModel.headerViewModel else {
            return
        }
        headerViewModel.imageURL = leadImageURL
        diffHeaderView?.updateImageView(with: headerViewModel)
    }

    func updateHeaderWithIntermediateCounts(_ editCounts: EditCountsGroupedByType) {
        switch type {
        case .compare:
            guard let headerViewModel = containerViewModel.headerViewModel,
                  let articleTitle = articleTitle else {
                return
            }

            let newTitleViewModel = DiffHeaderViewModel.generateTitleViewModelForCompare(articleTitle: articleTitle, byteDifference: byteDifference)
            headerViewModel.title = newTitleViewModel
            diffHeaderView?.updateTitleView(with: newTitleViewModel)
        case .single:
            assertionFailure("Should not call this method for the compare type.")
        }
    }
    
    func updateHeaderWithEditCount(_ editCount: Int) {
        
        // update view model
        guard let headerViewModel = containerViewModel.headerViewModel else {
            return
        }
        
        switch headerViewModel.headerType {
        case .single(let editorViewModel, _):
            editorViewModel.numberOfEdits = editCount
        case .compare:
            assertionFailure("Should not call this method for the compare type.")
            return
        }
        
        // update view
        headerExtendedView?.update(headerViewModel)
    }
    
    func fetchFirstDiff() {
        guard let toModel = toModel,
              isOnFirstRevisionInHistory else {
            return
        }
        
        view.setNeedsLayout()
        view.layoutIfNeeded()
        let width = diffListViewController?.collectionView.frame.width
        
        diffController.fetchFirstRevisionDiff(revisionId: toModel.revisionID, siteURL: siteURL, theme: theme, traitCollection: traitCollection) { [weak self] (result) in

            guard let self = self else {
                return
            }

            switch result {
            case .success(let listViewModel):

                self.updateListViewController(with: listViewModel, collectionViewWidth: width)
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self.containerViewModel.state = .error(error: error)
                }
            }
        }
    }
    
    func updateListViewController(with listViewModels: [DiffListGroupViewModel], collectionViewWidth: CGFloat?) {
        
        assert(!Thread.isMainThread, "diffListViewController.updateListViewModels could take a while, would be better from a background thread.")
        
        self.containerViewModel.listViewModel = listViewModels
        self.diffListViewController?.updateListViewModels(listViewModel: listViewModels, updateType: .initialLoad(width: collectionViewWidth ?? 0))
        
        DispatchQueue.main.async {
            self.diffListViewController?.applyListViewModelChanges(updateType: .initialLoad(width: collectionViewWidth ?? 0))
            
            self.diffListViewController?.updateScrollViewInsets()
            
            self.containerViewModel.state = listViewModels.count == 0 ? .empty : .data
        }
    }
    
    func fetchDiff() {
        
        guard let toModel = toModel,
              let fromModel = fromModel else {
            return
        }
        
        view.setNeedsLayout()
        view.layoutIfNeeded()
        let width = diffListViewController?.collectionView.frame.width
        
        diffController.fetchDiff(fromRevisionId: fromModel.revisionID, toRevisionId: toModel.revisionID, theme: theme, traitCollection: traitCollection) { [weak self] (result) in

            guard let self = self else {
                return
            }

            switch result {
            case .success(let listViewModel):

                self.updateListViewController(with: listViewModel, collectionViewWidth: width)
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self.containerViewModel.state = .error(error: error)
                }
            }
        }
    }

    func setupHeaderViewIfNeeded() {
        
        guard let headerViewModel = containerViewModel.headerViewModel else {
            return
        }
        
        if self.diffHeaderView == nil {
            let headerView = DiffHeaderView(frame: .zero)
            headerView.translatesAutoresizingMaskIntoConstraints = false
            
            navigationBar.isUnderBarViewHidingEnabled = true
            navigationBar.allowsUnderbarHitsFallThrough = true
            navigationBar.addUnderNavigationBarView(headerView)
            navigationBar.underBarViewPercentHiddenForShowingTitle = 0.6
            navigationBar.isShadowShowing = false
            
            self.diffHeaderView = headerView
        }
        
        if self.headerExtendedView == nil {
            let headerExtendedView = DiffHeaderExtendedView(frame: .zero)
            headerExtendedView.translatesAutoresizingMaskIntoConstraints = false
            
            navigationBar.allowsUnderbarHitsFallThrough = true
            navigationBar.allowsExtendedHitsFallThrough = true
            navigationBar.addExtendedNavigationBarView(headerExtendedView)
            headerExtendedView.delegate = self
            
            self.headerExtendedView = headerExtendedView
        }
        
        navigationBar.isBarHidingEnabled = false
        useNavigationBarVisibleHeightForScrollViewInsets = true
        
        switch headerViewModel.headerType {
        case .compare(_, let navBarTitle):
            navigationBar.title = navBarTitle
        default:
            break
        }
        diffHeaderView?.configure(with: headerViewModel, titleViewTapDelegate: self)
        headerExtendedView?.update(headerViewModel)
        navigationBar.isExtendedViewHidingEnabled = headerViewModel.isExtendedViewHidingEnabled
    }
    
    func setupScrollingEmptyViewControllerIfNeeded() {
        
        guard scrollingEmptyViewController == nil else {
            return
        }

        scrollingEmptyViewController = EmptyViewController(nibName: "EmptyViewController", bundle: nil)
        if let emptyViewController = scrollingEmptyViewController,
           let emptyView = emptyViewController.view {
            emptyViewController.canRefresh = false
            emptyViewController.theme = theme
            
            setupSafeAreaBottomAlignView()
            
            addChild(emptyViewController)
            emptyView.translatesAutoresizingMaskIntoConstraints = false
            view.insertSubview(emptyView, belowSubview: navigationBar)
            let bottomAnchor = diffToolbarView?.topAnchor ?? safeAreaBottomAlignView.bottomAnchor
            let bottom = emptyView.bottomAnchor.constraint(equalTo: bottomAnchor)
            let leading = view.leadingAnchor.constraint(equalTo: emptyView.leadingAnchor)
            let trailing = view.trailingAnchor.constraint(equalTo: emptyView.trailingAnchor)
            let top = view.topAnchor.constraint(equalTo: emptyView.topAnchor)
            NSLayoutConstraint.activate([top, leading, trailing, bottom])
            emptyViewController.didMove(toParent: self)
            
            emptyViewController.view.isHidden = true
            emptyViewController.delegate = self
            
        }
    }
    
    func setupSafeAreaBottomAlignView() {
        // add alignment view view
        safeAreaBottomAlignView.translatesAutoresizingMaskIntoConstraints = false
        safeAreaBottomAlignView.isHidden = true
        view.addSubview(safeAreaBottomAlignView)
        let leadingConstraint = view.leadingAnchor.constraint(equalTo: safeAreaBottomAlignView.leadingAnchor)
        let bottomAnchor = diffToolbarView?.topAnchor ?? view.safeAreaLayoutGuide.bottomAnchor
        let bottomConstraint = safeAreaBottomAlignView.bottomAnchor.constraint(equalTo: bottomAnchor)
        let widthAnchor = safeAreaBottomAlignView.widthAnchor.constraint(equalToConstant: 1)
        let heightAnchor = safeAreaBottomAlignView.heightAnchor.constraint(equalToConstant: 1)
        NSLayoutConstraint.activate([leadingConstraint, bottomConstraint, widthAnchor, heightAnchor])
    }
    
    func setupToolbarIfNeeded() {
        if diffToolbarView == nil {
            let toolbarView = DiffToolbarView(frame: .zero)
            self.diffToolbarView = toolbarView
            toolbarView.delegate = self
            toolbarView.translatesAutoresizingMaskIntoConstraints = false
            view.insertSubview(toolbarView, aboveSubview: navigationBar)
            let bottom = view.bottomAnchor.constraint(equalTo: toolbarView.bottomAnchor)
            let leading = view.leadingAnchor.constraint(equalTo: toolbarView.leadingAnchor)
            let trailing = view.trailingAnchor.constraint(equalTo: toolbarView.trailingAnchor)
            NSLayoutConstraint.activate([bottom, leading, trailing])
            toolbarView.apply(theme: theme)
            toolbarView.setPreviousButtonState(isEnabled: false)
            toolbarView.setNextButtonState(isEnabled: false)
        }
    }
    
    func setupDiffListViewControllerIfNeeded() {
        if diffListViewController == nil {
            let diffListViewController = DiffListViewController(theme: theme, delegate: self, type: type)
            self.diffListViewController = diffListViewController
            
            switch type {
            case .single:
                if let listView = diffListViewController.view,
                   let toolbarView = diffToolbarView {
                    addChild(diffListViewController)
                    listView.translatesAutoresizingMaskIntoConstraints = false
                    view.insertSubview(listView, belowSubview: navigationBar)
                    let bottom = toolbarView.topAnchor.constraint(equalTo: listView.bottomAnchor)
                    let leading = view.leadingAnchor.constraint(equalTo: listView.leadingAnchor)
                    let trailing = view.trailingAnchor.constraint(equalTo: listView.trailingAnchor)
                    let top = view.topAnchor.constraint(equalTo: listView.topAnchor)
                    NSLayoutConstraint.activate([top, leading, trailing, bottom])
                    diffListViewController.didMove(toParent: self)
                }
            case .compare:
                wmf_add(childController: diffListViewController, andConstrainToEdgesOfContainerView: view, belowSubview: navigationBar)
            }
            
            
        }
    }
    
    func showDiffPanelOnce() {
        let key = "didShowDiffPanel"
        if UserDefaults.standard.bool(forKey: key) {
            return
        }
        let panelVC = DiffEducationalPanelViewController(showCloseButton: false, primaryButtonTapHandler: { [weak self] _, _ in
            self?.presentedViewController?.dismiss(animated: true)
        }, secondaryButtonTapHandler: nil, dismissHandler: nil, discardDismissHandlerOnPrimaryButtonTap: true, theme: theme)
        present(panelVC, animated: true)
        UserDefaults.standard.set(true, forKey: key)
    }
    
    func showNoInternetConnectionAlertOrOtherWarning(from error: Error, noInternetConnectionAlertMessage: String = CommonStrings.noInternetConnection) {

        if (error as NSError).wmf_isNetworkConnectionError() {
            
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: noInternetConnectionAlertMessage)
            } else {
                WMFAlertManager.sharedInstance.showErrorAlertWithMessage(noInternetConnectionAlertMessage, sticky: true, dismissPreviousAlerts: true)
            }
            
        } else if let diffError = error as? DiffError {
            
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: diffError.localizedDescription)
            } else {
                WMFAlertManager.sharedInstance.showWarningAlert(diffError.localizedDescription, sticky: true, dismissPreviousAlerts: true)
            }
            
        } else {
            
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: error.localizedDescription)
            } else {
                WMFAlertManager.sharedInstance.showErrorAlertWithMessage(error.localizedDescription, sticky: true, dismissPreviousAlerts: true)
            }
            
        }
    }
}

extension DiffContainerViewController: DiffListDelegate {
    func diffListScrollViewDidScroll(_ scrollView: UIScrollView) {
        self.scrollViewDidScroll(scrollView)
    }
}

extension DiffContainerViewController: EmptyViewControllerDelegate {
    func triggeredRefresh(refreshCompletion: @escaping () -> Void) {
        // no refreshing
    }
    
    func emptyViewScrollViewDidScroll(_ scrollView: UIScrollView) {
        self.scrollViewDidScroll(scrollView)
    }
}

extension DiffContainerViewController: DiffHeaderActionDelegate {
    
    func tappedUsername(username: String, destination: DiffHeaderUsernameDestination) {
        
        guard let username = username.normalizedPageTitle else {
            return
        }
        
        let url: URL?
        switch destination {
        case .userContributions:
            url = siteURL.wmf_URL(withPath: "/wiki/Special:Contributions/\(username)", isMobile: true)
        case .userTalkPage:
            url = siteURL.wmf_URL(withPath: "/wiki/User_talk:\(username)", isMobile: true)
        case .userPage:
            url = siteURL.wmf_URL(withPath: "/wiki/User:\(username)", isMobile: true)
        }
        
        navigate(to: url)
    }
    
    func tappedRevision(revisionID: Int) {
        
        guard let fromModel = fromModel,
              let toModel = toModel,
              let articleTitle = articleTitle else {
            assertionFailure("Revision tapping is not supported on a page without models or articleTitle.")
            return
        }
        
        let revision: WMFPageHistoryRevision
        if revisionID == fromModel.revisionID {
            revision = fromModel
        } else if revisionID == toModel.revisionID {
            revision = toModel
        } else {
            assertionFailure("Trouble determining revision model to push on next")
            return
        }
        
        EditHistoryCompareFunnel.shared.logRevisionView(url: siteURL)
        
        let singleDiffVC = DiffContainerViewController(articleTitle: articleTitle, siteURL: siteURL, fromModel: nil, toModel: revision, theme: theme, revisionRetrievingDelegate: revisionRetrievingDelegate,  firstRevision: firstRevision, needsSetNavDelegate: needsSetNavDelegate, articleSummaryController: diffController.articleSummaryController, authenticationManager: diffController.authenticationManager)
        push(singleDiffVC, animated: true)
    }
}

extension DiffContainerViewController: ThanksGiving {
    var url: URL? {
        return siteURL
    }

    var bottomSpacing: CGFloat? {
        return diffToolbarView?.toolbarHeight
    }

    func didLogIn() {
        self.apply(theme: self.theme)
    }

    func wereThanksSent(for revisionID: Int) -> Bool {
        return diffToolbarView?.isThankSelected ?? false
    }

    func thanksWereSent(for revisionID: Int) {
        diffToolbarView?.isThankSelected = true
    }
}

class AuthorAlreadyThankedHintVC: HintViewController {
    override func configureSubviews() {
        viewType = .warning
        warningLabel.text = WMFLocalizedString("diff-thanks-sent-already", value: "You’ve already sent a ‘Thanks’ for this edit", comment: "Message indicating thanks was already sent")
        warningSubtitleLabel.text = WMFLocalizedString("diff-thanks-sent-cannot-unsend", value: "Thanks cannot be unsent", comment: "Message indicating thanks cannot be unsent")
    }
}

class AnonymousUsersCannotBeThankedHintVC: HintViewController {
    override func configureSubviews() {
        viewType = .warning
        warningLabel.text = WMFLocalizedString("diff-thanks-anonymous-no-thanks", value: "Anonymous users cannot be thanked", comment: "Message indicating anonymous users cannot be thanked")
        warningSubtitleLabel.text = nil
    }
}

class RevisionAuthorThankedHintVC: HintViewController {
    var recipient: String
    init(recipient: String) {
        self.recipient = recipient
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func configureSubviews() {
        viewType = .default
        
        let thanksMessageWithRecipient = String.localizedStringWithFormat(CommonStrings.thanksMessage, recipient)
        defaultImageView.image = UIImage(named: "selected")
        defaultLabel.text = thanksMessageWithRecipient
    }
}

class RevisionAuthorThanksErrorHintVC: HintViewController {
    var error: Error
    init(error: Error) {
        self.error = error
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func configureSubviews() {
        viewType = .warning
        warningLabel.text = (error as NSError).alertMessage()
        warningSubtitleLabel.text = nil
    }
}

extension DiffContainerViewController: DiffToolbarViewDelegate { 
    private func replaceLastAndPush(with viewController: UIViewController) {
        if var newViewControllers = navigationController?.viewControllers {
            newViewControllers.removeLast()
            newViewControllers.append(viewController)
            navigationController?.setViewControllers(newViewControllers, animated: true)
        }
    }
    
    func tappedPrevious() {
        
        animateDirection = .down
        
        guard prevModel != nil ||
                isOnSecondRevisionInHistory else {
            assertionFailure("Expecting either a prevModel populated to push or a firstRevision to push.")
            return
        }
        
        let fromModel = prevModel?.from
        let maybeToModel = prevModel?.to ?? firstRevision
        
        guard let toModel = maybeToModel,
              let articleTitle = articleTitle else {
            assertionFailure("toModel and articleTitle before pushing on new DiffContainerVC")
            return
        }
        
        WatchlistFunnel.shared.logDiffToolbarTapPrevious(project: wikimediaProject)
        
        let diffVC = DiffContainerViewController(articleTitle: articleTitle, siteURL: siteURL, fromModel: fromModel, toModel: toModel, theme: theme, revisionRetrievingDelegate: revisionRetrievingDelegate, firstRevision: firstRevision, needsSetNavDelegate: needsSetNavDelegate, articleSummaryController: diffController.articleSummaryController, authenticationManager: diffController.authenticationManager)

        replaceLastAndPush(with: diffVC)
    }
    
    func tappedNext() {
        
        animateDirection = .up
        
        guard let nextModel = nextModel,
              let articleTitle = articleTitle else {
            assertionFailure("Expecting nextModel and articleTitle to be populated. Next button should have been disabled if there's no model.")
            return
        }
        
        WatchlistFunnel.shared.logDiffToolbarTapNext(project: wikimediaProject)
        
        let diffVC = DiffContainerViewController(articleTitle: articleTitle, siteURL: siteURL, fromModel: nextModel.from, toModel: nextModel.to, theme: theme, revisionRetrievingDelegate: revisionRetrievingDelegate, firstRevision: firstRevision, needsSetNavDelegate: needsSetNavDelegate, articleSummaryController: diffController.articleSummaryController, authenticationManager: diffController.authenticationManager)

        replaceLastAndPush(with: diffVC)
    }
    
    func tappedShare() {
        guard let diffURL = fullRevisionDiffURL() else {
            assertionFailure("Couldn't get full revision diff URL")
            return
        }
        
        WatchlistFunnel.shared.logDiffToolbarMoreTapShare(project: wikimediaProject)
        let activityViewController = UIActivityViewController(activityItems: [diffURL], applicationActivities: [TUSafariActivity()])
        activityViewController.popoverPresentationController?.barButtonItem = diffToolbarView?.moreButton
        activityViewController.excludedActivityTypes = [.addToReadingList]
        activityViewController.completionWithItemsHandler = { [weak self] (_, completed, _, _) in
            if completed {
                WatchlistFunnel.shared.logDiffShareSuccess(project: self?.wikimediaProject)
            }
        }
        
        present(activityViewController, animated: true)
    }

    func tappedEditHistory() {
        guard let editHistoryURL = fetchEditHistoryURL(), let pageTitle = editHistoryURL.wmf_title else {
            return
        }

        WatchlistFunnel.shared.logDiffToolbarMoreTapArticleEditHistory(project: wikimediaProject)
        let historyViewController = PageHistoryViewController(pageTitle: pageTitle, pageURL: editHistoryURL, articleSummaryController: diffController.articleSummaryController, authenticationManager: diffController.authenticationManager)
        historyViewController.theme = theme

        push(historyViewController, animated: true)
    }

    func tappedThankButton() {
        let isUserAnonymous = toModel?.isAnon ?? true
        
        WatchlistFunnel.shared.logDiffToolbarTapThank(project: wikimediaProject)
        
        tappedThank(for: toModelRevisionID, isUserAnonymous: isUserAnonymous)
    }
    
    func tappedWatch() {
        
        guard let articleTitle,
        let sender = diffToolbarView?.moreButton else {
            showGenericError()
            return
        }
        
        watchlistController.watch(pageTitle: articleTitle, siteURL: siteURL, viewController: self, authenticationManager: diffController.authenticationManager, theme: theme, sender: sender, sourceView: diffToolbarView?.moreButtonSourceView, sourceRect: diffToolbarView?.moreButtonSourceRect)
    }
    
    func tappedUnwatch() {
        
        guard let articleTitle else {
            showGenericError()
            return
        }
        
        watchlistController.unwatch(pageTitle: articleTitle, siteURL: siteURL, viewController: self, authenticationManager: diffController.authenticationManager, theme: theme)
    }
    
    // MARK: Undo and Rollback

    func tappedUndo() {
        
        guard wmfProject != nil else {
            assertionFailure("WMFProject must be populated before attempting undo call.")
            return
        }

        if let pageURL = fetchPageURL() {
            EditAttemptFunnel.shared.logInit(pageURL: pageURL)
        }
        
        WatchlistFunnel.shared.logDiffToolbarTapUndo(project: wikimediaProject)
        
        let message = WMFLocalizedString("diff-undo-message", value: "This will undo the changes made by the revisions(s) of the article shown here. To continue, please provide a reason for undoing this edit.", comment: "Message showed in alert when user taps undo in diff toolbar.")

        let alertController = UIAlertController(title: CommonStrings.undo, message: message, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.clearButtonMode = .always
            textField.addTarget(self, action: #selector(self.undoSummaryTextfieldDidChange), for: .editingChanged)
            self.undoAlertSummaryTextField = textField
        }

        let cancel = UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel) { [weak self] (action) in
            WatchlistFunnel.shared.logDiffUndoAlertTapCancel(project: self?.wikimediaProject)
            if let pageURL = self?.fetchPageURL() {
                EditAttemptFunnel.shared.logAbort(pageURL: pageURL)
            }
        }
        
        let undo = UIAlertAction(title: CommonStrings.undo, style: .destructive) { [weak self] (action) in
            
            WatchlistFunnel.shared.logDiffUndoAlertTapUndo(project: self?.wikimediaProject)
            
            self?.performUndo()
        }
        
        undo.isEnabled = false
        undoAlertUndoAction = undo

        alertController.addAction(cancel)
        alertController.addAction(undo)

        present(alertController, animated: true)
    }
    
    @objc private func undoSummaryTextfieldDidChange() {
        undoAlertUndoAction?.isEnabled = !(undoAlertSummaryTextField?.text?.isEmpty ?? false)
    }
    
    private func performUndo() {
        guard let wmfProject = wmfProject,
              let title = articleTitle,
              let revisionID = toModelRevisionID,
              let username = toModel?.user,
              let summary = undoAlertSummaryTextField?.text else {
            return
        }
        fakeProgressController.start()

        if let pageURL = self.fetchPageURL() {
            EditAttemptFunnel.shared.logSaveAttempt(pageURL: pageURL)
        }
        
        WMFWatchlistDataController().undo(title: title, revisionID: UInt(revisionID), summary: summary, username: username, project: wmfProject) { [weak self] result in
            DispatchQueue.main.async {
                self?.completeRollbackOrUndo(result: result, isRollback: false)
            }
        }
    }

    func tappedRollback() {
        if let pageURL = fetchPageURL() {
            EditAttemptFunnel.shared.logInit(pageURL: pageURL)
        }
        WatchlistFunnel.shared.logDiffToolbarMoreTapRollback(project: wikimediaProject)
        let title = WMFLocalizedString("diff-rollback-alert-title", value: "Rollback edits", comment: "Title of alert when user taps rollback in diff toolbar.")
        let message = WMFLocalizedString("diff-rollback-alert-message", value: "Are you sure you want to rollback the edits?", comment: "Message in alert when user taps rollback in diff toolbar.")
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let cancel = UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel) { [weak self] (action) in
            WatchlistFunnel.shared.logDiffRollbackAlertTapCancel(project: self?.wikimediaProject)
            if let pageURL = self?.fetchPageURL() {
                EditAttemptFunnel.shared.logAbort(pageURL: pageURL)
            }
        }
        let rollback = UIAlertAction(title: CommonStrings.rollback, style: .destructive) { [weak self] (action) in
            WatchlistFunnel.shared.logDiffRollbackAlertTapRollback(project: self?.wikimediaProject)
            self?.performRollback()
        }
        
        alertController.addAction(cancel)
        alertController.addAction(rollback)
        present(alertController, animated: true)
    }
    
    private func performRollback() {
        guard let wmfProject = wmfProject,
              let title = articleTitle,
              let username = toModel?.user else {
            return
        }

        fakeProgressController.start()
        if let pageURL = self.fetchPageURL() {
            EditAttemptFunnel.shared.logSaveAttempt(pageURL: pageURL)
        }

        WMFWatchlistDataController().rollback(title: title, project: wmfProject, username: username) { [weak self] result in
            DispatchQueue.main.async {
                self?.completeRollbackOrUndo(result: result, isRollback: true)
            }
        }
    }
    
    private func completeRollbackOrUndo(result: Result<WMFUndoOrRollbackResult, Error>, isRollback: Bool) {
        fakeProgressController.stop()
        
        switch result {
        case .success(let result):
            
            if isRollback {
                WatchlistFunnel.shared.logDiffRollbackSuccess(revisionID: result.newRevisionID, project: self.wikimediaProject)
            } else {
                WatchlistFunnel.shared.logDiffUndoSuccess(revisionID: result.newRevisionID, project: self.wikimediaProject)
            }
            
            if let pageURL = self.fetchPageURL() {
                    EditAttemptFunnel.shared.logSaveSuccess(pageURL: pageURL, revisionId: result.newRevisionID)
            }

            let diffVC = DiffContainerViewController(siteURL: siteURL, theme: theme, fromRevisionID: result.oldRevisionID, toRevisionID: result.newRevisionID, articleTitle: articleTitle, articleSummaryController: diffController.articleSummaryController, authenticationManager: diffController.authenticationManager)

            animateDirection = .up
            replaceLastAndPush(with: diffVC)
            revisionRetrievingDelegate?.refreshRevisions()
            
            let message = isRollback ? CommonStrings.diffRollbackSuccess : CommonStrings.diffUndoSuccess
            if UIAccessibility.isVoiceOverRunning {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: message)
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    WMFAlertManager.sharedInstance.showSuccessAlert(message, sticky: false, dismissPreviousAlerts: true, tapCallBack: nil)
                }
            }
            if isRollback {
                WatchlistFunnel.shared.logDiffRollbackDisplaySuccessToast(project: self.wikimediaProject)
            } else {
                WatchlistFunnel.shared.logDiffUndoDisplaySuccessToast(project: self.wikimediaProject)
            }
            
            
        case .failure(let error):
            if let pageURL = self.fetchPageURL() {
                EditAttemptFunnel.shared.logSaveFailure(pageURL: pageURL)
            }

            let fallback: (Error) -> Void = { error in
                let errorReason = (error as NSError).domain + "." + String((error as NSError).code)

                if isRollback {
                    WatchlistFunnel.shared.logDiffRollbackFail(errorReason: errorReason, project: self.wikimediaProject)
                } else {
                    WatchlistFunnel.shared.logDiffUndoFail(errorReason: errorReason, project: self.wikimediaProject)
                }
                if UIAccessibility.isVoiceOverRunning {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: CommonStrings.unknownError)
                    }
                } else {
                    WMFAlertManager.sharedInstance.showErrorAlert(error, sticky: false, dismissPreviousAlerts: true)
                }
            }
            
            guard let dataControllerError = error as? WMFData.WMFDataControllerError else {
                fallback(error)
                return
            }
            
            switch dataControllerError {
            case .serviceError(let error):

                guard let mediaWikiError = error as? MediaWikiFetcher.MediaWikiFetcherError else {
                    fallback(error)
                    return
                }
                
                switch mediaWikiError {
                case .mediaWikiAPIResponseError(let displayError):
                    
                    let errorReason = displayError.loggingErrorReasonDomain + "." + displayError.code

                    if isRollback {
                        WatchlistFunnel.shared.logDiffRollbackFail(errorReason: errorReason, project: self.wikimediaProject)
                    } else {
                        WatchlistFunnel.shared.logDiffUndoFail(errorReason: errorReason, project: self.wikimediaProject)
                    }

                    wmf_showBlockedPanel(messageHtml: displayError.messageHtml, linkBaseURL: displayError.linkBaseURL, currentTitle: articleTitle ?? "", theme: theme)
                    return
                    
                default:
                    break
                }
                
            default:
                break
            }

            fallback(error)
        }
    }
}

extension DiffContainerViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if let direction = animateDirection {
            return DiffRevisionTransition(direction: direction)
        }
        
        return nil
    }
}

extension DiffContainerViewController: DiffRevisionAnimating {
    var embeddedViewController: UIViewController? {
        switch containerViewModel.state {
        case .data, .loading:
            return diffListViewController
        case .empty, .error:
            return scrollingEmptyViewController
        }
    }
}

extension DiffContainerViewController: WatchlistControllerDelegate {
    func didSuccessfullyWatchTemporarily(_ controller: WatchlistController) {
        diffToolbarView?.updateMoreButton(needsWatchButton: false, needsUnwatchHalfButton: true, needsUnwatchFullButton: false, needsArticleEditHistoryButton: true)
    }
    
    func didSuccessfullyWatchPermanently(_ controller: WatchlistController) {
        diffToolbarView?.updateMoreButton(needsWatchButton: false, needsUnwatchHalfButton: false, needsUnwatchFullButton: true, needsArticleEditHistoryButton: true)
    }
    
    func didSuccessfullyUnwatch(_ controller: WatchlistController) {
        diffToolbarView?.updateMoreButton(needsWatchButton: true, needsUnwatchHalfButton: false, needsUnwatchFullButton: false, needsArticleEditHistoryButton: true)
    }
}

extension DiffContainerViewController: DiffHeaderTitleViewTapDelegate {

    func userDidTapTitleLabel() {
        guard let navigationURL = fetchPageURL() else {
            return
        }

        navigate(to: navigationURL)
    }

}
