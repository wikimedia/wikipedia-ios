import UIKit

@objc public protocol BatchEditActionDelegate: NSObjectProtocol {
    @objc func didPerformAction(_ action: BatchEditAction) -> Bool
}

public class BatchEditActionView: SizeThatFitsView, Themeable {
    
    var needsSubviews = true
    var button: UIButton = UIButton()
    
    internal var action: BatchEditAction? = nil {
        didSet {
            needsSubviews = true
        }
    }
    
    func expand() {
        bringSubview(toFront: button)
        setNeedsLayout()
    }
    
    public override var frame: CGRect {
        didSet {
            setNeedsLayout()
        }
    }
    
    public override var bounds: CGRect {
        didSet {
            setNeedsLayout()
        }
    }
    
    public override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let superSize = super.sizeThatFits(size, apply: apply)
        if (apply) {
            if (size.width > 0 && needsSubviews) {
                guard let action = action else {
                    return superSize
                }
                createSubview(for: action)
                needsSubviews = false
            }
            let buttonDelta = min(size.width, buttonWidth)
            var x: CGFloat = 0
            button.frame = CGRect(x: x, y: 0, width: buttonWidth, height: size.height)
            x += buttonDelta
        }
        let width = superSize.width == UIViewNoIntrinsicMetric ? buttonWidth : superSize.width
        let height = superSize.height == UIViewNoIntrinsicMetric ? 50 : superSize.height
        return CGSize(width: width, height: height)
    }
    public var theme = Theme.dark
    var buttonWidth: CGFloat  = 0
    var minButtonWidth: CGFloat = 60
    
    func createSubview(for action: BatchEditAction) {
        for view in subviews {
            view.removeFromSuperview()
        }
        
        var maxButtonWidth: CGFloat = 0
        
        let button = UIButton(type: .custom)
        button.setImage(action.icon, for: .normal)
        button.titleLabel?.numberOfLines = 1
        button.contentEdgeInsets = UIEdgeInsetsMake(0, 14, 0, 14)
        button.backgroundColor = theme.colors.paperBackground
        button.addTarget(self, action: #selector(didPerformAction(_:)), for: .touchUpInside)
        maxButtonWidth = max(maxButtonWidth, button.intrinsicContentSize.width)
        insertSubview(button, at: 0)
        self.button = button
        
        backgroundColor = button.backgroundColor
        buttonWidth = max(minButtonWidth, maxButtonWidth)
        setNeedsLayout()
    }
    
    public weak var delegate: BatchEditActionDelegate?
    
    @objc func didPerformAction(_ sender: UIButton) {
        guard let action = action else {
            return
        }
        if let image = action.confirmationIcon {
            sender.setImage(image, for: .normal)
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
                let _ = self.delegate?.didPerformAction(action)
            }
        } else {
            let _ = delegate?.didPerformAction(action)
        }
    }
    
    public func apply(theme: Theme) {
        //
    }
}

public protocol CollectionViewBatchEditControllerDelegate: NSObjectProtocol {
    func batchEditAction(at indexPath: IndexPath) -> BatchEditAction
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
    
    fileprivate var batchEditingState: BatchEditingState = .none {
        didSet {
            editableCells.forEach({ $0.batchEditingState = batchEditingState })
            var barButtonSystemItem: UIBarButtonSystemItem = UIBarButtonSystemItem.edit
            var tag = 0
            switch batchEditingState {
            case .none:
                fallthrough
            case .cancelled:
                closeBatchEditPane()
            case .open:
                barButtonSystemItem = UIBarButtonSystemItem.cancel
                tag = 1
                openBatchEditPane()
            }
            // change
            collectionViewController.parent?.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: barButtonSystemItem, target: self, action: #selector(batchEdit(_:)))
            collectionViewController.parent?.navigationItem.rightBarButtonItem?.tag = tag
        }
    }
    
    fileprivate func openBatchEditPane() {
        for cell in editableCells {
            UIView.animate(withDuration: 0.3, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
//                cell.batchEditActionView.expand()
                cell.batchEditingTranslation = cell.batchEditActionView.buttonWidth != 0 ? cell.batchEditActionView.buttonWidth : cell.batchEditActionView.minButtonWidth
                cell.layoutIfNeeded()
            }, completion: nil)
        }

    }
    
    fileprivate func closeBatchEditPane() {
        for cell in editableCells {
            UIView.animate(withDuration: 0.3, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
                cell.batchEditingTranslation = 0
                cell.layoutIfNeeded()
            }, completion: nil)
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
            return BatchEditAction(accessibilityTitle: "Select", type: .select, icon: #imageLiteral(resourceName: "temp-remove-control"), confirmationIcon: #imageLiteral(resourceName: "temp-remove-control"), at: indexPath, target: target, selector: #selector(ActionDelegate.didPerformAction(_:)))
        }
    }
}

public class BatchEditAction: UIAccessibilityCustomAction {
    let type: BatchEditActionType
    let icon: UIImage
    let confirmationIcon: UIImage?
    let indexPath: IndexPath
    
    public init(accessibilityTitle: String, type: BatchEditActionType, icon: UIImage, confirmationIcon: UIImage?, at indexPath: IndexPath, target: Any?, selector: Selector) {
        self.type = type
        self.icon = icon
        self.confirmationIcon = confirmationIcon
        self.indexPath = indexPath
        super.init(name: accessibilityTitle, target: target, selector: selector)
    }
}

public enum BatchEditingState {
    case none
    case open
    case cancelled
}

public protocol BatchEditableCell: NSObjectProtocol {
    var batchEditingState: BatchEditingState { get set }
    var batchEditingTranslation: CGFloat { get set }
    var batchEditActionView: BatchEditActionView { get }
    func layoutIfNeeded() // call to layout views after setting batch edit translation
}

