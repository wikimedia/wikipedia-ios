
import UIKit

struct StubRevisionModel {
    let revisionId: Int
    let summary: String
    let username: String
    let timestamp: Date
}

class DiffContainerViewController: ViewController {
    
    private var containerViewModel: DiffContainerViewModel
    private var headerExtendedView: DiffHeaderExtendedView?
    private var headerTitleView: DiffHeaderTitleView?
    private var emptyViewController: EmptyViewController?
    private var diffListViewController: DiffListViewController?
    private let diffController: DiffController
    private let fromModel: WMFPageHistoryRevision?
    private let toModel: WMFPageHistoryRevision
    private let siteURL: URL
    private let articleTitle: String
    
    private let type: DiffContainerViewModel.DiffType
    
    init(articleTitle: String, siteURL: URL, type: DiffContainerViewModel.DiffType, fromModel: WMFPageHistoryRevision?, toModel: WMFPageHistoryRevision, theme: Theme, diffController: DiffController? = nil) {
        self.type = type
        
        self.fromModel = fromModel
        self.toModel = toModel
        self.articleTitle = articleTitle
        
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

        if let emptyViewController = emptyViewController {
            navigationBar.setNeedsLayout()
            navigationBar.layoutSubviews()
            let targetRect = CGRect(x: 0, y: navigationBar.visibleHeight, width: emptyViewController.view.frame.width, height: emptyViewController.view.frame.height - navigationBar.visibleHeight)
            let convertedTargetRect = view.convert(targetRect, to: emptyViewController.view)
            emptyViewController.centerEmptyView(within: convertedTargetRect)
        }
    }
    
    override func apply(theme: Theme) {
        
        guard isViewLoaded else {
            return
        }
        
        super.apply(theme: theme)
        
        view.backgroundColor = theme.colors.midBackground
        
        headerTitleView?.apply(theme: theme)
        headerExtendedView?.apply(theme: theme)
        diffListViewController?.apply(theme: theme)
    }
}

private extension DiffContainerViewController {
    
    func evaluateState() {
        
        switch containerViewModel.state {
            case .empty:
                setupEmptyViewControllerIfNeeded()
                emptyViewController?.view.isHidden = false
                diffListViewController?.view.isHidden = true
                
        default:
            emptyViewController?.view.isHidden = true
            diffListViewController?.view.isHidden = false
            break
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
                        case .failure(let error):
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
                        case .failure(let error):
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
            return
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
                    
                    if listViewModel.count == 0 {
                        self.containerViewModel.state = .empty
                    }
                }
                
            case .failure(let error):
                print(error)
                //tonitodo: error handling
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
    
    func setupEmptyViewControllerIfNeeded() {
        
        guard emptyViewController == nil else {
            return
        }

        emptyViewController = EmptyViewController(nibName: "EmptyViewController", bundle: nil)
        if let emptyViewController = emptyViewController {
            emptyViewController.canRefresh = false
            emptyViewController.theme = theme
            addChildViewController(childViewController: emptyViewController, belowSubview: navigationBar)
            emptyViewController.type = .diff
            emptyViewController.view.isHidden = true
            emptyViewController.delegate = self
        }
    }
    
    func addChildViewController(childViewController: UIViewController, belowSubview: UIView) {
           addChild(childViewController)
           childViewController.view.translatesAutoresizingMaskIntoConstraints = false
           view.insertSubview(childViewController.view, belowSubview: belowSubview)
           
           let topConstraint = childViewController.view.topAnchor.constraint(equalTo: view.topAnchor)
            let bottomConstraint = childViewController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
           let leadingConstraint = childViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor)
           let trailingConstraint = childViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
           NSLayoutConstraint.activate([topConstraint, bottomConstraint, leadingConstraint, trailingConstraint])
           childViewController.didMove(toParent: self)
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
        
        let singleDiffVC = DiffContainerViewController(articleTitle: articleTitle, siteURL: siteURL, type: .single(byteDifference: revision.revisionSize), fromModel: nil, toModel: revision, theme: theme)
        wmf_push(singleDiffVC, animated: true)
    }
    
    
}
