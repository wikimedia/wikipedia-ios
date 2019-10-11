
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
        let item1 = DiffListChangeItemViewModel(text: "The fleet under her command established hegemony over many coastal villages, in some cases even imposing levies, and taxes on settlements. According to Robert Antony, In his authoritative text on female Pirates, Robert Antony states that Ching Shih ''\"robbed towns, markets, and villages, from Macau to Canton.\"''<ref>{{cite book |last=Antony |first=Robert |title=Like Froth Floating on the Sea: The world of pirates and seafarers in Late Imperial South China |location=Berkeley |publisher=University of California Press |year=2003 |isbn=978-1-55729-078-6}}</ref> In one coastal village, the Sanshan village, they beheaded 80 men and abducted their women and children and held them for ransom until they were sold in slavery.<ref name=\":0\">{{Cite web|url=http://www.cindyvallar.com/chengsao.html |title=Pirates & Privateers: The History of Maritime Piracy - Cheng I Sao |last=Vallar |first=Cindy| website= www.cindyvallar.com |access-date=2018-03-03}}</ref>", highlightedRanges: [range1, range2], traitCollection: traitCollection, theme: theme, type: .compareRevision)
        let item2 = DiffListChangeItemViewModel(text: "Here is another line of text to test multi-line changes.", highlightedRanges: [range1, range2], traitCollection: traitCollection, theme: theme, type: .compareRevision)
        
        let changeCompareViewModel = DiffListChangeViewModel(type: .compareRevision, heading: "Line 1", items: [item1, item2], theme: theme, width: 0, sizeClass: (traitCollection.horizontalSizeClass, traitCollection.verticalSizeClass), traitCollection: traitCollection)
        //let changeSingleViewModel = DiffListChangeViewModel(type: .compareRevision, heading: "Pirates", items: [item1, item2], theme: theme, width: 0, sizeClass: (traitCollection.horizontalSizeClass, traitCollection.verticalSizeClass), traitCollection: traitCollection)
        let contextViewModel = DiffListContextViewModel(heading: "Lines 150-151", isExpanded: false, items: [nil, "In 1999, a study of [[mitochondrial DNA]] indicated that the domestic dog may have originated from multiple grey [[wolf]] populations, with the [[dingo]] and [[New Guinea singing dog]] \"breeds\" having developed at a time when human populations were more isolated from each other.<ref name=wayne1999/> In the third edition of ''[[Mammal Species of the World]]'' published in 2005, the mammalogist [[:de:W. Christopher Wozencraft|W. Christopher Wozencraft]] listed under the wolf ''Canis lupus'' its wild subspecies, and proposed two additional subspecies: \"''familiaris'' Linneaus, 1758 [domestic dog]\" and \"''dingo'' Meyer, 1793 [domestic dog]\". Wozencraft included ''hallstromi'' - the New Guinea singing dog - as a [[taxonomic synonym]] for the dingo. Wozencraft referred to the mDNA study as one of the guides in forming his decision.<ref name=wozencraft2005/> The inclusion of ''familiaris'' under a \"domestic dog\" clade has been noted by other mammalogists.<ref name=jackson2017/> This classification by Wozencraft is debated among zoologists.<ref name=smithC1/>"], theme: theme, width: 0, sizeClass: (traitCollection.horizontalSizeClass, traitCollection.verticalSizeClass), traitCollection: traitCollection)
        
        let uneditedViewModel = DiffListUneditedViewModel(numberOfUneditedLines: 100, theme: theme, width: 0, sizeClass: (traitCollection.horizontalSizeClass, traitCollection.verticalSizeClass), traitCollection: traitCollection)
        self.containerViewModel = DiffContainerViewModel(type: type, fromModel: fromModel, toModel: toModel, theme: theme, listViewModel: [contextViewModel, uneditedViewModel, changeCompareViewModel])
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
        
        diffListViewController?.apply(theme: theme)
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)

        updateListViewModels(newSizeClass: (newCollection.horizontalSizeClass, newCollection.verticalSizeClass), newWidth: nil, newTraitCollection: nil,indexPathToToggleExpand: nil)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateListViewModels(newSizeClass: nil, newWidth: nil, newTraitCollection: traitCollection, indexPathToToggleExpand: nil)
    }
    
}

private extension DiffContainerViewController {
    
    func updateListViewModels(newSizeClass: (horizontal: UIUserInterfaceSizeClass, vertical: UIUserInterfaceSizeClass)?, newWidth: CGFloat?, newTraitCollection: UITraitCollection?, indexPathToToggleExpand: IndexPath?) {
        
        guard newSizeClass != nil ||
            newWidth != nil ||
            newTraitCollection != nil ||
            indexPathToToggleExpand != nil else {
                return
        }
        
        guard let listViewModel = containerViewModel.listViewModel else {
            return
        }
        
        var needsUpdate = false
        var needsOnlyLayoutUpdate = false
        for var item in listViewModel {
            if let newSizeClass = newSizeClass {
                if item.sizeClass != newSizeClass {
                    item.sizeClass = newSizeClass
                    needsUpdate = true
                }
            }
            
            if let newWidth = newWidth {
                if item.width != newWidth {
                    item.width = newWidth
                    needsUpdate = true
                }
            }
            
            if let newTraitCollection = newTraitCollection {
                
                if item.traitCollection != newTraitCollection {
                    item.traitCollection = newTraitCollection
                    needsUpdate = true
                }
            }
        }
        
        if let indexPathToToggleExpand = indexPathToToggleExpand,
            let item = listViewModel[safeIndex: indexPathToToggleExpand.item] as? DiffListContextViewModel {
            item.isExpanded.toggle()
            
            if !needsUpdate {
                needsOnlyLayoutUpdate = true
            }
        }
        
        if needsUpdate || needsOnlyLayoutUpdate {
            diffListViewController?.update(listViewModel, needsOnlyLayoutUpdate: needsOnlyLayoutUpdate, indexPath: indexPathToToggleExpand)
        }
    }
    
    func update(_ containerViewModel: DiffContainerViewModel) {
        
        navigationBar.title = containerViewModel.navBarTitle
        if let listViewModel = containerViewModel.listViewModel {
            setupDiffListViewControllerIfNeeded()
            diffListViewController?.update(listViewModel, indexPath: nil)
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
    
    func diffListUpdateWidth(newWidth: CGFloat) {
        
        updateListViewModels(newSizeClass: nil, newWidth: newWidth, newTraitCollection: nil, indexPathToToggleExpand: nil)
    }
    
    func diffListDidTapContextExpand(indexPath: IndexPath) {
        updateListViewModels(newSizeClass: nil, newWidth: nil, newTraitCollection: nil, indexPathToToggleExpand: indexPath)
    }
}
