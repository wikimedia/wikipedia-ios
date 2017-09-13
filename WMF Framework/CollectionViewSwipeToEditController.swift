import Foundation

public enum CollectionViewCellSwipeType {
    case primary, secondary, none
}

enum CollectionViewCellState {
    case idle, open
}

public class CollectionViewSwipeToEditController: NSObject, UIGestureRecognizerDelegate, ActionsViewDelegate {
    
    let collectionView: UICollectionView
    let pan = UIPanGestureRecognizer()
    let longPress = UILongPressGestureRecognizer()
    
    var currentState: CollectionViewCellState = .idle {
        didSet {
            currentState == .idle ? didEnterIdleState() : didEnterOpenState()
        }
    }
    
    var activeCell: ArticleCollectionViewCell?
    var activeIndexPath: IndexPath?
    
    public var cellWithActionPaneOpen: ArticleCollectionViewCell?
    
    public var primaryActions: [CollectionViewCellAction] = []
    public var secondaryActions: [CollectionViewCellAction] = []
    
    fileprivate var theme: Theme = Theme.standard
    
    public init(collectionView: UICollectionView, theme: Theme) {
        self.collectionView = collectionView
        self.theme = theme
        super.init()
        
        if let gestureRecognizers = self.collectionView.gestureRecognizers {
            var otherGestureRecognizer: UIGestureRecognizer
            for gestureRecognizer in gestureRecognizers {
                otherGestureRecognizer = gestureRecognizer is UIPanGestureRecognizer ? pan : longPress
                gestureRecognizer.require(toFail: otherGestureRecognizer)
            }
            
        }
        
        addPanGesture(to: self.collectionView)
        addLongPressGesture(to: self.collectionView)
    }
    
    func addPanGesture(to collectionView: UICollectionView) {
        pan.addTarget(self, action: #selector(handlePanGesture))
        pan.delegate = self
        collectionView.addGestureRecognizer(pan)
    }
    
    func addLongPressGesture(to collectionView: UICollectionView) {
        longPress.addTarget(self, action: #selector(handleLongPressGesture))
        longPress.delegate = self
        longPress.minimumPressDuration = 0.05
        collectionView.addGestureRecognizer(longPress)
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        let position = pan.location(in: collectionView)
        
        guard let indexPath = collectionView.indexPathForItem(at: position),
            let cell = collectionView.cellForItem(at: indexPath) as? ArticleCollectionViewCell  else {
            return false
        }
        
        activeCell = cell
        activeIndexPath = indexPath
        
        return gestureRecognizer is UIPanGestureRecognizer ? panGestureRecognizerShouldBegin(gestureRecognizer, in: cell, at: indexPath) : longPressGestureRecognizerShouldBegin(gestureRecognizer, in: cell, at: indexPath)
    }
    
    public var isActionPanOpenInCollectionView = false
    
    public weak var delegate: CollectionViewSwipeToEditDelegate?
    
    public func didPerformAction(_ action: CollectionViewCellAction) {
        guard let indexPath = activeIndexPath else { return }
        delegate?.didPerformAction(action, at: indexPath)
    }
    
    func panGestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer, in cell: ArticleCollectionViewCell, at indexPath: IndexPath) -> Bool {
        
        guard !isActionPanOpenInCollectionView, let delegate = delegate else { return false }
        
        let velocity = pan.velocity(in: collectionView)
        
        // Begin only if there's enough x velocity.
        if fabs(velocity.y) >= fabs(velocity.x) {
            return false
        }
        
        let primaryActions = delegate.primaryActions(for: indexPath)
        let secondaryActions = delegate.secondaryActions(for: indexPath)
        
        cell.actions = velocity.x < 0 ? primaryActions : secondaryActions
        cell.actionsView?.delegate = self
        
        guard cell.actions.count > 0 else { return false }
        
        cell.swipeType = velocity.x < 0 ? .primary : .secondary
        activeCell = cell
        
        return true
    }
    
    func longPressGestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer, in cell: ArticleCollectionViewCell, at indexPath: IndexPath) -> Bool {
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
