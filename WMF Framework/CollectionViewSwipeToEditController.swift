import Foundation

public enum CollectionViewCellSwipeType {
    case primary, secondary, none
}

enum CollectionViewCellState {
    case idle, open
}

public class CollectionViewSwipeToEditController: NSObject, UIGestureRecognizerDelegate, ActionsViewDelegate {
    
    let collectionView: UICollectionView
    
    var currentState: CollectionViewCellState = .idle {
        didSet {
            currentState == .idle ? didEnterIdleState() : didEnterOpenState()
        }
    }
    
    var activeCell: ArticleCollectionViewCell?
    var activeIndexPath: IndexPath?
    
    public var primaryActions: [CollectionViewCellAction] = []
    public var secondaryActions: [CollectionViewCellAction] = []
    
    fileprivate var theme: Theme = Theme.standard
    
    public init(collectionView: UICollectionView, theme: Theme) {
        self.collectionView = collectionView
        self.theme = theme
        super.init()
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        let longPress = UITapGestureRecognizer(target: self, action: #selector(handleLongPressGesture))

        if let gestureRecognizers = self.collectionView.gestureRecognizers {
            var otherGestureRecognizer: UIGestureRecognizer
            for gestureRecognizer in gestureRecognizers {
                otherGestureRecognizer = gestureRecognizer is UIPanGestureRecognizer ? pan : longPress
                gestureRecognizer.require(toFail: otherGestureRecognizer)
            }

        }
        
        pan.delegate = self
        self.collectionView.addGestureRecognizer(pan)
        
        longPress.delegate = self
        self.collectionView.addGestureRecognizer(longPress)
        
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if let pan = gestureRecognizer as? UIPanGestureRecognizer {
            return panGestureRecognizerShouldBegin(pan)
        }
        
        if let longPress = gestureRecognizer as? UITapGestureRecognizer {
            return longPressGestureRecognizerShouldBegin(longPress)
        }
        
        return false
    }
    
    public weak var delegate: CollectionViewSwipeToEditDelegate?
    
    public func didPerformAction(_ action: CollectionViewCellAction) {
        guard let indexPath = activeIndexPath else { return }
        delegate?.didPerformAction(action, at: indexPath)
    }
    
    func panGestureRecognizerShouldBegin(_ gestureRecognizer: UIPanGestureRecognizer) -> Bool {
        guard activeIndexPath == nil, let delegate = delegate else {
            return false
            
        }
        
        let position = gestureRecognizer.location(in: collectionView)
        
        guard let indexPath = collectionView.indexPathForItem(at: position),
            let cell = collectionView.cellForItem(at: indexPath) as? ArticleCollectionViewCell  else {
                return false
        }
        
        activeCell = cell
        activeIndexPath = indexPath
        
        let velocity = gestureRecognizer.velocity(in: collectionView)
        
        // Begin only if there's enough x velocity.
        if fabs(velocity.y) >= fabs(velocity.x) {
            return false
        }
        
        let primaryActions = delegate.primaryActions(for: indexPath)
        let secondaryActions = delegate.secondaryActions(for: indexPath)
        
        cell.actions = velocity.x < 0 ? primaryActions : secondaryActions
        cell.actionsView?.delegate = self
        
        guard cell.actions.count > 0 else {
            return false
        }
        
        cell.swipeType = velocity.x < 0 ? .primary : .secondary
        activeCell = cell
        
        return true
    }
    
    func longPressGestureRecognizerShouldBegin(_ gestureRecognizer: UITapGestureRecognizer) -> Bool {
        guard let cell = activeCell else {
            return false
        }
        
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
        
        if gestureRecognizer is UITapGestureRecognizer {
            return true
        }
        
        if gestureRecognizer is UIPanGestureRecognizer {
            return otherGestureRecognizer is UITapGestureRecognizer
        }
        
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
    
    @objc func handleLongPressGesture(_ sender: UITapGestureRecognizer) {
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
        guard let cell = activeCell else { return }
        cell.closeActionPane()
        activeCell = nil
        activeIndexPath = nil
    }
    
    func didEnterOpenState() {
        collectionView.isScrollEnabled = false
        guard let cell = activeCell else { return }
        cell.theme = theme
        cell.openActionPane()
        
    }
    
    public func performedAction() {
        closeActionPane()
    }
    
    func closeActionPane() {
        currentState = .idle
    }
    
}
