import Foundation

public enum CollectionViewCellSwipeType {
    case primary, secondary, none
}

enum CollectionViewCellState {
    case idle, open
}

public class CollectionViewSwipeToEditController: NSObject, UIGestureRecognizerDelegate, ActionsViewDelegate {
    
    let collectionView: UICollectionView
    var swipeTranslationByIndexPath: [IndexPath: CGFloat] = [:]
    
    var activeCell: ArticleCollectionViewCell? {
        guard let indexPath = activeIndexPath else {
            return nil
        }
        return collectionView.cellForItem(at: indexPath) as? ArticleCollectionViewCell
    }
    
    var activeIndexPath: IndexPath?
    var isRTL: Bool = false
    var initialSwipeTranslation: CGFloat = 0
    
    public var primaryActions: [CollectionViewCellAction] = []
    public var secondaryActions: [CollectionViewCellAction] = []
    
    let panGestureRecognizer: UIPanGestureRecognizer
    let longPressGestureRecognizer: UILongPressGestureRecognizer
    
    public init(collectionView: UICollectionView) {
        self.collectionView = collectionView
        panGestureRecognizer = UIPanGestureRecognizer()
        longPressGestureRecognizer = UILongPressGestureRecognizer()
        super.init()
        panGestureRecognizer.addTarget(self, action: #selector(handlePanGesture))
        longPressGestureRecognizer.addTarget(self, action: #selector(handleLongPressGesture))
        if let gestureRecognizers = self.collectionView.gestureRecognizers {
            var otherGestureRecognizer: UIGestureRecognizer
            for gestureRecognizer in gestureRecognizers {
                otherGestureRecognizer = gestureRecognizer is UIPanGestureRecognizer ? panGestureRecognizer : longPressGestureRecognizer
                gestureRecognizer.require(toFail: otherGestureRecognizer)
            }

        }
        
        panGestureRecognizer.delegate = self
        self.collectionView.addGestureRecognizer(panGestureRecognizer)
        
        longPressGestureRecognizer.delegate = self
        longPressGestureRecognizer.minimumPressDuration = 0.05
        longPressGestureRecognizer.require(toFail: panGestureRecognizer)
        self.collectionView.addGestureRecognizer(longPressGestureRecognizer)
        
    }
    
    public func swipeTranslationForItem(at indexPath: IndexPath) -> CGFloat? {
        return swipeTranslationByIndexPath[indexPath]
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === panGestureRecognizer {
            return panGestureRecognizerShouldBegin(panGestureRecognizer)
        }
        
        if gestureRecognizer === longPressGestureRecognizer  {
            return longPressGestureRecognizerShouldBegin(longPressGestureRecognizer)
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
            if let indexPath = activeIndexPath {
                initialSwipeTranslation = swipeTranslationByIndexPath[indexPath] ?? 0
            }
        }
        
        isRTL = false
        if #available(iOS 10.0, *) {
            isRTL = collectionView.effectiveUserInterfaceLayoutDirection == .rightToLeft
        }
        let isPrimary = isRTL ? velocity.x > 0 : velocity.x < 0
        
        if indexPath == activeIndexPath && !isPrimary{
            return true
        }
        
        if activeIndexPath != nil && activeIndexPath != indexPath {
            closeActionPane()
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
        if let cell = activeCell {
            cell.actionsView.actions = primaryActions
            cell.actionsView.semanticContentAttribute = isRTL ? .forceRightToLeft : .forceLeftToRight
        }
        return true
    }
    
    func longPressGestureRecognizerShouldBegin(_ gestureRecognizer: UILongPressGestureRecognizer) -> Bool {
        guard let cell = activeCell else {
            return false
        }
        
        // Don't allow the cancel gesture to recognize if any of the touches are within the actions view.
        let numberOfTouches = gestureRecognizer.numberOfTouches
        
        for touchIndex in 0..<numberOfTouches {
            let touchLocation = gestureRecognizer.location(ofTouch: touchIndex, in: cell.actionsView)
            let touchedActionsView = cell.actionsView.bounds.contains(touchLocation)
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
        guard let indexPath = activeIndexPath, let cell = activeCell else {
            return
        }
        cell.actionsView.delegate = self
        let deltaX = sender.translation(in: collectionView).x
        let velocityX = sender.velocity(in: collectionView).x
        var swipeTranslation = deltaX + initialSwipeTranslation
        let normalizedSwipeTranslation = isRTL ? swipeTranslation : -swipeTranslation
        switch (sender.state) {
        case .began:
            cell.isSwiping = true
            fallthrough
        case .changed:
            if normalizedSwipeTranslation < 0 {
                let normalizedSqrt = sqrt(abs(normalizedSwipeTranslation))
                swipeTranslation = isRTL ? 0 - normalizedSqrt : normalizedSqrt
            }
            if normalizedSwipeTranslation > cell.actionsView.maximumWidth {
                let maxWidth = cell.actionsView.maximumWidth
                let delta = normalizedSwipeTranslation - maxWidth
                swipeTranslation = isRTL ? maxWidth + sqrt(delta) : 0 - maxWidth - sqrt(delta)
            }
            cell.swipeVelocity = velocityX
            cell.swipeTranslation = swipeTranslation
            swipeTranslationByIndexPath[indexPath] = swipeTranslation
        case .cancelled:
            fallthrough
        case .failed:
            fallthrough
        case .ended:
            let isOpen: Bool
            let velocityAdjustment = 0.3 * velocityX
            if isRTL {
                isOpen = swipeTranslation + velocityAdjustment > 0.5 * cell.actionsView.maximumWidth
            } else {
                isOpen = -swipeTranslation - velocityAdjustment > 0.5 * cell.actionsView.maximumWidth
            }
            if isOpen {
                openActionPane()
            } else {
                closeActionPane()
            }
            fallthrough
        default:
            break
        }
    }
    
    @objc func handleLongPressGesture(_ sender: UILongPressGestureRecognizer) {
        guard activeIndexPath != nil else {
            return
        }
        
        switch (sender.state) {
        case .ended:
            closeActionPane()
        default:
            break
        }
    }
    
    // MARK: - States
    
    func openActionPane() {
        collectionView.isScrollEnabled = false
        guard let cell = activeCell else {
            return
        }
        cell.openActionPane()
        guard let indexPath = activeIndexPath else {
            return
        }
        swipeTranslationByIndexPath[indexPath] = cell.swipeTranslation
    }
    
    public func performedAction() {
        closeActionPane()
    }
    
    public func closeActionPane() {
        collectionView.isScrollEnabled = true
        guard let cell = activeCell else {
            return
        }
        cell.closeActionPane()
        guard let indexPath = activeIndexPath else {
            return
        }
        activeIndexPath = nil
        swipeTranslationByIndexPath[indexPath] = nil
    }
    
}
