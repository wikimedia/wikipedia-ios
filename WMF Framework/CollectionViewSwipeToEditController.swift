import Foundation

public enum CollectionViewCellSwipeType {
    case primary, secondary, none
}

enum CollectionViewCellState {
    case idle, open
}

public class CollectionViewSwipeToEditController: NSObject, UIGestureRecognizerDelegate {
    let collectionView: UICollectionView
    let panGesture = UIPanGestureRecognizer()
    let longPressGesture = UILongPressGestureRecognizer()
    
    var currentState: CollectionViewCellState = .idle {
        didSet {
            currentState == .idle ? didEnterIdleState() : didEnterOpenState()
        }
    }
    
    var activeCell: ArticleCollectionViewCell? {
        get {
            let position = panGesture.location(in: collectionView)
            let panCellPath = collectionView.indexPathForItem(at: position)
            if let path = panCellPath, let cell = collectionView.cellForItem(at: path) as? ArticleCollectionViewCell {
                return cell
            }
            return nil
        }
        set {
            
        }
    }
    
    public var cellWithActionPaneOpen: ArticleCollectionViewCell?
    
    public var primaryActions: [CollectionViewCellAction] = []
    public var secondaryActions: [CollectionViewCellAction] = []
    
    fileprivate var theme: Theme = Theme.standard
    
    public init(collectionView: UICollectionView, theme: Theme) {
        self.collectionView = collectionView
        self.theme = theme
        super.init()
        
        if let gestureRecognizers = self.collectionView.gestureRecognizers {
            for gestureRecognizer in gestureRecognizers {
                if gestureRecognizer is UIPanGestureRecognizer {
                    gestureRecognizer.require(toFail: panGesture)
                }
                if gestureRecognizer is UILongPressGestureRecognizer {
                    gestureRecognizer.require(toFail: longPressGesture)
                }
            }
        }
        
        addPanGesture(to: self.collectionView)
        addLongPressGesture(to: self.collectionView)
    }
    
    func addPanGesture(to collectionView: UICollectionView) {
        panGesture.addTarget(self, action: #selector(handlePanGesture))
        panGesture.delegate = self
        collectionView.addGestureRecognizer(panGesture)
    }
    
    func addLongPressGesture(to collectionView: UICollectionView) {
        longPressGesture.addTarget(self, action: #selector(handleLongPressGesture))
        longPressGesture.delegate = self
        longPressGesture.minimumPressDuration = 0.05
        collectionView.addGestureRecognizer(longPressGesture)
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let cell = activeCell else { return false }
        
        return gestureRecognizer is UIPanGestureRecognizer ? panGestureRecognizerShouldBegin(gestureRecognizer, in: cell) : longPressGestureRecognizerShouldBegin(gestureRecognizer, in: cell)
    }
    
    public var isActionPanOpenInCollectionView = false
    
    var activeCellIndexPath: IndexPath? {
        if let cell = activeCell {
            return collectionView.indexPath(for: cell)
        }
        return nil
    }
    
    func panGestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer, in cell: ArticleCollectionViewCell) -> Bool {
        
        guard !isActionPanOpenInCollectionView else { return false }
        
        let velocity = panGesture.velocity(in: collectionView)
        
        // Begin only if there's enough x velocity.
        if fabs(velocity.y) >= fabs(velocity.x) {
            return false
        }
        
        // If the article was saved, swap the "Save" action for "Unsave" and vice versa.
        swapSaveActionsIfNecessary(cell.isSaved)
        
        cell.actions = velocity.x < 0 ? primaryActions : secondaryActions
        
        guard cell.actions.count > 0 else { return false }
        
        cell.swipeType = velocity.x < 0 ? .primary : .secondary
        activeCell = cell
        
        return true
    }
    
    func swapSaveActionsIfNecessary(_ saved: Bool) {
        let unsave = CollectionViewCellActionType.unsave.action
        let save = CollectionViewCellActionType.save.action
        
        if saved {
            guard primaryActions.contains(save) else { return }
            
            for (index, action) in primaryActions.enumerated() {
                if action.type == .save {
                    primaryActions.remove(at: index)
                    primaryActions.insert(unsave, at: index)
                }
            }
            
        } else {
            guard primaryActions.contains(unsave) else { return }
            
            for (index, action) in primaryActions.enumerated() {
                if action.type == .unsave {
                    primaryActions.remove(at: index)
                    primaryActions.insert(save, at: index)
                }
            }
        }
    }
    
    func longPressGestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer, in cell: ArticleCollectionViewCell) -> Bool {
        guard isActionPanOpenInCollectionView else { return false }
        
        // Don't allow the cancel gesture to recognize if any of the touches are within the actions view.
        let numberOfTouches = gestureRecognizer.numberOfTouches
        
        for touchIndex in 0..<numberOfTouches {
            let touchLocation = gestureRecognizer.location(ofTouch: touchIndex, in: cell)
            let touchedActionsView = cell.actionsViewRect.contains(touchLocation)
            return !touchedActionsView
        }
        
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if gestureRecognizer is UILongPressGestureRecognizer { return otherGestureRecognizer is UIPanGestureRecognizer }
        
        if gestureRecognizer is UIPanGestureRecognizer { return otherGestureRecognizer is UILongPressGestureRecognizer }
        
        return false
    }
    
    @objc func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        guard let cell = activeCell else { return }
        
        switch (sender.state) {
        case .began:
            let position = sender.location(in: cell)
            let velocityX = sender.velocity(in: cell).x
            cell.beginSwipe(with: position, velocity: velocityX)
            currentState = .open
        case .changed:
            let position = sender.location(in: cell)
            let velocityX = sender.velocity(in: cell).x
            cell.updateSwipe(with: position, velocity: velocityX)
        case .cancelled:
            currentState = .idle
        default:
            break
        }
    }
    
    @objc func handleLongPressGesture(_ sender: UILongPressGestureRecognizer) {
        guard let cell = activeCell else { return }
        
        switch (sender.state) {
        case .began:
            let location = sender.location(in: cell)
            if cell.bounds.contains(location) { break }
            currentState = .idle
            sender.isEnabled = false
            sender.isEnabled = true
        case .cancelled:
            currentState = .idle
        case .ended:
            currentState = .idle
        default:
            break
        }
    }
    
    // MARK: - States
    func didEnterIdleState() {
        collectionView.isScrollEnabled = true
        if let cell = activeCell, let cellOpen = cellWithActionPaneOpen {
            // Make sure that we're always closing the currently open cell, regardless of where the tap occurs.
            if cell != cellOpen {
                cellWithActionPaneOpen = nil
                cellOpen.closeActionPane()
            }
            activeCell = nil
            cell.closeActionPane()
        }
    }
    
    func didEnterOpenState() {
        collectionView.isScrollEnabled = false
        if let cell = activeCell {
            cell.theme = theme
            cell.openActionPane()
        }
    }
    
    public func performedAction() {
        closeActionPane()
    }
    
    func closeActionPane() {
        currentState = .idle
    }
    
}
