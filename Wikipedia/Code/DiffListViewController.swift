
import UIKit

protocol DiffListDelegate: class {
    func diffListScrollViewDidScroll(_ scrollView: UIScrollView)
}

class DiffListViewController: ViewController {
    
    enum ListUpdateType {
        case itemExpandUpdate(indexPath: IndexPath) //tapped context cell to expand
        case layoutUpdate(collectionViewWidth: CGFloat, traitCollection: UITraitCollection) //willTransitionToSize - simple rotation that keeps size class
        case initialLoad(width: CGFloat)
        case theme(theme: Theme)
    }

    lazy private(set) var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layoutCopy)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.alwaysBounceVertical = true
        scrollView = collectionView
        return collectionView
    }()
    
    var layoutCopy: UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 20
        switch type {
        case .single:
            layout.sectionInset = UIEdgeInsets(top: 15, left: 0, bottom: 10, right: 0)
        case .compare:
            layout.sectionInset = UIEdgeInsets(top: 25, left: 0, bottom: 10, right: 0)
        }
        
        return layout
    }
    
    private var dataSource: [DiffListGroupViewModel] = []
    private weak var delegate: DiffListDelegate?
    private let type: DiffContainerViewModel.DiffType

    private var updateWidthsOnLayoutSubviews = false
    private var isRotating = false
    
    private var centerIndexPath: IndexPath? {
        let center = view.convert(collectionView.center, to: collectionView)
        return collectionView.indexPathForItem(at: center)
    }
    private var indexPathBeforeRotating: IndexPath?
    private let chunkedHeightCalculationsConcurrentQueue = DispatchQueue(label: "org.wikipedia.diff.chunkedHeightCalculations", qos: .userInteractive, attributes: .concurrent)
    private let layoutSubviewsHeightCalculationsSerialQueue = DispatchQueue(label: "org.wikipedia.diff.layoutHeightCalculations", qos: .userInteractive)
    
    private var scrollDidFinishInfo: (indexPathToScrollTo: IndexPath, changeItemToScrollTo: Int)?
    
    init(theme: Theme, delegate: DiffListDelegate?, type: DiffContainerViewModel.DiffType) {
        self.type = type
        super.init(nibName: nil, bundle: nil)
        self.theme = theme
        self.delegate = delegate
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraints([
            view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor),
            view.topAnchor.constraint(equalTo: collectionView.topAnchor),
            view.bottomAnchor.constraint(equalTo: collectionView.bottomAnchor)
        ])
        collectionView.register(DiffListChangeCell.wmf_classNib(), forCellWithReuseIdentifier: DiffListChangeCell.reuseIdentifier)
        collectionView.register(DiffListContextCell.wmf_classNib(), forCellWithReuseIdentifier: DiffListContextCell.reuseIdentifier)
        collectionView.register(DiffListUneditedCell.wmf_classNib(), forCellWithReuseIdentifier: DiffListUneditedCell.reuseIdentifier)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if updateWidthsOnLayoutSubviews {
            
            //More improvements could be size caching & putting layoutSubviewsHeightCalculationsSerialQueue instead into an NSOperation to be cancelled if another viewDidLayoutSubviews is called.
            //tonitodo: clean up - move this and updateListViewModel methods into separate class, DiffListSizeCalculator or something
            let updateType = ListUpdateType.layoutUpdate(collectionViewWidth: self.collectionView.frame.width, traitCollection: self.traitCollection)
            
            //actually not sure if this serial queue is needed or simply calling on the main thread (also serial) is the same. this also seems faster than without though.
            layoutSubviewsHeightCalculationsSerialQueue.async {
                
                self.backgroundUpdateListViewModels(listViewModel: self.dataSource, updateType: updateType) {
                    
                    DispatchQueue.main.async {
                        self.applyListViewModelChanges(updateType: updateType)
                        
                        if let indexPathBeforeRotating = self.indexPathBeforeRotating {
                            self.collectionView.scrollToItem(at: indexPathBeforeRotating, at: .centeredVertically, animated: false)
                            self.indexPathBeforeRotating = nil
                        }
                        
                        self.updateScrollViewInsets()
                    }
                    
                }
            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        updateWidthsOnLayoutSubviews = true
        isRotating = true
        
        self.indexPathBeforeRotating = centerIndexPath
        coordinator.animate(alongsideTransition: { (context) in
            
            //nothing
            
        }) { (context) in
            self.updateWidthsOnLayoutSubviews = false
            self.isRotating = false
        }

    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        
        updateWidthsOnLayoutSubviews = true
        coordinator.animate(alongsideTransition: { (context) in
        }) { (context) in
            self.updateWidthsOnLayoutSubviews = false
        }
        
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        delegate?.diffListScrollViewDidScroll(scrollView)
    }
    
    override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        super.scrollViewDidEndScrollingAnimation(scrollView)
        
        if let scrollDidFinishInfo = scrollDidFinishInfo {
            scrollToChangeItem(cellIndexPath: scrollDidFinishInfo.indexPathToScrollTo, itemIndex: scrollDidFinishInfo.changeItemToScrollTo)
            self.scrollDidFinishInfo = nil
        }
    }
    
    func updateListViewModels(listViewModel: [DiffListGroupViewModel], updateType: DiffListViewController.ListUpdateType) {
        
        switch updateType {
        case .itemExpandUpdate(let indexPath):
            
            if let item = listViewModel[safeIndex: indexPath.item] as? DiffListContextViewModel {
                item.isExpanded.toggle()
            }
            
        case .layoutUpdate(let width, let traitCollection):
            for item in listViewModel {
                if item.width != width || item.traitCollection != traitCollection {
                    item.updateSize(width: width, traitCollection: traitCollection)
                }
            }
        
        case .initialLoad(let width):
            for var item in listViewModel {
                if item.width != width {
                    item.width = width
                }
            }
            self.dataSource = listViewModel
        case .theme(let theme):
            for var item in listViewModel {
                if item.theme != theme {
                    item.theme = theme
                }
            }
        }
    }
    
    override func apply(theme: Theme) {
        
        super.apply(theme: theme)
        
        guard isViewLoaded else {
            return
        }
        
        updateListViewModels(listViewModel: dataSource, updateType: .theme(theme: theme))
        applyListViewModelChanges(updateType: .theme(theme: theme))

        collectionView.backgroundColor = theme.colors.paperBackground
    }
    
    func applyListViewModelChanges(updateType: DiffListViewController.ListUpdateType) {
        switch updateType {
        case .itemExpandUpdate:
            
            collectionView.setCollectionViewLayout(layoutCopy, animated: true)

        default:
            collectionView.reloadData()
        }
    }
}

private extension DiffListViewController {
    
    func backgroundUpdateListViewModels(listViewModel: [DiffListGroupViewModel], updateType: DiffListViewController.ListUpdateType, completion: @escaping () -> Void) {

       let group = DispatchGroup()

       let chunked = listViewModel.chunked(into: 10)

       for chunk in chunked {
           chunkedHeightCalculationsConcurrentQueue.async(group: group) {
               
               self.updateListViewModels(listViewModel: chunk, updateType: updateType)
           }
       }

       group.notify(queue: layoutSubviewsHeightCalculationsSerialQueue) {
           completion()
       }
   }
   
   func scrollToChangeItem(cellIndexPath: IndexPath, itemIndex: Int) {
       if let cell = collectionView.cellForItem(at: cellIndexPath) as? DiffListChangeCell,
           let offsetToView = cell.yLocationOfItem(index: itemIndex, convertView: view) {
           
           let midPointTarget = collectionView.frame.height / 2
           let delta = midPointTarget - offsetToView
           collectionView.setContentOffset(CGPoint(x: collectionView.contentOffset.x, y: collectionView.contentOffset.y - delta), animated: true)
       }
    }
}

extension DiffListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let viewModel = dataSource[safeIndex: indexPath.item] else {
            return UICollectionViewCell()
        }
        
        if let viewModel = viewModel as? DiffListChangeViewModel,
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DiffListChangeCell.reuseIdentifier, for: indexPath) as? DiffListChangeCell {
            cell.update(viewModel)
            cell.delegate = self
            return cell
        } else if let viewModel = viewModel as? DiffListContextViewModel,
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DiffListContextCell.reuseIdentifier, for: indexPath) as? DiffListContextCell {
            cell.update(viewModel, indexPath: indexPath)
            cell.delegate = self
            return cell
        } else if let viewModel = viewModel as? DiffListUneditedViewModel,
           let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DiffListUneditedCell.reuseIdentifier, for: indexPath) as? DiffListUneditedCell {
           cell.update(viewModel)
           return cell
        }
        
        return UICollectionViewCell()
    }
}

extension DiffListViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        guard let viewModel = dataSource[safeIndex: indexPath.item] else {
            return .zero
        }
        
        if let contextViewModel = viewModel as? DiffListContextViewModel {
            let height = contextViewModel.isExpanded ? contextViewModel.expandedHeight : contextViewModel.height
            return CGSize(width: min(collectionView.frame.width, contextViewModel.width), height: height)
        }
        
        return CGSize(width: min(collectionView.frame.width, viewModel.width), height: viewModel.height)

    }
    
    func collectionView(_ collectionView: UICollectionView, targetContentOffsetForProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        
        if !isRotating {
            //prevents jumping when expanding/collapsing context cell
            return collectionView.contentOffset
        } else {
            return proposedContentOffset
        }
        
    }
}

extension DiffListViewController: DiffListContextCellDelegate {
    func didTapContextExpand(indexPath: IndexPath) {
        
        updateListViewModels(listViewModel: dataSource, updateType: .itemExpandUpdate(indexPath: indexPath))
        applyListViewModelChanges(updateType: .itemExpandUpdate(indexPath: indexPath))
        
        if let contextViewModel = dataSource[safeIndex: indexPath.item] as? DiffListContextViewModel,
        let cell = collectionView.cellForItem(at: indexPath) as? DiffListContextCell {
            cell.update(contextViewModel, indexPath: indexPath)
        }
    }
}

extension DiffListViewController: DiffListChangeCellDelegate {
    func didTapItem(item: DiffListChangeItemViewModel) {
        
        guard let tappedMoveInfo = item.moveInfo else {
            return
        }
        
        let tappedLinkId = tappedMoveInfo.linkId
        let moveDirection = tappedMoveInfo.linkDirection
        
        var indexOfOtherMoveCell: Int?
        var changeItemToScrollTo: Int?
        for (index, viewModel) in dataSource.enumerated() {
            if let changeViewModel = viewModel as? DiffListChangeViewModel {
                for (subindex, item) in changeViewModel.items.enumerated() {
                    if let moveInfo = item.moveInfo,
                        moveInfo.id == tappedLinkId {
                        indexOfOtherMoveCell = index
                        changeItemToScrollTo = subindex
                    }
                }
            }
        }
        
        if let indexOfOtherMoveCell = indexOfOtherMoveCell,
            let changeItemToScrollTo = changeItemToScrollTo {

            let indexPathOfOtherMoveCell = IndexPath(item: indexOfOtherMoveCell, section: 0)
            let visibleIndexPaths = collectionView.indexPathsForVisibleItems
            
            if visibleIndexPaths.contains(indexPathOfOtherMoveCell) { //cell already configured, skip straight to detecting offset needed to get top of *item* on screen.
                
                scrollToChangeItem(cellIndexPath: indexPathOfOtherMoveCell, itemIndex: changeItemToScrollTo)
            } else {
                
                //avoids weird bouncing when scrolling up if we choose the index path below
                let indexAfterIndexOfOtherMoveCell = indexOfOtherMoveCell + 1
                let indexToScrollTo = moveDirection == .down ? indexOfOtherMoveCell : ((dataSource.count) > indexAfterIndexOfOtherMoveCell) ? indexAfterIndexOfOtherMoveCell : indexOfOtherMoveCell
                let indexPathToScrollTo = IndexPath(item: indexToScrollTo, section: 0)
                
                //first scroll to cell, scrollViewDidEndAnimation will then scroll to item
                scrollDidFinishInfo = (indexPathOfOtherMoveCell, changeItemToScrollTo)
                collectionView.scrollToItem(at: indexPathToScrollTo, at: UICollectionView.ScrollPosition.top, animated: true)
            }
        }
    }
    
    
}
