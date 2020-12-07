import Foundation

public enum CollectionViewCellSwipeType {
    case primary, secondary, none
}

enum CollectionViewCellState {
    case idle, open
}

// wrapper around UIBarButtonItem that lets us access systemItem after button creation
public class SystemBarButton: UIBarButtonItem {
    var systemItem: UIBarButtonItem.SystemItem?
    public convenience init(with barButtonSystemItem: UIBarButtonItem.SystemItem, target: Any?, action: Selector?) {
        self.init(barButtonSystemItem: barButtonSystemItem, target: target, action: action)
        self.systemItem = barButtonSystemItem
    }
}

public protocol CollectionViewEditControllerNavigationDelegate: class {
    func didChangeEditingState(from oldEditingState: EditingState, to newEditingState: EditingState, rightBarButton: UIBarButtonItem?, leftBarButton: UIBarButtonItem?) // same implementation for 2/3
    func didSetBatchEditToolbarHidden(_ batchEditToolbarViewController: BatchEditToolbarViewController, isHidden: Bool, with items: [UIButton]) // has default implementation
    func newEditingState(for currentEditingState: EditingState, fromEditBarButtonWithSystemItem systemItem: UIBarButtonItem.SystemItem) -> EditingState
    func emptyStateDidChange(_ empty: Bool)
    var currentTheme: Theme { get }
}

public class CollectionViewEditController: NSObject, UIGestureRecognizerDelegate, ActionDelegate {
    
    let collectionView: UICollectionView
    
    struct SwipeInfo {
        let translation: CGFloat
        let velocity: CGFloat
        let state: SwipeState
    }
    var swipeInfoByIndexPath: [IndexPath: SwipeInfo] = [:]
    var configuredCellsByIndexPath: [IndexPath: SwipeableCell] = [:]

    var activeCell: SwipeableCell? {
        guard let indexPath = activeIndexPath else {
            return nil
        }
        return collectionView.cellForItem(at: indexPath) as? SwipeableCell
    }

    public var isActive: Bool {
        return activeIndexPath != nil
    }

    var activeIndexPath: IndexPath? {
        didSet {
            if activeIndexPath != nil {
                editingState = .swiping
            } else {
                editingState = isCollectionViewEmpty ? .empty : .none
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(close), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public func swipeTranslationForItem(at indexPath: IndexPath) -> CGFloat? {
        return swipeInfoByIndexPath[indexPath]?.translation
    }
    
    public func configureSwipeableCell(_ cell: UICollectionViewCell, forItemAt indexPath: IndexPath, layoutOnly: Bool) {
        guard
            !layoutOnly,
            let cell = cell as? SwipeableCell,
            cell.isSwipeEnabled else {
            return
        }
        cell.actions = availableActions(at: indexPath)
        configuredCellsByIndexPath[indexPath] = cell
        guard let info = swipeInfoByIndexPath[indexPath] else {
            return
        }
        cell.swipeState = info.state
        cell.actionsView.delegate = self
        cell.swipeTranslation = info.translation
    }
    
    public func deconfigureSwipeableCell(_ cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        configuredCellsByIndexPath.removeValue(forKey: indexPath)
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
        if let cell = activeCell {
            return cell.actionsView.updateConfirmationImage(for: action) {
               self.delegatePerformingAction(action)
            }
        }
        return self.delegatePerformingAction(action)
    }
    
    private func delegatePerformingAction(_ action: Action) -> Bool {
        guard action.indexPath == activeIndexPath else {
            return self.delegate?.didPerformAction(action) ?? false
        }
        let activatedAction = action.type == .delete ? action : nil
        closeActionPane(with: activatedAction) { (finished) in
            let _ = self.delegate?.didPerformAction(action)
        }
        return true
    }
    
    public func willPerformAction(_ action: Action) -> Bool {
        return delegate?.willPerformAction(action) ?? didPerformAction(action)
    }
    
    public func availableActions(at indexPath: IndexPath) -> [Action] {
        return delegate?.availableActions(at: indexPath) ?? []
    }
    
    func panGestureRecognizerShouldBegin(_ gestureRecognizer: UIPanGestureRecognizer) -> Bool {
        var shouldBegin = false
        defer {
            if !shouldBegin {
                closeActionPane()
            }
        }
        guard delegate != nil else {
            return shouldBegin
        }
        
        let position = gestureRecognizer.location(in: collectionView)
        
        guard let indexPath = collectionView.indexPathForItem(at: position) else {
            return shouldBegin
        }

        let velocity = gestureRecognizer.velocity(in: collectionView)
        
        // Begin only if there's enough x velocity.
        if abs(velocity.y) >= abs(velocity.x) {
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
        
        guard let cell = activeCell, !cell.actions.isEmpty && cell.isSwipeEnabled else {
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
       let batchEditToolbarViewController = BatchEditToolbarViewController(nibName: "BatchEditToolbarViewController", bundle: Bundle.wmf)
        batchEditToolbarViewController.items = self.batchEditToolbarItems
        return batchEditToolbarViewController
    }()
    
    public var batchEditToolbarView: UIView {
        return self.batchEditToolbarViewController.view
    }
    
    @objc func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        guard let indexPath = activeIndexPath, let cell = activeCell, cell.isSwipeEnabled else {
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
            swipeInfoByIndexPath[indexPath] = SwipeInfo(translation: swipeTranslation, velocity: velocityX, state: .swiping)
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
        swipeInfoByIndexPath[indexPath] = SwipeInfo(translation: targetTranslation, velocity: velocity, state: .open)
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
    
    public var isShowingDefaultCellOnly: Bool = false {
        didSet {
            guard oldValue != isShowingDefaultCellOnly else {
                return
            }
            editingState = isCollectionViewEmpty || isShowingDefaultCellOnly ? .empty : .none
        }
    }
    
    public weak var navigationDelegate: CollectionViewEditControllerNavigationDelegate? {
        willSet {
            batchEditToolbarViewController.remove()
        }
        didSet {
            guard oldValue !== navigationDelegate else {
                return
            }
            if navigationDelegate == nil {
                editingState = .unknown
            } else {
                editingState = isCollectionViewEmpty || isShowingDefaultCellOnly ? .empty : .none
            }
        }
    }
    
    private var editableCells: [BatchEditableCell] {
        guard let editableCells = collectionView.visibleCells as? [BatchEditableCell] else {
            return []
        }
        return editableCells
    }
    
    public var isBatchEditing: Bool {
        return editingState == .open
    }
    
    private var editingState: EditingState = .unknown {
        didSet {
            guard editingState != oldValue else {
                return
            }
            editingStateDidChange(from: oldValue, to: editingState)
        }
    }
    
    private func editingStateDidChange(from oldValue: EditingState, to newValue: EditingState) {
        
        let rightBarButtonSystemItem: UIBarButtonItem.SystemItem?
        let leftBarButtonSystemItem: UIBarButtonItem.SystemItem?
        var isRightBarButtonEnabled = !(isCollectionViewEmpty || isShowingDefaultCellOnly) || shouldShowEditButtonsForEmptyState
        
        switch newValue {
        case .editing:
            areSwipeActionsDisabled = true
            leftBarButtonSystemItem = .cancel
            rightBarButtonSystemItem = .done
            isRightBarButtonEnabled = true
            if oldValue == .open {
                transformBatchEditPane(for: editingState)
            }
        case .swiping:
            leftBarButtonSystemItem = nil
            rightBarButtonSystemItem = .edit
        case .open:
            leftBarButtonSystemItem = nil
            rightBarButtonSystemItem = .cancel
            transformBatchEditPane(for: editingState)
        case .closed:
            leftBarButtonSystemItem = nil
            rightBarButtonSystemItem = .edit
            transformBatchEditPane(for: editingState)
        case .empty:
            leftBarButtonSystemItem = nil
            rightBarButtonSystemItem = shouldShowEditButtonsForEmptyState ? .edit : nil
            isBatchEditToolbarHidden = true
        default:
            leftBarButtonSystemItem = nil
            rightBarButtonSystemItem = .edit
        }
        
        var rightButton: SystemBarButton?
        var leftButton: SystemBarButton?
        
        if let barButtonSystemItem = rightBarButtonSystemItem {
            rightButton = SystemBarButton(with: barButtonSystemItem, target: self, action: #selector(barButtonPressed(_:)))
        }
        
        if let barButtonSystemItem = leftBarButtonSystemItem {
            leftButton = SystemBarButton(with: barButtonSystemItem, target: self, action: #selector(barButtonPressed(_:)))
        }
        
        leftButton?.tag = editingState.tag
        rightButton?.tag = editingState.tag
        rightButton?.isEnabled = isRightBarButtonEnabled
        
        let font = rightBarButtonSystemItem != .edit ? UIFont.wmf_font(.semiboldBody) : UIFont.wmf_font(.body)
        let attributes = [NSAttributedString.Key.font: font]
        rightButton?.setTitleTextAttributes(attributes, for: .normal)
        leftButton?.setTitleTextAttributes(attributes, for: .normal)
        
        navigationDelegate?.didChangeEditingState(from: oldValue, to: editingState, rightBarButton: rightButton, leftBarButton: leftButton)
    }
    
    private func transformBatchEditPane(for state: EditingState, animated: Bool = true) {
        guard !isCollectionViewEmpty else {
            return
        }
        let willOpen = state == .open
        areSwipeActionsDisabled = willOpen
        collectionView.allowsMultipleSelection = willOpen
        isBatchEditToolbarHidden = !willOpen
        for cell in editableCells {
            guard cell.isBatchEditable else {
                continue
            }
            if animated {
                // ensure layout is in the start anim state
                cell.isBatchEditing = !willOpen
                cell.layoutIfNeeded()
                UIView.animate(withDuration: 0.3, delay: 0.1, options: [.allowUserInteraction, .beginFromCurrentState, .curveEaseInOut], animations: {
                    cell.isBatchEditing = willOpen
                    cell.layoutIfNeeded()
                })
            } else {
                cell.isBatchEditing = willOpen
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
        guard editingState == .open || editingState == .swiping else {
            return
        }
        if editingState == .swiping {
            editingState = .none
        } else {
            editingState = .closed
        }
        closeActionPane()
    }
    
    private func emptyStateDidChange() {
        if isCollectionViewEmpty || isShowingDefaultCellOnly {
            editingState = .empty
        } else {
            editingState = .none
        }
        navigationDelegate?.emptyStateDidChange(isCollectionViewEmpty)
    }
    
    public var isCollectionViewEmpty: Bool = true {
        didSet {
            guard oldValue != isCollectionViewEmpty else {
                return
            }
            emptyStateDidChange()
        }
    }
    
    public var shouldShowEditButtonsForEmptyState: Bool = false
    
    @objc private func barButtonPressed(_ sender: SystemBarButton) {
        guard let navigationDelegate = navigationDelegate else {
            assertionFailure("Unable to set new editing state - navigationDelegate is nil")
            return
        }
        guard let systemItem = sender.systemItem else {
            assertionFailure("Unable to set new editing state - systemItem is nil")
            return
        }
        let currentEditingState = editingState
        if currentEditingState == .swiping {
            closeActionPane()
        }
        editingState = navigationDelegate.newEditingState(for: currentEditingState, fromEditBarButtonWithSystemItem: systemItem)
    }
    
    public func changeEditingState(to newEditingState: EditingState) {
        editingState = newEditingState
    }
    
    public var isTextEditing: Bool = false {
        didSet {
            editingState = isTextEditing ? .editing : .done
        }
    }
    
    public var isClosed: Bool {
        let isClosed = editingState != .open
        if !isClosed {
            batchEditToolbarViewController.setItemsEnabled(!selectedIndexPaths.isEmpty)
        }
        return isClosed
    }
    
    public func transformBatchEditPaneOnScroll() {
        transformBatchEditPane(for: editingState, animated: false)
    }
    
    private var selectedIndexPaths: [IndexPath] {
        return collectionView.indexPathsForSelectedItems ?? []
    }
    
    private var isBatchEditToolbarHidden: Bool = true {
        didSet {
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
        guard let delegate = delegate else {
            assertionFailure("delegate should be set by now")
            editingState = .closed
            return
        }
        guard let didPerformBatchEditToolbarAction = delegate.didPerformBatchEditToolbarAction else {
            assertionFailure("delegate should implement didPerformBatchEditToolbarAction")
            editingState = .closed
            return
        }
        let action = batchEditToolbarActions[sender.tag]
        didPerformBatchEditToolbarAction(action) { finished in
            if finished {
                self.editingState = .closed
            }
        }
    }
    
    private lazy var batchEditToolbarItems: [UIButton] = {
        
        var buttons: [UIButton] = []
        
        for (index, action) in batchEditToolbarActions.enumerated() {
            let button = UIButton(type: .system)
            button.addTarget(self, action: #selector(didPerformBatchEditToolbarAction(with:)), for: .touchUpInside)
            button.tag = index
            button.setTitle(action.title, for: UIControl.State.normal)
            buttons.append(button)
            button.isEnabled = false
        }
        
        return buttons
    }()
    
}
