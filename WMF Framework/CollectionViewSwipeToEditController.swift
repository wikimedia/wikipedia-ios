import Foundation

public enum CollectionViewCellSwipeType {
    case primary, secondary, none
}

enum CollectionViewCellState {
    case idle, open
}

public class CollectionViewSwipeToEditController: NSObject, UIGestureRecognizerDelegate, ActionsViewDelegate {
    
    let collectionView: UICollectionView
    
    var activeCell: ArticleCollectionViewCell? {
        guard let indexPath = activeIndexPath else {
            return nil
        }
        return collectionView.cellForItem(at: indexPath) as? ArticleCollectionViewCell
    }
    
    var activeIndexPath: IndexPath?
    var initialSwipeTranslation: CGFloat = 0
    var activeDirectionIsPrimary: Bool?
    
    public var primaryActions: [CollectionViewCellAction] = []
    public var secondaryActions: [CollectionViewCellAction] = []
    
    
    public init(collectionView: UICollectionView) {
        self.collectionView = collectionView
        super.init()
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture))


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
        longPress.minimumPressDuration = 0.05
        self.collectionView.addGestureRecognizer(longPress)
        
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let pan = gestureRecognizer as? UIPanGestureRecognizer {
            return panGestureRecognizerShouldBegin(pan)
        }
        
        if let longPress = gestureRecognizer as? UILongPressGestureRecognizer {
            return longPressGestureRecognizerShouldBegin(longPress)
        }
        
        return false
    }
    
    public weak var delegate: CollectionViewSwipeToEditDelegate?
    
    public func didPerformAction(_ action: CollectionViewCellAction) {
        guard let indexPath = activeIndexPath else {
            return
        }
        delegate?.didPerformAction(action, at: indexPath)
    }
    
    func panGestureRecognizerShouldBegin(_ gestureRecognizer: UIPanGestureRecognizer) -> Bool {
        guard let delegate = delegate else {
            return false
        }
        
        let position = gestureRecognizer.location(in: collectionView)
        
        guard let indexPath = collectionView.indexPathForItem(at: position) else {
                return false
        }

        let velocity = gestureRecognizer.velocity(in: collectionView)
        
        // Begin only if there's enough x velocity.
        if fabs(velocity.y) >= fabs(velocity.x) {
            return false
        }
        
        defer {
            initialSwipeTranslation = activeCell?.swipeTranslation ?? 0
        }
        
        let isPrimary = velocity.x < 0
        
        if indexPath == activeIndexPath && isPrimary != activeDirectionIsPrimary {
            return true
        }
        
        if activeIndexPath != nil && activeIndexPath != indexPath {
            return false
        }
        
        guard activeIndexPath == nil else {
            return true
        }
        
        let primaryActions = delegate.primaryActions(for: indexPath)
        let secondaryActions = delegate.secondaryActions(for: indexPath)
        
        let actions = isPrimary ? primaryActions : secondaryActions
        
        guard actions.count > 0 else {
            return false
        }
        
        activeIndexPath = indexPath
        activeCell?.actionsView.actions = primaryActions
        
        return true
    }
    
    func longPressGestureRecognizerShouldBegin(_ gestureRecognizer: UILongPressGestureRecognizer) -> Bool {
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
        
        if gestureRecognizer is UILongPressGestureRecognizer {
            return true
        }
        
        if gestureRecognizer is UIPanGestureRecognizer{
            return otherGestureRecognizer is UILongPressGestureRecognizer
        }
        
        return false
    }
    
    @objc func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        guard let cell = activeCell else {
            return
        }
        cell.actionsView.delegate = self
        let deltaX = sender.translation(in: collectionView).x
        let velocityX = sender.velocity(in: collectionView).x
        var swipeTranslation = deltaX + initialSwipeTranslation
        switch (sender.state) {
        case .began:
            cell.isSwiping = true
            fallthrough
        case .changed:
            if swipeTranslation > 0 {
                swipeTranslation = sqrt(swipeTranslation)
            }
            if abs(swipeTranslation) > abs(cell.actionsView.maximumWidth) {
                swipeTranslation = 0 - cell.actionsView.maximumWidth - sqrt(abs(swipeTranslation) - abs(cell.actionsView.maximumWidth))
            }
            cell.swipeVelocity = velocityX
            cell.swipeTranslation = swipeTranslation
        case .cancelled:
            fallthrough
        case .failed:
            fallthrough
        case .ended:
            if -swipeTranslation > 0.5 * cell.actionsView.maximumWidth {
                cell.openActionPane()
            } else {
                cell.closeActionPane()
                activeIndexPath = nil
            }
            fallthrough
        default:
            break
        }
    }
    
    @objc func handleLongPressGesture(_ sender: UILongPressGestureRecognizer) {
        guard activeCell != nil else {
            return
        }
        
        switch (sender.state) {
        case .ended:
            sender.isEnabled = false
            sender.isEnabled = true
        default:
            break
        }
    }
    
    // MARK: - States
    func didEnterIdleState() {
        collectionView.isScrollEnabled = true
        guard let cell = activeCell else {
            return
        }
        cell.closeActionPane()
        activeIndexPath = nil
        activeDirectionIsPrimary = nil
    }
    
    func didEnterOpenState() {
        collectionView.isScrollEnabled = false
        guard let cell = activeCell else {
            return
        }
        cell.openActionPane()
    }
    
    public func performedAction() {
        closeActionPane()
    }
    
    func closeActionPane() {

    }
    
}
