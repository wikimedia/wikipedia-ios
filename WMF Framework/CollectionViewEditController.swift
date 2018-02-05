import Foundation

public enum CollectionViewCellSwipeType {
    case primary, secondary, none
}

enum CollectionViewCellState {
    case idle, open
}

public protocol BatchEditNavigationDelegate: NSObjectProtocol {
    func didChange(editingState: BatchEditingState, rightBarButton: UIBarButtonItem) // same implementation for 2/3
    func didSetBatchEditToolbarHidden(_ batchEditToolbarViewController: BatchEditToolbarViewController, isHidden: Bool, with items: [UIButton]) // has default implementation
    func emptyStateDidChange(_ empty: Bool)
    var currentTheme: Theme { get }
}

public protocol EditableCollection: NSObjectProtocol {
    var editController: CollectionViewEditController! { get set }
}

public class CollectionViewEditController: NSObject, UIGestureRecognizerDelegate, ActionDelegate {
    
    let collectionView: UICollectionView
    
    struct SwipeInfo {
        let translation: CGFloat
        let velocity: CGFloat
    }
    var swipeInfoByIndexPath: [IndexPath: SwipeInfo] = [:]
    
    var activeCell: SwipeableCell? {
        guard let indexPath = activeIndexPath else {
            return nil
        }
        return collectionView.cellForItem(at: indexPath) as? SwipeableCell
    }

    public var isActive: Bool {
        return activeIndexPath != nil
    }
    // disabled
    var activeIndexPath: IndexPath? {
        didSet {
            if activeIndexPath != nil {
                batchEditingState = .inactive
            } else {
                batchEditingState = .none
            }
        }
    }
    var isRTL: Bool = false
    var initialSwipeTranslation: CGFloat = 0
    let maxExtension: CGFloat = 10
    
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(close), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
    }
    
    public func swipeTranslationForItem(at indexPath: IndexPath) -> CGFloat? {
        return swipeInfoByIndexPath[indexPath]?.translation
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
    
    public weak var delegate: ActionDelegate?
    
    public func didPerformAction(_ action: Action) -> Bool {
        guard action.indexPath == activeIndexPath else {
            return self.delegate?.didPerformAction(action) ?? false
        }
        let activatedAction = action.type == .delete ? action : nil
        closeActionPane(with: activatedAction) { (finished) in
            let _ = self.delegate?.didPerformAction(action)
        }
        return true
    }
    
    public func shouldPerformAction(_ action: Action) -> Bool {
        guard let shouldPerformAction = delegate?.shouldPerformAction?(action) else {
            return didPerformAction(action)
        }
        return shouldPerformAction
    }
    
    func panGestureRecognizerShouldBegin(_ gestureRecognizer: UIPanGestureRecognizer) -> Bool {
        var shouldBegin = false
        defer {
            if !shouldBegin {
                closeActionPane()
            }
        }
        guard let delegate = delegate else {
            return shouldBegin
        }
        
        let position = gestureRecognizer.location(in: collectionView)
        
        guard let indexPath = collectionView.indexPathForItem(at: position) else {
            return shouldBegin
        }

        let velocity = gestureRecognizer.velocity(in: collectionView)
        
        // Begin only if there's enough x velocity.
        if fabs(velocity.y) >= fabs(velocity.x) {
            return shouldBegin
        }
        
        defer {
            if let indexPath = activeIndexPath {
                initialSwipeTranslation = swipeInfoByIndexPath[indexPath]?.translation ?? 0
            }
        }

        isRTL = collectionView.effectiveUserInterfaceLayoutDirection == .rightToLeft
        let isOpenSwipe = isRTL ? velocity.x > 0 : velocity.x < 0

        if !isOpenSwipe { // only allow closing swipes on active cells
            shouldBegin = indexPath == activeIndexPath
            return shouldBegin
        }
        
        if activeIndexPath != nil && activeIndexPath != indexPath {
            closeActionPane()
        }
        
        guard activeIndexPath == nil else {
            shouldBegin = true
            return shouldBegin
        }

        activeIndexPath = indexPath
        guard let cell = activeCell, cell.actions.count > 0 else {
            activeIndexPath = nil
            return shouldBegin
        }
        
        shouldBegin = true
        return shouldBegin
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
    
    private lazy var batchEditToolbarViewController: BatchEditToolbarViewController = {
       let batchEditToolbarViewController = BatchEditToolbarViewController()
        batchEditToolbarViewController.items = self.batchEditToolbarItems
        return batchEditToolbarViewController
    }()
    
    @objc func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        guard let indexPath = activeIndexPath, let cell = activeCell else {
            return
        }
        cell.actionsView.delegate = self
        let deltaX = sender.translation(in: collectionView).x
        let velocityX = sender.velocity(in: collectionView).x
        var swipeTranslation = deltaX + initialSwipeTranslation
        let normalizedSwipeTranslation = isRTL ? swipeTranslation : -swipeTranslation
        let normalizedMaxSwipeTranslation = abs(cell.swipeTranslationWhenOpen)
        switch (sender.state) {
        case .began:
            cell.swipeState = .swiping
            fallthrough
        case .changed:
            if normalizedSwipeTranslation < 0 {
                let normalizedSqrt = maxExtension * log(abs(normalizedSwipeTranslation))
                swipeTranslation = isRTL ? 0 - normalizedSqrt : normalizedSqrt
            }
            if normalizedSwipeTranslation > normalizedMaxSwipeTranslation {
                let maxWidth = normalizedMaxSwipeTranslation
                let delta = normalizedSwipeTranslation - maxWidth
                swipeTranslation = isRTL ? maxWidth + (maxExtension * log(delta)) : 0 - maxWidth - (maxExtension * log(delta))
            }
            cell.swipeTranslation = swipeTranslation
            swipeInfoByIndexPath[indexPath] = SwipeInfo(translation: swipeTranslation, velocity: velocityX)
        case .cancelled:
            fallthrough
        case .failed:
            fallthrough
        case .ended:
            let isOpen: Bool
            let velocityAdjustment = 0.3 * velocityX
            if isRTL {
                isOpen = swipeTranslation + velocityAdjustment > 0.5 * cell.swipeTranslationWhenOpen
            } else {
                isOpen = swipeTranslation + velocityAdjustment < 0.5 * cell.swipeTranslationWhenOpen
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
    
    var areSwipeActionsDisabled: Bool = false {
        didSet {
            longPressGestureRecognizer.isEnabled = !areSwipeActionsDisabled
            panGestureRecognizer.isEnabled = !areSwipeActionsDisabled
        }
    }
    
    // MARK: - States
    
    func openActionPane(_ completion: @escaping (Bool) -> Void = {_ in }) {
        collectionView.allowsSelection = false
        guard let cell = activeCell, let indexPath = activeIndexPath else {
            completion(false)
            return
        }
        let targetTranslation =  cell.swipeTranslationWhenOpen
        let velocity = swipeInfoByIndexPath[indexPath]?.velocity ?? 0
        swipeInfoByIndexPath[indexPath] = SwipeInfo(translation: targetTranslation, velocity: velocity)
        cell.swipeState = .open
        animateActionPane(of: cell, to: targetTranslation, with: velocity, completion: completion)
    }
    
    func closeActionPane(with expandedAction: Action? = nil, _ completion: @escaping (Bool) -> Void = {_ in }) {
        collectionView.allowsSelection = true
        guard let cell = activeCell, let indexPath = activeIndexPath else {
            completion(false)
            return
        }
        activeIndexPath = nil
        let velocity = swipeInfoByIndexPath[indexPath]?.velocity ?? 0
        swipeInfoByIndexPath[indexPath] = nil
        if let expandedAction = expandedAction {
            let translation = isRTL ? cell.bounds.width : 0 - cell.bounds.width
            animateActionPane(of: cell, to: translation, with: velocity, expandedAction: expandedAction, completion: { (finished) in
                //don't set isSwiping to false so that the expanded action stays visible through the fade
                completion(finished)
            })
        } else {
            animateActionPane(of: cell, to: 0, with: velocity, completion: { (finished: Bool) in
                cell.swipeState = self.activeIndexPath == indexPath ? .swiping : .closed
                completion(finished)
            })
        }
    }

    func animateActionPane(of cell: SwipeableCell, to targetTranslation: CGFloat, with swipeVelocity: CGFloat, expandedAction: Action? = nil, completion: @escaping (Bool) -> Void = {_ in }) {
         if let action = expandedAction {
            UIView.animate(withDuration: 0.3, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
                cell.actionsView.expand(action)
                cell.swipeTranslation = targetTranslation
                cell.layoutIfNeeded()
            }, completion: completion)
            return
        }
        let initialSwipeTranslation = cell.swipeTranslation
        let animationTranslation = targetTranslation - initialSwipeTranslation
        let animationDuration: TimeInterval = 0.3
        let distanceInOneSecond = animationTranslation / CGFloat(animationDuration)
        let unitSpeed = distanceInOneSecond == 0 ? 0 : swipeVelocity / distanceInOneSecond
        UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: unitSpeed, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
            cell.swipeTranslation = targetTranslation
            cell.layoutIfNeeded()
        }, completion: completion)
    }
    
    // MARK: - Batch editing
    
    public weak var navigationDelegate: BatchEditNavigationDelegate? {
        willSet {
            batchEditToolbarViewController.remove()
        }
        didSet {
            batchEditingState = .none
        }
    }
    
    private var editableCells: [BatchEditableCell] {
        guard let editableCells = collectionView.visibleCells as? [BatchEditableCell] else {
            return []
        }
        return editableCells
    }
    
    private var batchEditingState: BatchEditingState = .none {
        didSet {
            var barButtonSystemItem: UIBarButtonSystemItem = UIBarButtonSystemItem.edit
            var enabled = true
            var tag = 0
            
            defer {
                let button = UIBarButtonItem(barButtonSystemItem: barButtonSystemItem, target: self, action: #selector(batchEdit(_:)))
                button.tag = tag
                button.isEnabled = enabled
                navigationDelegate?.didChange(editingState: batchEditingState, rightBarButton: button)
            }
            
            guard !isCollectionViewEmpty && !hasDefaultCell else {
                isBatchEditToolbarHidden = true
                enabled = false
                return
            }

            switch batchEditingState {
            case .inactive:
                barButtonSystemItem = .done
                tag = -1
            case .none:
                break
            case .cancelled:
                transformBatchEditPane(for: batchEditingState)
            case .open:
                barButtonSystemItem = UIBarButtonSystemItem.cancel
                tag = 1
                transformBatchEditPane(for: batchEditingState)
            }
        }
    }
    
    private func transformBatchEditPane(for state: BatchEditingState, animated: Bool = true) {
        let willOpen = state == .open
        areSwipeActionsDisabled = willOpen
        collectionView.allowsMultipleSelection = willOpen
        isBatchEditToolbarHidden = !willOpen
        for cell in editableCells {
            let targetTranslation = (willOpen ? cell.batchEditSelectView?.fixedWidth : 0) ?? 0
            if animated {
                UIView.animate(withDuration: 0.3, delay: 0.1, options: [.allowUserInteraction, .beginFromCurrentState, .curveEaseInOut], animations: {
                    cell.batchEditingTranslation = targetTranslation
                    cell.layoutIfNeeded()
                })
            } else {
                cell.batchEditingTranslation = targetTranslation
                cell.layoutIfNeeded()
            }
            if let themeableCell = cell as? Themeable, let navigationDelegate = navigationDelegate {
                themeableCell.apply(theme: navigationDelegate.currentTheme)
            }
        }
        if !willOpen {
            selectedIndexPaths.forEach({ collectionView.deselectItem(at: $0, animated: true) })
            batchEditToolbarViewController.setItemsEnabled(false)
        }
    }
    
    @objc public func close() {
        batchEditingState = .cancelled
        closeActionPane()
    }
    
    public var isCollectionViewEmpty: Bool = false {
        didSet {
            batchEditingState = .none
            navigationDelegate?.emptyStateDidChange(isCollectionViewEmpty)
        }
    }
    
    public var hasDefaultCell: Bool = false {
        didSet {
            guard hasDefaultCell else {
                return
            }
            batchEditingState = .none
        }
    }
    
    @objc private func batchEdit(_ sender: UIBarButtonItem) {
        switch sender.tag {
        case -1:
            closeActionPane()
            batchEditingState = .none
        case 0:
            batchEditingState = .open
        case 1:
            batchEditingState = .cancelled
        default:
            return
        }
    }
    
    public var isClosed: Bool {
        let isClosed = batchEditingState != .open
        if !isClosed {
            batchEditToolbarViewController.setItemsEnabled(!selectedIndexPaths.isEmpty)
        }
        return isClosed
    }
    
    public func transformBatchEditPaneOnScroll() {
        transformBatchEditPane(for: batchEditingState, animated: false)
    }
    
    private var selectedIndexPaths: [IndexPath] {
        return collectionView.indexPathsForSelectedItems ?? []
    }
    
    private var isBatchEditToolbarHidden: Bool = true {
        didSet {
            guard collectionView.window != nil else {
                return
            }
            self.navigationDelegate?.didSetBatchEditToolbarHidden(batchEditToolbarViewController, isHidden: self.isBatchEditToolbarHidden, with: self.batchEditToolbarItems)
        }
    }
    
    private var batchEditToolbarActions: [BatchEditToolbarAction] {
        guard let delegate = delegate, let actions = delegate.availableBatchEditToolbarActions else {
            return []
        }
        return actions
    }
    
    @objc public func didPerformBatchEditToolbarAction(with sender: UIBarButtonItem) {
        let didPerformAction = delegate?.didPerformBatchEditToolbarAction?(batchEditToolbarActions[sender.tag]) ?? false
        if didPerformAction {
            batchEditingState = .cancelled
        }
    }
    
    private lazy var batchEditToolbarItems: [UIButton] = {
        
        var buttons: [UIButton] = []
        
        for (index, action) in batchEditToolbarActions.enumerated() {
            let button = action.button
            button.addTarget(self, action: #selector(didPerformBatchEditToolbarAction(with:)), for: .touchUpInside)
            button.tag = index
            button.setTitle(action.title, for: UIControlState.normal)
            buttons.append(button)
            button.isEnabled = false
        }
        
        return buttons
    }()
    
}
