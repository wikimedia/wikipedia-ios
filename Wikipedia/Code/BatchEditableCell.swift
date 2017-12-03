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

    let collectionViewController: UICollectionViewController
    
    public weak var delegate: CollectionViewBatchEditControllerDelegate?
    
    public init(collectionViewController: UICollectionViewController) {
        self.collectionViewController = collectionViewController
        defer {
            batchEditingState = .none
        }
    }
    
    fileprivate var editableCells: [BatchEditableCell] {
        guard let editableCells = collectionViewController.collectionView?.visibleCells as? [BatchEditableCell] else {
            return []
        }
        return editableCells
    }
    
    public func cancelBatchEditing() {
        
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
            // change
            collectionViewController.parent?.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: barButtonSystemItem, target: self, action: #selector(batchEdit(_:)))
            collectionViewController.parent?.navigationItem.rightBarButtonItem?.tag = tag
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

