import UIKit

public class BatchEditActionsView: SizeThatFitsView, Themeable {
    public var actions: [BatchEditAction] = [] {
        didSet {
        }
    }
    
    public func apply(theme: Theme) {
        //
    }
}

public protocol CollectionViewBatchEditControllerDelegate: NSObjectProtocol {
    func availableActions(at indexPath: IndexPath) -> [BatchEditAction]
}

public class CollectionViewBatchEditController {
    /// View controller that owns the navigationItem.
    let viewController: UIViewController
    
    public var collectionView: UICollectionView? = nil {
        didSet {
           batchEditingState = .none
        }
    }
    
    public weak var delegate: CollectionViewBatchEditControllerDelegate?
    
    public init(viewController: UIViewController) {
        self.viewController = viewController
        defer {
            batchEditingState = .none
        }
    }
    
    fileprivate var editableCells: [BatchEditableCell] {
        guard let collectionView = collectionView, let editableCells = collectionView.visibleCells as? [BatchEditableCell] else {
            return []
        }
        return editableCells
    }
    
    fileprivate var batchEditingState: BatchEditingState = .none {
        didSet {
            editableCells.forEach({ $0.batchEditingState = batchEditingState })
            var barButtonSystemItem: UIBarButtonSystemItem = UIBarButtonSystemItem.edit
            var tag = 0
            switch batchEditingState {
            case .none:
                fallthrough
            case .cancelled:
                break
            case .open:
                barButtonSystemItem = UIBarButtonSystemItem.cancel
                tag = 1
            }
            viewController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: barButtonSystemItem, target: self, action: #selector(batchEdit(_:)))
            viewController.navigationItem.rightBarButtonItem?.tag = tag
        }
    }
    
    @objc func batchEdit(_ sender: UIBarButtonItem) {
        switch sender.tag {
        case 0:
            batchEditingState = .open
        case 1:
            batchEditingState = .cancelled
        default:
            return
        }
    }
    
    
}

public enum BatchEditActionType {
    case select
    
    public func action(with target: Any?, indexPath: IndexPath) -> BatchEditAction {
        switch self {
        case .select:
            return BatchEditAction(type: .select, icon: #imageLiteral(resourceName: "temp-remove-control"), at: indexPath)
        }
    }
}

public class BatchEditAction {
    let type: BatchEditActionType
    let icon: UIImage
    let indexPath: IndexPath
    
    public init(type: BatchEditActionType, icon: UIImage, at indexPath: IndexPath) {
        self.type = type
        self.icon = icon
        self.indexPath = indexPath
    }
}

public enum BatchEditingState {
    case none
    case open
    case cancelled
}

public protocol BatchEditableCell: NSObjectProtocol {
    var batchEditingState: BatchEditingState { get set }
}

