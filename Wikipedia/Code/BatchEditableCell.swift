import UIKit

public protocol CollectionViewBatchEditControllerDelegate: NSObjectProtocol {
    
}

public class CollectionViewBatchEditController {
    /// View controller that owns the navigationItem.
    let viewController: UIViewController
    
    public var collectionView: UICollectionView? = nil {
        didSet {
           batchEditingState = .closed
        }
    }
    
    public weak var delegate: CollectionViewBatchEditControllerDelegate?
    
    public init(viewController: UIViewController) {
        self.viewController = viewController
        defer {
            batchEditingState = .closed
        }
    }
    
    fileprivate var batchEditingState: BatchEditState = .closed {
        didSet {
            let isClosed = batchEditingState == .closed
            let barButtonSystemItem: UIBarButtonSystemItem = isClosed ? UIBarButtonSystemItem.edit : UIBarButtonSystemItem.cancel
            let tag = isClosed ? 0 : 1
            viewController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: barButtonSystemItem, target: self, action: #selector(batchEdit(_:)))
            viewController.navigationItem.rightBarButtonItem?.tag = tag
        }
    }
    
    @objc func batchEdit(_ sender: UIBarButtonItem) {
        switch sender.tag {
        case 0:
            batchEditingState = .open
        case 1:
            batchEditingState = .closed
        default:
            return
        }
    }
    
    
}

public enum BatchEditActionType {
    case edit
    case delete
    
    public func action(with target: Any?, indexPath: IndexPath) -> BatchEditAction {
        switch self {
        case .edit:
            return BatchEditAction(type: .edit, icon: #imageLiteral(resourceName: "temp-remove-control"), at: indexPath)
        case .delete:
            return BatchEditAction(type: .edit, icon: #imageLiteral(resourceName: "temp-remove-control"), at: indexPath)
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

public enum BatchEditState {
    case open
    case closed
}

public protocol BatchEditableCell: NSObjectProtocol {
    var batchEditState: BatchEditState { get set }
}

