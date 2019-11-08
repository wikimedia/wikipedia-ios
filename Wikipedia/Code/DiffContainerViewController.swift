
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

class DiffContainerViewController: ViewController {
    
    private var containerViewModel: DiffContainerViewModel
    private var headerExtendedView: DiffHeaderExtendedView?
    private var headerTitleView: DiffHeaderTitleView?
    private var scrollingEmptyViewController: EmptyViewController?
    private var diffListViewController: DiffListViewController?
    private let diffController: DiffController
    private let fromModel: WMFPageHistoryRevision?
    private let toModel: WMFPageHistoryRevision
    private let siteURL: URL
    private let articleTitle: String
    private weak var revisionDelegate: DiffRevisionRetrieving?
    private let safeAreaBottomAlignView = UIView()
    
    private let type: DiffContainerViewModel.DiffType
    
    lazy private(set) var fakeProgressController: FakeProgressController = {
        let progressController = FakeProgressController(progress: navigationBar, delegate: navigationBar)
        progressController.delay = 0.0
        return progressController
    }()
    
    init(articleTitle: String, siteURL: URL, type: DiffContainerViewModel.DiffType, fromModel: WMFPageHistoryRevision?, toModel: WMFPageHistoryRevision, theme: Theme, diffController: DiffController? = nil, revisionDelegate: DiffRevisionRetrieving?) {
        self.type = type
        
        self.fromModel = fromModel
        self.toModel = toModel
        self.articleTitle = articleTitle
        self.revisionDelegate = revisionDelegate
        
        let forceSiteURL = URL(string: "https://en.wikipedia.beta.wmflabs.org")! //tonitodo: hardcoded to wmflabs for now
        self.siteURL = forceSiteURL
        
        if let diffController = diffController {
            self.diffController = diffController
        } else {
            self.diffController = DiffController(siteURL: forceSiteURL, articleTitle: articleTitle, type: type)
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
        
        setupHeaderViewIfNeeded()
        setupDiffListViewControllerIfNeeded()
        fetchIntermediateCountIfNeeded()
        apply(theme: theme)
        
        fetchDiff()
        fetchEditCountIfNeeded()
        
    }
    
    @objc func tappedDown() {
        
        guard let fromModel = fromModel else {
            assertionFailure("fromModel needs to be populated at this point before user attempts to go further back in history")
            return
        }
        
        //note DiffContainerViewController knows how to determine a fromModel on it's own. Hence why we don't care if previousRevision is null here, this is just an optimization.
        let previousRevision = revisionDelegate?.retrievePreviousRevision(with: fromModel)
        
        let singleDiffVC = DiffContainerViewController(articleTitle: articleTitle, siteURL: siteURL, type: .single(byteDifference: fromModel.revisionSize), fromModel: previousRevision, toModel: fromModel, theme: theme, revisionDelegate: revisionDelegate)
        wmf_push(singleDiffVC, animated: true)
        
    }
    
    @objc func tappedUp() {
        
        //note because we aren't filtering in History yet, PageHistoryViewController should always be able to tell us the next revision. If filtering is implemented this method will fail, and we will need to have DiffContainerViewController know how to handle a situation where fromModel is populated but toModel is not (that is, hide header & list, fetch next toModel & diff, then show header & list)
        guard let nextRevision = revisionDelegate?.retrieveNextRevision(with: toModel) else {
            assertionFailure("Unable to determine next revision. Perhaps user tapped the latest revision in history? Up arrow should be disabled in this case.")
            return
        }
        
        let singleDiffVC = DiffContainerViewController(articleTitle: articleTitle, siteURL: siteURL, type: .single(byteDifference: nextRevision.revisionSize), fromModel: toModel, toModel: nextRevision, theme: theme, revisionDelegate: revisionDelegate)
        wmf_push(singleDiffVC, animated: true)
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
    }
}

private extension DiffContainerViewController {
    
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
    
    func fetchIntermediateCountIfNeeded() {
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
        let headerViewModel = containerViewModel.headerViewModel
        
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
        let header = containerViewModel.headerViewModel
        switch header.headerType {
        case .single(let editorViewModel, _):
            editorViewModel.numberOfEdits = editCount
        case .compare:
            assertionFailure("Should not call this method for the compare type.")
            return
        }
        
        //update view
        headerExtendedView?.update(header)
    }
    
    func fetchDiff() {
        view.setNeedsLayout()
        view.layoutIfNeeded()
        let width = diffListViewController?.collectionView.frame.width
        
        containerViewModel.state = .loading
        diffController.fetchDiff(fromRevisionId: fromModel?.revisionID, toRevisionId: toModel.revisionID, theme: theme, traitCollection: traitCollection) { [weak self] (result) in

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
        
        switch containerViewModel.headerViewModel.headerType {
        case .compare(_, let navBarTitle):
            navigationBar.title = navBarTitle
        default:
            break
        }
        
        headerTitleView?.update(containerViewModel.headerViewModel.title)
        headerExtendedView?.update(containerViewModel.headerViewModel)
        navigationBar.isExtendedViewHidingEnabled = containerViewModel.headerViewModel.isExtendedViewHidingEnabled
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
    
    func setupDiffListViewControllerIfNeeded() {
        if diffListViewController == nil {
            let diffListViewController = DiffListViewController(theme: theme, delegate: self, type: type)
            wmf_add(childController: diffListViewController, andConstrainToEdgesOfContainerView: view, belowSubview: navigationBar)
            self.diffListViewController = diffListViewController
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
    
    private func showNoInternetConnectionAlertOrOtherWarning(from error: Error, noInternetConnectionAlertMessage: String = CommonStrings.noInternetConnection) {

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
        
        guard let fromModel = fromModel else {
            assertionFailure("Revision tapping is not supported on a page without a from model")
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
        
        let singleDiffVC = DiffContainerViewController(articleTitle: articleTitle, siteURL: siteURL, type: .single(byteDifference: revision.revisionSize), fromModel: nil, toModel: revision, theme: theme, revisionDelegate: revisionDelegate)
        wmf_push(singleDiffVC, animated: true)
    }
    
    
}
