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
            // SWIPE: Should we be returning nil?
            return nil
        }
        set {
            
        }
    }
    
    public var primaryActions: [CollectionViewCellAction] = []
    public var secondaryActions: [CollectionViewCellAction] = []
    
    public init(collectionView: UICollectionView) {
        self.collectionView = collectionView
        super.init()
        addPanGesture(to: self.collectionView)
        // SWIPE: Call addLongPressGesture.
    }
    
    func addPanGesture(to collectionView: UICollectionView) {
        panGesture.addTarget(self, action: #selector(handlePanGesture))
        panGesture.delegate = self
        collectionView.addGestureRecognizer(panGesture)
    }
    
    func addLongPressGesture(to collectionView: UICollectionView) {
        longPressGesture.addTarget(self, action: #selector(handleLongPressGesture))
        longPressGesture.delegate = self
        collectionView.addGestureRecognizer(longPressGesture)
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let cell = activeCell else { return false }

        let velocity = panGesture.velocity(in: collectionView)
        
        // Begin only if there's enough x velocity.
        if fabs(velocity.y) >= fabs(velocity.x) {
            return false
        }
        
        cell.actions = velocity.x < 0 ? primaryActions : secondaryActions
        
        guard cell.actions.count > 0 else { return false }
        
        cell.swipeType = velocity.x < 0 ? .primary : .secondary
        print("cell.swipeType: \(cell.swipeType)")
        activeCell = cell
        
        return true
    }
    
    @objc func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        guard let cell = activeCell else { return }
        
        switch (sender.state) {
        case .began:
            print("handlePanGesture: began")
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
        print("handleLongPressGesture")
    }
    
    // MARK: - States
    func didEnterIdleState() {
        collectionView.isScrollEnabled = true
        if let cell = activeCell {
            activeCell = nil
            // SWIPE: Handle action pane closing.
            // cell.closeActionPane(animated: true)
        }
    }
    
    func didEnterOpenState() {
        collectionView.isScrollEnabled = false
        if let cell = activeCell {
            // SWIPE: Handle action pane opening.
             cell.openActionPane(animated: true)
        }
    }
    
}
