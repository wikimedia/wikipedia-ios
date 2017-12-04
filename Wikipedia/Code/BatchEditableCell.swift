import UIKit

@objc public protocol BatchEditActionDelegate: NSObjectProtocol {
    @objc func didBatchSelect(_ action: BatchEditAction) -> Bool
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
    var buttonWidth: CGFloat  = 0
    var minButtonWidth: CGFloat = 60
    
    func createSubview(for action: BatchEditAction) {
        for view in subviews {
            view.removeFromSuperview()
        }
        
        var maxButtonWidth: CGFloat = 0
        
        // .withRenderingMode(.alwaysTemplate) can be set directly on assets, once we have them
        let button = UIButton(type: .custom)
        button.setImage(action.icon.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setImage(action.confirmationIcon.withRenderingMode(.alwaysTemplate), for: .selected)
        button.titleLabel?.numberOfLines = 1
        button.contentEdgeInsets = UIEdgeInsetsMake(0, 14, 0, 14)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(didBatchSelect(_:)), for: .touchUpInside)
        maxButtonWidth = max(maxButtonWidth, button.intrinsicContentSize.width)
        insertSubview(button, at: 0)
        self.button = button
        
        backgroundColor = button.backgroundColor
        buttonWidth = max(minButtonWidth, maxButtonWidth)
        setNeedsLayout()
    }
    
    public weak var delegate: BatchEditActionDelegate?
    
    @objc func didBatchSelect(_ sender: UIButton) {
        guard let action = action else {
            return
        }
        let _ = delegate?.didBatchSelect(action)
    }
    
    fileprivate var theme: Theme = Theme.standard
    
    public func apply(theme: Theme) {
        button.imageView?.tintColor = theme.colors.secondaryText
    }

}

public class CollectionViewBatchEditController: NSObject, BatchEditActionDelegate {

    let collectionViewController: UICollectionViewController
    
    public weak var delegate: BatchEditActionDelegate?
    
    public init(collectionViewController: UICollectionViewController) {
        self.collectionViewController = collectionViewController
        super.init()
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
            for cell in editableCells {
                cell.batchEditingState = batchEditingState
                cell.batchEditActionView.delegate = self
            }
            var barButtonSystemItem: UIBarButtonSystemItem = UIBarButtonSystemItem.edit
            var tag = 0
            switch batchEditingState {
            case .none:
                break
            case .cancelled:
                closeBatchEditPane()
            case .open:
                barButtonSystemItem = UIBarButtonSystemItem.cancel
                tag = 1
                openBatchEditPane()
            }
            // change, don't call parent directly here
            collectionViewController.parent?.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: barButtonSystemItem, target: self, action: #selector(batchEdit(_:)))
            collectionViewController.parent?.navigationItem.rightBarButtonItem?.tag = tag
        }
    }
    
    fileprivate func openBatchEditPane() {
        collectionViewController.collectionView?.allowsMultipleSelection = true
        for cell in editableCells {
            UIView.animate(withDuration: 0.3, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
                cell.batchEditActionView.expand()
                cell.batchEditingTranslation = cell.batchEditActionView.buttonWidth != 0 ? cell.batchEditActionView.buttonWidth : cell.batchEditActionView.minButtonWidth
                cell.layoutIfNeeded()
            }, completion: nil)
        }

    }
    
    fileprivate func closeBatchEditPane() {
        for cell in editableCells {
            UIView.animate(withDuration: 0.3, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
                cell.isSelected = false
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
    
    public func didBatchSelect(_ action: BatchEditAction) -> Bool {
        isBatchEditToolbarVisible = true
        return self.delegate?.didBatchSelect(action) ?? false
    }
    
    var isBatchEditToolbarVisible: Bool = false {
        didSet {
            guard let toolbar = batchEditToolbar else {
                return
            }
            if isBatchEditToolbarVisible {
                collectionViewController.collectionView?.addSubview(toolbar)
            } else {
                toolbar.removeFromSuperview()
            }
            collectionViewController.parent?.tabBarController?.tabBar.isHidden = isBatchEditToolbarVisible
        }
    }
    
    fileprivate lazy var batchEditToolbar: UIToolbar? = {
        let tabBarHeight = collectionViewController.parent?.tabBarController?.tabBar.frame.size.height ?? 0
        guard let collectionView = collectionViewController.collectionView else {
            return nil
        }
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: collectionView.bounds.height - 44, width: collectionView.bounds.width, height: 44))
        let updateItem = UIBarButtonItem(title: "Update", style: .plain, target: self, action: #selector(update))
        let addToListItem = UIBarButtonItem(title: "Add to list", style: .plain, target: self, action: #selector(addToList))
        let unsaveItem = UIBarButtonItem(title: "Unsave", style: .plain, target: self, action: #selector(unsave))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        toolbar.items = [updateItem, flexibleSpace, addToListItem, flexibleSpace, unsaveItem]
        return toolbar
    }()
    
    @objc func update() {
        
    }
    
    @objc func addToList() {
        
    }
    
    @objc func unsave() {
        
    }
    
}

public enum BatchEditActionType {
    case select
    
    public func action(with target: Any?, indexPath: IndexPath) -> BatchEditAction {
        switch self {
        case .select:
            let icon = UIImage(named: "swipe-action-save", in: Bundle.wmf, compatibleWith: nil)
            let confirmationIcon = UIImage(named: "swipe-action-unsave", in: Bundle.wmf, compatibleWith: nil)
            return BatchEditAction(accessibilityTitle: "Select", type: .select, icon: icon!, confirmationIcon: confirmationIcon!, at: indexPath, target: target, selector: #selector(BatchEditActionDelegate.didBatchSelect(_:)))
        }
    }
}

public class BatchEditAction: UIAccessibilityCustomAction {
    public let type: BatchEditActionType
    let icon: UIImage
    let confirmationIcon: UIImage
    public let indexPath: IndexPath
    
    public init(accessibilityTitle: String, type: BatchEditActionType, icon: UIImage, confirmationIcon: UIImage, at indexPath: IndexPath, target: Any?, selector: Selector) {
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
    var isSelected: Bool { get set } // selection has to be reset on cancel
}

