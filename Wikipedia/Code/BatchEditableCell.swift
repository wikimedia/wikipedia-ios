import UIKit

public protocol CollectionViewBatchEditControllerDelegate: NSObjectProtocol {
    
}

public class CollectionViewBatchEditController {
    public var collectionView: UICollectionView? = nil {
        didSet {
            
        }
    }
    public weak var delegate: CollectionViewBatchEditControllerDelegate?
    public init() {}
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

