import UIKit

@objc public protocol BatchEditNavigationDelegate: NSObjectProtocol {
    func changeRightNavButton(to button: UIBarButtonItem)
    func didSetIsBatchEditToolbarVisible(_ isVisible: Bool)
    var batchEditToolbar: UIToolbar { get }
    func createBatchEditToolbar(with items: [UIBarButtonItem], add: Bool)
}

public class BatchEditSelectView: SizeThatFitsView, Themeable {
    
    public var needsSubviews = false
    var button: UIButton = UIButton()
    
    var isSelected: Bool = false {
        didSet {
            button.isSelected = isSelected
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
                createSubview()
                needsSubviews = false
            }
            button.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: size.height)
        }
        let width = superSize.width == UIViewNoIntrinsicMetric ? buttonWidth : superSize.width
        let height = superSize.height == UIViewNoIntrinsicMetric ? 50 : superSize.height
        return CGSize(width: width, height: height)
    }
    var buttonWidth: CGFloat  = 0
    var minButtonWidth: CGFloat = 60
    
    func createSubview() {
        for view in subviews {
            view.removeFromSuperview()
        }
        
        // .withRenderingMode(.alwaysTemplate) can be set directly on assets, once we have them
        let button = UIButton(type: .custom)
        let icon = UIImage(named: "swipe-action-save", in: Bundle.wmf, compatibleWith: nil)
        let selectedIcon = UIImage(named: "swipe-action-unsave", in: Bundle.wmf, compatibleWith: nil)
        button.setImage(icon?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setImage(selectedIcon?.withRenderingMode(.alwaysTemplate), for: .selected)
        button.titleLabel?.numberOfLines = 1
        button.contentEdgeInsets = UIEdgeInsetsMake(0, 14, 0, 14)
        button.backgroundColor = .clear
        insertSubview(button, at: 0)
        self.button = button
        
        backgroundColor = button.backgroundColor
        buttonWidth = max(minButtonWidth, button.intrinsicContentSize.width)
        setNeedsLayout()
    }
    
    fileprivate var theme: Theme = Theme.standard
    
    public func apply(theme: Theme) {
        button.imageView?.tintColor = theme.colors.secondaryText
    }

}

public enum BatchEditingState {
    case none
    case open
    case cancelled
    case inactive // swipe action is open
}

public enum BatchEditToolbarActionType {
    case update, addToList, unsave, delete
        
    public func action(with target: Any?) -> BatchEditToolbarAction {
        var title: String = "Update"
        var type: BatchEditToolbarActionType = .update
        switch self {
        case .addToList:
            title = "Add to list"
            type = .addToList
        case .unsave:
            title = "Un-save"
            type = .unsave
        case .delete:
            title = "Delete"
            type = .delete
        default:
            break
        }
        let button = UIBarButtonItem(title: title, style: .plain, target: target, action: #selector(ActionDelegate.didPerformBatchEditToolbarAction(_:)))
        return BatchEditToolbarAction(title: title, type: type, button: button, target: target)
    }
}

public class BatchEditToolbarAction: UIAccessibilityCustomAction {
    let title: String
    public let type: BatchEditToolbarActionType
    public let button: UIBarButtonItem
    
    public init(title: String, type: BatchEditToolbarActionType, button: UIBarButtonItem, target: Any?) {
        self.title = title
        self.type = type
        self.button = button
        let selector = button.action ?? #selector(ActionDelegate.didPerformBatchEditToolbarAction(_:))
        super.init(name: title, target: target, selector: selector)
    }
}

public protocol BatchEditableCell: NSObjectProtocol {
    var batchEditingState: BatchEditingState { get set }
    var batchEditingTranslation: CGFloat { get set }
    var batchEditSelectView: BatchEditSelectView { get }
    func layoutIfNeeded() // call to layout views after setting batch edit translation
    var isSelected: Bool { get set } // selection has to be reset on cancel
}

