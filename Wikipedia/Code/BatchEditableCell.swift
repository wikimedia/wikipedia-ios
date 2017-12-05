import UIKit

@objc public protocol BatchEditNavigationDelegate: NSObjectProtocol {
    func didChangeBatchEditingState(button: UIBarButtonItem, tag: Int)
    func didSetIsBatchEditToolbarVisible(_ isVisible: Bool)
    func createBatchEditToolbar(with items: [UIBarButtonItem], add: Bool)
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
    
    public weak var delegate: ActionDelegate?
    
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

public enum BatchEditActionType {
    case select
    
    public func action(with target: Any?, indexPath: IndexPath) -> BatchEditAction {
        switch self {
        case .select:
            let icon = UIImage(named: "swipe-action-save", in: Bundle.wmf, compatibleWith: nil)
            let confirmationIcon = UIImage(named: "swipe-action-unsave", in: Bundle.wmf, compatibleWith: nil)
            return BatchEditAction(accessibilityTitle: "Select", type: .select, icon: icon!, confirmationIcon: confirmationIcon!, at: indexPath, target: target, selector: #selector(ActionDelegate.didBatchSelect(_:)))
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

