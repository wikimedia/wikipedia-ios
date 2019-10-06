
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
        let stubCompareVC = DiffContainerViewController(type: .compare(articleTitle: "Dog", numIntermediateRevisions: 5, numIntermediateEditors: 2, scrollYOffset: 0, beginSquishYOffset: 0), fromModel: revisionModel1, toModel: revisionModel2, theme: theme)
        return stubCompareVC
    }
    
    @objc static func stubSingleContainerViewController(theme: Theme) -> DiffContainerViewController {
        let revisionModel1 = StubRevisionModel(revisionId: 123, summary: "Summary 1", username: "fancypants", timestamp: Date(timeInterval: -(60*60*24*3), since: Date()))
        let revisionModel2 = StubRevisionModel(revisionId: 234, summary: "Summary 2", username: "funtimez2019", timestamp: Date(timeInterval: -(60*60*24*2), since: Date()))
        let stubSingleVC = DiffContainerViewController(type: .single(byteDifference: 6), fromModel: revisionModel1, toModel: revisionModel2, theme: theme)
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
        apply(theme: theme)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard let headerTitleView = headerTitleView else {
            return
        }
        
        switch containerViewModel.type {
        case .compare(_, _, _, _, let existingSquishYOffset):
            
            let newBeginSquishYOffset = headerTitleView.frame.height
            if existingSquishYOffset != newBeginSquishYOffset {
                containerViewModel = generateNewContainerModel(changeScrollYOffset: nil, beginSquishYOffset: newBeginSquishYOffset, changeListViewModel: nil)
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
        let contextViewModel = DiffListContextViewModel(lines: "Line 1-2", isExpanded: false, items: ["Testing here now", ""])
        
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
        view.backgroundColor = theme.colors.paperBackground
    }
    
}

private extension DiffContainerViewController {
    func update(_ containerViewModel: DiffContainerViewModel) {
        
        navigationBar.title = containerViewModel.title
        if let listViewModel = containerViewModel.listViewModel {
            setupDiffListViewControllerIfNeeded()
            diffListViewController?.update(listViewModel)
        } else {
            //TONITODO: show loading state?
            //or container has an empty (no differences), error, and list state. list state has associated value of items, otherwise things change)
        }
        
        setupHeaderViewIfNeeded()
        headerTitleView?.update(containerViewModel.headerViewModel)
        headerExtendedView?.update(containerViewModel.headerViewModel)
        navigationBar.isExtendedViewHidingEnabled = containerViewModel.headerViewModel.isExtendedViewHidingEnabled
        view.setNeedsLayout()
        view.layoutIfNeeded()
        updateScrollViewInsets()
    }
    
    func setupHeaderViewIfNeeded() {
        if self.headerTitleView == nil {
            let headerTitleView = DiffHeaderTitleView(frame: .zero)
            headerTitleView.translatesAutoresizingMaskIntoConstraints = false
            
            navigationBar.isUnderBarViewHidingEnabled = true
            navigationBar.allowsUnderbarHitsFallThrough = true
            navigationBar.addUnderNavigationBarView(headerTitleView)
            navigationBar.underBarViewPercentHiddenForShowingTitle = 0.6
            
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
        case .compareRevision:
            let newScrollYOffset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
            containerViewModel = generateNewContainerModel(changeScrollYOffset: newScrollYOffset, beginSquishYOffset: nil, changeListViewModel: nil)
        default:
            break
        }
    }
    
    func diffListDidTapIndexPath(_ indexPath: IndexPath) {
        if var listViewModel = containerViewModel.listViewModel,
        listViewModel.count > indexPath.item,
            let contextViewModel = listViewModel[indexPath.item] as? DiffListContextViewModel {
            let newModel = DiffListContextViewModel(lines: contextViewModel.lines, isExpanded: !contextViewModel.isExpanded, items: contextViewModel.items)
            listViewModel[indexPath.item] = newModel
            containerViewModel = generateNewContainerModel(changeScrollYOffset: nil, beginSquishYOffset: nil, changeListViewModel: listViewModel)
        }
    }
}

private extension DiffContainerViewController {
    func generateNewContainerModel(changeScrollYOffset: CGFloat?, beginSquishYOffset: CGFloat?, changeListViewModel: [DiffListGroupViewModel]?) -> DiffContainerViewModel {
        
        guard changeScrollYOffset != nil ||
            changeListViewModel != nil ||
            beginSquishYOffset != nil else {
                //change nothing, return current
                return containerViewModel
        }
        
        let newListViewModel: [DiffListGroupViewModel]?
        if let changeListViewModel = changeListViewModel {
            newListViewModel = changeListViewModel
        } else {
            newListViewModel = containerViewModel.listViewModel
        }
        
        switch containerViewModel.headerViewModel.type {
        case .compareRevision(let existingModel):
            
            let newScrollYOffset: CGFloat
            if let changeScrollYOffset = changeScrollYOffset {
                newScrollYOffset = changeScrollYOffset
            } else {
                newScrollYOffset = existingModel.scrollYOffset
            }
            
            let newBeginSquishYOffset: CGFloat
            if let beginSquishYOffset = beginSquishYOffset {
                newBeginSquishYOffset = beginSquishYOffset
            } else {
                newBeginSquishYOffset = existingModel.beginSquishYOffset
            }
            
            switch type {
            case .compare(let existingArticleTitle, let existingNumIntermediateRevisions, let existingNumIntermediateEditors, _, _):
                
                //reset view model
                return DiffContainerViewModel(type: .compare(articleTitle: existingArticleTitle, numIntermediateRevisions: existingNumIntermediateRevisions, numIntermediateEditors: existingNumIntermediateEditors, scrollYOffset: newScrollYOffset, beginSquishYOffset: newBeginSquishYOffset), fromModel: fromModel, toModel: toModel, theme: theme, listViewModel: newListViewModel)
            default:
                break
            }
            
            

        case .singleRevision:
            switch type {
            case .single(let existingByteDifference):
                return DiffContainerViewModel(type: .single(byteDifference: existingByteDifference), fromModel: fromModel, toModel: toModel, theme: theme, listViewModel: newListViewModel)
                default: break
            }
        }
        
        return self.containerViewModel
    }
}
