
import UIKit

struct StubRevisionModel {
    let revisionId: Int
    let summary: String
    let username: String
    let timestamp: Date
}

protocol DiffRevisionRetrieving: class {
    func retrievePreviousRevision(with sourceRevision: WMFPageHistoryRevision) -> WMFPageHistoryRevision?
    func retrieveNextRevision(with sourceRevision: WMFPageHistoryRevision) -> WMFPageHistoryRevision?
}

class DiffContainerViewController: ViewController, HintPresenting {
    
    struct NextPrevModel {
        let from: WMFPageHistoryRevision
        let to: WMFPageHistoryRevision
    }
    
    private var containerViewModel: DiffContainerViewModel
    private var headerExtendedView: DiffHeaderExtendedView?
    private var headerTitleView: DiffHeaderTitleView?
    private var scrollingEmptyViewController: EmptyViewController?
    private var diffListViewController: DiffListViewController?
    private var diffToolbarView: DiffToolbarView?
    private let diffController: DiffController
    private var fromModel: WMFPageHistoryRevision?
    private var toModel: WMFPageHistoryRevision?
    private let siteURL: URL
    private let articleTitle: String
    private let safeAreaBottomAlignView = UIView()
    
    private let type: DiffContainerViewModel.DiffType
    
    private let revisionRetrievingDelegate: DiffRevisionRetrieving?
    
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
    
    init?(articleTitle: String, siteURL: URL, type: DiffContainerViewModel.DiffType, fromModel: WMFPageHistoryRevision?, toModel: WMFPageHistoryRevision?, theme: Theme, diffController: DiffController? = nil, revisionRetrievingDelegate: DiffRevisionRetrieving?) {
        
        guard fromModel != nil || toModel != nil else {
            assertionFailure("Need at least one revision model for diff screen.")
            return nil
        }
        
        self.type = type
        
        self.fromModel = fromModel
        self.toModel = toModel
        self.articleTitle = articleTitle
        self.revisionRetrievingDelegate = revisionRetrievingDelegate
        self.siteURL = siteURL
        
        if let diffController = diffController {
            self.diffController = diffController
        } else {
            self.diffController = DiffController(siteURL: siteURL, articleTitle: articleTitle, revisionRetrievingDelegate: revisionRetrievingDelegate, type: type)
        }
        
        self.containerViewModel = DiffContainerViewModel(type: type, fromModel: fromModel, toModel: toModel, listViewModel: nil, theme: theme)
        
        super.init()
        
        self.theme = theme
        
        self.containerViewModel.stateHandler = { [weak self] in
            self?.evaluateState()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        assert(fromModel != nil || toModel != nil, "Need at least one revision model for diff screen.")
        
        if fromModel == nil {
            fetchFromModelAndSetup()
        } else if toModel == nil {
            fetchToModelAndSetup()
        } else {
            startSetup()
            midSetup()
            completeSetup()
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
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let scrollView = diffListViewController?.scrollView {
            configureExtendedViewSquishing(scrollView: scrollView)
        }

        if let emptyViewController = scrollingEmptyViewController {
            navigationBar.setNeedsLayout()
            navigationBar.layoutSubviews()
            let bottomSafeAreaHeight = view.bounds.height - safeAreaBottomAlignView.frame.maxY
            let targetRect = CGRect(x: 0, y: navigationBar.visibleHeight, width: emptyViewController.view.frame.width, height: emptyViewController.view.frame.height - navigationBar.visibleHeight - bottomSafeAreaHeight)
            //tonitodo: this still doesn't seem quite centered...
            let convertedTargetRect = view.convert(targetRect, to: emptyViewController.view)
            print(convertedTargetRect)
            emptyViewController.centerEmptyView(within: convertedTargetRect)
        }
    }
    
    override func apply(theme: Theme) {
        
        super.apply(theme: theme)
        
        guard isViewLoaded else {
            return
        }
        
        view.backgroundColor = theme.colors.paperBackground
        
        headerTitleView?.apply(theme: theme)
        headerExtendedView?.apply(theme: theme)
        diffListViewController?.apply(theme: theme)
        scrollingEmptyViewController?.apply(theme: theme)
        diffToolbarView?.apply(theme: theme)
    }
}

//MARK: Private

private extension DiffContainerViewController {
    
    func fetchToModelAndSetup() {
        guard let fromModel = fromModel else {
            assertionFailure("toModel must be populated for fetching fromModel")
            return
        }
        
        startSetup()
        containerViewModel.state = .loading
        
        diffController.fetchRevision(sourceRevision: fromModel, direction: .next) { (result) in
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
    
    func fetchFromModelAndSetup() {
        
        guard let toModel = toModel else {
            assertionFailure("toModel must be populated for fetching fromModel")
            return
        }
        
        startSetup()
        midSetup()
        containerViewModel.state = .loading
        
        diffController.fetchRevision(sourceRevision: toModel, direction: .previous) { (result) in
            switch result {
            case .success(let revision):
                DispatchQueue.main.async {
                    self.fromModel = revision
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
    }
    
    func midSetup() {
        guard let _ = toModel else {
            assertionFailure("Expecting at least toModel to be populated for this method.")
            return
        }
        
        setupHeaderViewIfNeeded()
        setupDiffListViewControllerIfNeeded()
        fetchIntermediateCountIfNeeded()
        fetchEditCountIfNeeded()
        apply(theme: theme)
    }
    
    func completeSetup() {
        
        guard let _ = fromModel,
            let _ = toModel else {
                assertionFailure("Both models must be populated at this point.")
                return
        }
        
        //models ready to fetch diff.
        fetchDiff()
        
        //Still need models for enabling/disabling prev/next buttons
        populatePrevNextModelsForToolbar()
    }
    
    func populatePrevNextModelsForToolbar() {
        
        guard let fromModel = fromModel,
            let toModel = toModel else {
                assertionFailure("Both models must be populated at this point.")
                return
        }
        
        //populate nextModel for enabling previous/next button
        let nextFromModel = toModel
        var nextToModel: WMFPageHistoryRevision?
        diffController.fetchRevision(sourceRevision: nextFromModel, direction: .next) { [weak self] (result) in
            
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
                    self.completeSetup()
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.containerViewModel.state = .error(error: error)
                }
            }
        }
        
        //populate nextModel for enabling previous/next button
        var prevFromModel: WMFPageHistoryRevision?
        let prevToModel = fromModel
        diffController.fetchRevision(sourceRevision: prevToModel, direction: .previous) { [weak self] (result) in
            
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
                    self.completeSetup()
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.containerViewModel.state = .error(error: error)
                }
            }
        }
    }
    
    func fullRevisionDiffURL() -> URL? {
        
        guard let toModel = toModel else {
            return nil
        }
        
        var components = URLComponents(url: siteURL, resolvingAgainstBaseURL: false)
        components?.path = "/w/index.php"
        components?.queryItems = [
            URLQueryItem(name: "title", value: articleTitle),
            URLQueryItem(name: "diff", value: String(toModel.revisionID)),
            URLQueryItem(name: "oldid", value: String(toModel.parentID))
        ]
        return components?.url
    }
    
    func evaluateState() {
        
        switch containerViewModel.state {

        case .loading:
            fakeProgressController.start()
            scrollingEmptyViewController?.view.isHidden = true
            diffListViewController?.view.isHidden = true
        case .empty:
            fakeProgressController.stop()
            setupScrollingEmptyViewControllerIfNeeded()
            switch type {
            case .compare:
                scrollingEmptyViewController?.type = .diffCompare
            case .single:
                scrollingEmptyViewController?.type = .diffSingle
            }
            scrollingEmptyViewController?.view.isHidden = false
            diffListViewController?.view.isHidden = true
        case .error(let error):
            fakeProgressController.stop()
            showNoInternetConnectionAlertOrOtherWarning(from: error)
            setupScrollingEmptyViewControllerIfNeeded()
            scrollingEmptyViewController?.type = .diffError
            scrollingEmptyViewController?.view.isHidden = false
            diffListViewController?.view.isHidden = true
        case .data:
            fakeProgressController.stop()
            scrollingEmptyViewController?.view.isHidden = true
            diffListViewController?.view.isHidden = false
        }
    }
    
    func fetchEditCountIfNeeded() {
        
        guard let toModel = toModel else {
            return
        }
        
        switch type {
        case .single:
            if let username = toModel.user {
                diffController.fetchEditCount(guiUser: username, siteURL: siteURL) { [weak self] (result) in
                    
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

    private func show(hintViewController: HintViewController){
        
        guard let toolbarView =  diffToolbarView else {
            return
        }
        
        let showHint = {
            self.hintController = HintController(hintViewController: hintViewController)
            self.hintController?.toggle(presenter: self, context: nil, theme: self.theme, additionalBottomSpacing: toolbarView.toolbarHeight)
            self.hintController?.setHintHidden(false)
        }
        if let hintController = self.hintController {
            hintController.setHintHidden(true) {
                showHint()
            }
        } else {
            showHint()
        }
    }
    
    private func thankRevisionAuthor() {
        
        guard let toModel = toModel else {
            return
        }
        
        switch type {
        case .single:
            diffController.thankRevisionAuthor(toRevisionId: toModel.revisionID) { [weak self] (result) in
                guard let self = self else {
                    return
                }
                DispatchQueue.main.async {
                    switch result {
                    case .success(let result):
                        self.show(hintViewController: RevisionAuthorThankedHintVC(recipient: result.recipient))
                    case .failure(let error as NSError):
                        self.show(hintViewController: RevisionAuthorThanksErrorHintVC(error: error))
                    }
                }
            }
        case .compare:
            break
        }
    }
    
    func fetchIntermediateCountIfNeeded() {
        
        guard let toModel = toModel else {
            return
        }
        
        switch type {
        case .compare:
            if let fromModel = fromModel {
                let fromID = fromModel.revisionID
                let toID = toModel.revisionID
                diffController.fetchIntermediateCounts(fromRevisionId: fromID, toRevisionId: toID) { [weak self] (result) in
                    
                    guard let self = self else {
                        return
                    }
                    
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let counts):
                            self.updateHeaderWithIntermediateCounts(counts)
                        case .failure:
                            break
                        }
                    }
                }
            } else {
                assertionFailure("Expect compare type to have fromModel for fetching intermediate count")
            }
        case .single:
            break
        }
    }
    
    func updateHeaderWithIntermediateCounts(_ counts: (revision: Int, user: Int)) {
        
        //update view model
        guard let headerViewModel = containerViewModel.headerViewModel else {
            return
        }
        
        switch type {
        case .compare(let articleTitle):
            
            let newTitleViewModel = DiffHeaderViewModel.generateTitleViewModelForCompare(articleTitle: articleTitle, counts: counts)
            headerViewModel.title = newTitleViewModel
            headerTitleView?.update(newTitleViewModel)
        case .single:
            assertionFailure("Should not call this method for the compare type.")
        }
    }
    
    func updateHeaderWithEditCount(_ editCount: Int) {
        
        //update view model
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
        
        //update view
        headerExtendedView?.update(headerViewModel)
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

                self.containerViewModel.listViewModel = listViewModel
                self.diffListViewController?.updateListViewModels(listViewModel: listViewModel, updateType: .initialLoad(width: width ?? 0))
                
                DispatchQueue.main.async {
                    self.diffListViewController?.applyListViewModelChanges(updateType: .initialLoad(width: width ?? 0))
                    
                    self.diffListViewController?.updateScrollViewInsets()
                    
                    self.containerViewModel.state = listViewModel.count == 0 ? .empty : .data
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self.containerViewModel.state = .error(error: error)
                }
            }
        }
    }
    
    func configureExtendedViewSquishing(scrollView: UIScrollView) {
        guard let headerTitleView = headerTitleView,
        let headerExtendedView = headerExtendedView else {
            return
        }
        
        let beginSquishYOffset = headerTitleView.frame.height
        let scrollYOffset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        headerExtendedView.configureHeight(beginSquishYOffset: beginSquishYOffset, scrollYOffset: scrollYOffset)
    }
    
    func setupHeaderViewIfNeeded() {
        
        guard let headerViewModel = containerViewModel.headerViewModel else {
            return
        }
        
        if self.headerTitleView == nil {
            let headerTitleView = DiffHeaderTitleView(frame: .zero)
            headerTitleView.translatesAutoresizingMaskIntoConstraints = false
            
            navigationBar.isUnderBarViewHidingEnabled = true
            navigationBar.allowsUnderbarHitsFallThrough = true
            navigationBar.addUnderNavigationBarView(headerTitleView)
            navigationBar.underBarViewPercentHiddenForShowingTitle = 0.6
            navigationBar.isShadowBelowUnderBarView = true
            
            self.headerTitleView = headerTitleView
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
        
        headerTitleView?.update(headerViewModel.title)
        headerExtendedView?.update(headerViewModel)
        navigationBar.isExtendedViewHidingEnabled = headerViewModel.isExtendedViewHidingEnabled
    }
    
    func setupScrollingEmptyViewControllerIfNeeded() {
        
        guard scrollingEmptyViewController == nil else {
            return
        }

        scrollingEmptyViewController = EmptyViewController(nibName: "EmptyViewController", bundle: nil)
        if let emptyViewController = scrollingEmptyViewController {
            emptyViewController.canRefresh = false
            emptyViewController.theme = theme
            
            //add alignment view view
            safeAreaBottomAlignView.translatesAutoresizingMaskIntoConstraints = false
            safeAreaBottomAlignView.isHidden = true
            view.addSubview(safeAreaBottomAlignView)
            let leadingConstraint = view.leadingAnchor.constraint(equalTo: safeAreaBottomAlignView.leadingAnchor)
            let bottomConstraint = view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: safeAreaBottomAlignView.bottomAnchor)
            let widthAnchor = safeAreaBottomAlignView.widthAnchor.constraint(equalToConstant: 1)
            let heightAnchor = safeAreaBottomAlignView.heightAnchor.constraint(equalToConstant: 1)
            NSLayoutConstraint.activate([leadingConstraint, bottomConstraint, widthAnchor, heightAnchor])
            
            wmf_add(childController: emptyViewController, andConstrainToEdgesOfContainerView: view, belowSubview: navigationBar)
            emptyViewController.view.isHidden = true
            emptyViewController.delegate = self
        }
    }
    
    func setupToolbarIfNeeded() {
        
        switch type {
        case .single:
            if diffToolbarView == nil {
                let toolbarView = DiffToolbarView(frame: .zero)
                self.diffToolbarView = toolbarView
                toolbarView.delegate = self
                toolbarView.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(toolbarView)
                let bottom = view.bottomAnchor.constraint(equalTo: toolbarView.bottomAnchor)
                let leading = view.leadingAnchor.constraint(equalTo: toolbarView.leadingAnchor)
                let trailing = view.trailingAnchor.constraint(equalTo: toolbarView.trailingAnchor)
                NSLayoutConstraint.activate([bottom, leading, trailing])
                toolbarView.apply(theme: theme)
                toolbarView.setPreviousButtonState(isEnabled: false)
                toolbarView.setNextButtonState(isEnabled: false)
            }
        default:
            break
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
        if (UserDefaults.wmf.bool(forKey: key)) {
            return
        }
        let panelVC = DiffEducationalPanelViewController(showCloseButton: false, primaryButtonTapHandler: { [weak self] (action) in
            self?.presentedViewController?.dismiss(animated: true)
        }, secondaryButtonTapHandler: nil, dismissHandler: nil, discardDismissHandlerOnPrimaryButtonTap: true, theme: theme)
        present(panelVC, animated: true)
        UserDefaults.wmf.set(true, forKey: key)
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
            
        }  else {
            
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
        
        configureExtendedViewSquishing(scrollView: scrollView)
    }
}

extension DiffContainerViewController: EmptyViewControllerDelegate {
    func triggeredRefresh(refreshCompletion: @escaping () -> Void) {
        //no refreshing
    }
    
    func emptyViewScrollViewDidScroll(_ scrollView: UIScrollView) {
        self.scrollViewDidScroll(scrollView)
    }
}

extension DiffContainerViewController: DiffHeaderActionDelegate {
    func tappedUsername(username: String) {
        if let username = (username as NSString).wmf_normalizedPageTitle() {
            let userPageURL = siteURL.wmf_URL(withPath: "/wiki/User:\(username)", isMobile: true)
            wmf_openExternalUrl(userPageURL)
        }
    }
    
    func tappedRevision(revisionID: Int) {
        
        guard let fromModel = fromModel,
        let toModel = toModel else {
            assertionFailure("Revision tapping is not supported on a page without models")
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
        
        if let singleDiffVC = DiffContainerViewController(articleTitle: articleTitle, siteURL: siteURL, type: .single(byteDifference: revision.revisionSize), fromModel: nil, toModel: revision, theme: theme, revisionRetrievingDelegate: revisionRetrievingDelegate) {
            wmf_push(singleDiffVC, animated: true)
        }
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
        let thanksMessage = WMFLocalizedString("diff-thanks-sent", value: "Your 'Thanks' was set to %1$@", comment: "Message indicating thanks was sent. Parameters:\n* %1$@ - name of user who was thanked")
        let thanksMessageWithRecipient = String.localizedStringWithFormat(thanksMessage, recipient)
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
        
        guard let prevModel = prevModel else {
            assertionFailure("Expecting prevModel to be populated. Previous button should have been disabled if there's no model.")
            return
        }
        
        if let singleDiffVC = DiffContainerViewController(articleTitle: articleTitle, siteURL: siteURL, type: .single(byteDifference: prevModel.to.revisionSize), fromModel: prevModel.from, toModel: prevModel.to, theme: theme, revisionRetrievingDelegate: revisionRetrievingDelegate) {
            replaceLastAndPush(with: singleDiffVC)
        }
    }
    
    func tappedNext() {
        
        guard let nextModel = nextModel else {
            assertionFailure("Expecting prevModel to be populated. Previous button should have been disabled if there's no model.")
            return
        }
        
        if let singleDiffVC = DiffContainerViewController(articleTitle: articleTitle, siteURL: siteURL, type: .single(byteDifference: nextModel.to.revisionSize), fromModel: nextModel.from, toModel: nextModel.to, theme: theme, revisionRetrievingDelegate: revisionRetrievingDelegate) {
            replaceLastAndPush(with: singleDiffVC)
        }
    }
    
    func tappedShare(_ sender: UIView?) {
        guard let diffURL = fullRevisionDiffURL(),
        let toolbarView = diffToolbarView else {
            assertionFailure("Couldn't get full revision diff URL")
            return
        }
        
        let activityViewController = UIActivityViewController(activityItems: [diffURL], applicationActivities: [TUSafariActivity()])
        
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = sender
            popover.sourceRect = sender?.bounds ?? toolbarView.bounds
            popover.permittedArrowDirections = .down
        }
        
        present(activityViewController, animated: true)
    }
    
    func tappedThank(isAlreadySelected: Bool, isLoggedIn: Bool) {
        
        guard let toModel = toModel else {
            return
        }
        
        guard !isAlreadySelected else {
            self.show(hintViewController: AuthorAlreadyThankedHintVC())
            return
        }
        
        guard !toModel.isAnon else {
            self.show(hintViewController: AnonymousUsersCannotBeThankedHintVC())
            return
        }
        
        guard isLoggedIn else {
            wmf_showLoginOrCreateAccountToThankRevisionAuthorPanel(theme: theme, dismissHandler: nil, loginSuccessCompletion: {
                self.apply(theme: self.theme)
            }, loginDismissedCompletion: nil)
            return
        }

        guard !UserDefaults.wmf.wmf_didShowThankRevisionAuthorEducationPanel() else {
            thankRevisionAuthor()
            return
        }

        wmf_showThankRevisionAuthorEducationPanel(theme: theme, sendThanksHandler: {_ in
            UserDefaults.wmf.wmf_setDidShowThankRevisionAuthorEducationPanel(true)
            self.dismiss(animated: true, completion: {
                self.thankRevisionAuthor()
            })
        })
    }
    
    
}
