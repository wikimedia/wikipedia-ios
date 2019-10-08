
import UIKit

struct StubRevisionModel {
    let revisionId: Int
    let summary: String
    let username: String
    let timestamp: Date
}

class DiffContainerViewController: ViewController {
    
    private var containerViewModel: DiffContainerViewModel {
        didSet {
            update(containerViewModel)
        }
    }
    private var headerExtendedView: DiffHeaderExtendedView?
    private var headerTitleView: DiffHeaderTitleView?
    private var diffListViewController: DiffListViewController?
    
    //tonitodo: can I remove these?
    private let type: DiffContainerViewModel.DiffType
    private let fromModel: StubRevisionModel
    private let toModel: StubRevisionModel
    
    //TONITODO: delete
    @objc static func stubCompareContainerViewController(theme: Theme) -> DiffContainerViewController {
        let revisionModel1 = StubRevisionModel(revisionId: 123, summary: "Summary 1", username: "fancypants", timestamp: Date(timeInterval: -(60*60*24*3), since: Date()))
        let revisionModel2 = StubRevisionModel(revisionId: 234, summary: "Summary 2", username: "funtimez2019", timestamp: Date(timeInterval: -(60*60*24*2), since: Date()))
        let stubCompareVC = DiffContainerViewController(type: .compare(articleTitle: "Dog", numberOfIntermediateRevisions: 1, numberOfIntermediateUsers: 1), fromModel: revisionModel1, toModel: revisionModel2, theme: theme)
        return stubCompareVC
    }
    
    @objc static func stubSingleContainerViewController(theme: Theme) -> DiffContainerViewController {
        let revisionModel1 = StubRevisionModel(revisionId: 123, summary: "Summary 1", username: "fancypants", timestamp: Date(timeInterval: -(60*60*24*3), since: Date()))
        let revisionModel2 = StubRevisionModel(revisionId: 234, summary: "Summary 2", username: "funtimez2019", timestamp: Date(timeInterval: -(60*60*24*2), since: Date()))
        let stubSingleVC = DiffContainerViewController(type: .single(byteDifference: -6), fromModel: revisionModel1, toModel: revisionModel2, theme: theme)
        return stubSingleVC
    }
    
    init(type: DiffContainerViewModel.DiffType, fromModel: StubRevisionModel, toModel: StubRevisionModel, theme: Theme) {
        
        self.type = type
        self.fromModel = fromModel
        self.toModel = toModel
        
        self.containerViewModel = DiffContainerViewModel(type: type, fromModel: fromModel, toModel: toModel, theme: theme, listViewModel: nil)
        
        super.init()
        
        self.theme = theme
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.isNavigationBarHidden = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard let headerTitleView = headerTitleView else {
            return
        }
        
        let newBeginSquishYOffset = headerTitleView.frame.height
        switch containerViewModel.headerViewModel.type {
        case .compare(let compareViewModel):
            if compareViewModel.beginSquishYOffset != newBeginSquishYOffset {
                compareViewModel.beginSquishYOffset = newBeginSquishYOffset
                headerExtendedView?.update(containerViewModel.headerViewModel)
            }
        default:
            break
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //TONITODO: fetch revision compare here.
        //once revision compare fetch finishes:
        //stub, //TONITODO delete
        navigationController?.isNavigationBarHidden = true
        let range1 = DiffListItemHighlightRange(start: 7, length: 5, type: .added)
        let range2 = DiffListItemHighlightRange(start: 12, length: 4, type: .deleted)
        let item1 = DiffListItemViewModel(text: "Testing here now", highlightedRanges: [range1, range2])
        
        //let changeCompareViewModel = DiffListChangeViewModel(type: .compareRevision("Line 1"), items: [item1])
        //let changeSingleViewModel = DiffListChangeViewModel(type: .singleRevison("Pirates"), items: [item1])
        let contextViewModel = DiffListContextViewModel(lines: "Line 1-2", isExpanded: false, items: ["Testing here now", ""], theme: theme)
        
        self.containerViewModel = DiffContainerViewModel(type: type, fromModel: fromModel, toModel: toModel, theme: theme, listViewModel: [contextViewModel, contextViewModel, contextViewModel, contextViewModel, contextViewModel, contextViewModel, contextViewModel, contextViewModel])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = false
    }
    
    override func apply(theme: Theme) {
        
        guard isViewLoaded else {
            return
        }
        
        super.apply(theme: theme)

        if containerViewModel.theme != theme {
            containerViewModel.theme = theme
            update(containerViewModel)
        }
    }
    
}

private extension DiffContainerViewController {
    func update(_ containerViewModel: DiffContainerViewModel) {
        
        navigationBar.title = containerViewModel.navBarTitle
        if let listViewModel = containerViewModel.listViewModel {
            setupDiffListViewControllerIfNeeded()
            diffListViewController?.update(listViewModel)
        } else {
            //TONITODO: show loading state?
            //or container has an empty (no differences), error, and list state. list state has associated value of items, otherwise things change)
        }
        
        setupHeaderViewIfNeeded()
        headerTitleView?.update(containerViewModel.headerViewModel.title)
        headerExtendedView?.update(containerViewModel.headerViewModel)
        navigationBar.isExtendedViewHidingEnabled = containerViewModel.headerViewModel.isExtendedViewHidingEnabled
        view.setNeedsLayout()
        view.layoutIfNeeded()
        updateScrollViewInsets()
        
        //theming
        view.backgroundColor = containerViewModel.theme.colors.paperBackground
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
            
            //navigationBar.allowsUnderbarHitsFallThrough = true //tonitodo: need this
            navigationBar.addExtendedNavigationBarView(headerExtendedView)
            
            self.headerExtendedView = headerExtendedView
        }
        
        navigationBar.isBarHidingEnabled = false
        useNavigationBarVisibleHeightForScrollViewInsets = true
    }
    
    func setupDiffListViewControllerIfNeeded() {
        if diffListViewController == nil {
            let diffListViewController = DiffListViewController(theme: theme, delegate: self)
            wmf_add(childController: diffListViewController, andConstrainToEdgesOfContainerView: view, belowSubview: navigationBar)
            //scrollView = diffListViewController.collectionView
            self.diffListViewController = diffListViewController
        }
    }
}

extension DiffContainerViewController: DiffListDelegate {
    func diffListScrollViewDidScroll(_ scrollView: UIScrollView) {
        self.scrollViewDidScroll(scrollView)
        
        switch containerViewModel.headerViewModel.type {
        case .compare(let compareViewModel):
            let newScrollYOffset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
            if compareViewModel.scrollYOffset != newScrollYOffset {
                compareViewModel.scrollYOffset = newScrollYOffset
                headerExtendedView?.update(containerViewModel.headerViewModel)
            }
        default:
            break
        }
    }
    
    func diffListDidTapIndexPath(_ indexPath: IndexPath) {
        if let listViewModel = containerViewModel.listViewModel,
        listViewModel.count > indexPath.item,
        let contextViewModel = listViewModel[indexPath.item] as? DiffListContextViewModel {
            
            contextViewModel.isExpanded.toggle()
            diffListViewController?.update(listViewModel)
        }
    }
}
