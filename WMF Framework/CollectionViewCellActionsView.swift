import Foundation

public class Action: UIAccessibilityCustomAction {
    let icon: UIImage?
    let confirmationIcon: UIImage?
    public let type: ActionType
    public let indexPath: IndexPath

    public init(accessibilityTitle: String, icon: UIImage?, confirmationIcon: UIImage?, type: ActionType, indexPath: IndexPath, target: Any?, selector: Selector) {
        self.icon = icon
        self.confirmationIcon = confirmationIcon
        self.type = type
        self.indexPath = indexPath
        super.init(name: accessibilityTitle, target: target, selector: selector)
    }
}

@objc public protocol ActionDelegate: NSObjectProtocol {
    @objc func availableActions(at indexPath: IndexPath) -> [Action]
    @objc func didPerformAction(_ action: Action) -> Bool
    @objc func willPerformAction(_ action: Action) -> Bool
    @objc optional func didPerformBatchEditToolbarAction(_ action: BatchEditToolbarAction, completion: @escaping (Bool) -> Void)
    @objc optional var availableBatchEditToolbarActions: [BatchEditToolbarAction] { get }
}

public enum ActionType {
    case delete, save, unsave, share
    
    private struct Icon {
        static let delete = UIImage(named: "swipe-action-delete", in: Bundle.wmf, compatibleWith: nil)
        static let save = UIImage(named: "swipe-action-save", in: Bundle.wmf, compatibleWith: nil)
        static let unsave = UIImage(named: "swipe-action-unsave", in: Bundle.wmf, compatibleWith: nil)
        static let share = UIImage(named: "swipe-action-share", in: Bundle.wmf, compatibleWith: nil)
    }

    public func action(with target: Any?, indexPath: IndexPath) -> Action {
        switch self {
        case .delete:
            return Action(accessibilityTitle: CommonStrings.deleteActionTitle, icon: Icon.delete, confirmationIcon: nil, type: .delete, indexPath: indexPath, target: target, selector: #selector(ActionDelegate.willPerformAction(_:)))
        case .save:
            return Action(accessibilityTitle: CommonStrings.saveTitle, icon: Icon.save, confirmationIcon: Icon.unsave, type: .save, indexPath: indexPath, target: target, selector: #selector(ActionDelegate.willPerformAction(_:)))
        case .unsave:
            return Action(accessibilityTitle: CommonStrings.accessibilitySavedTitle, icon: Icon.unsave, confirmationIcon: Icon.save, type: .unsave, indexPath: indexPath, target: target, selector: #selector(ActionDelegate.willPerformAction(_:)))
        case .share:
            return Action(accessibilityTitle: CommonStrings.shareActionTitle, icon: Icon.share, confirmationIcon: nil, type: .share, indexPath: indexPath, target: target, selector: #selector(ActionDelegate.willPerformAction(_:)))
        }
    }
}

public class ActionsView: SizeThatFitsView, Themeable {
    fileprivate let minButtonWidth: CGFloat = 60
    var maximumWidth: CGFloat = 0
    var buttonWidth: CGFloat  = 0
    var buttons: [UIButton] = []
    var needsSubviews = true
    
    public var theme = Theme.standard
    
    internal var actions: [Action] = [] {
        didSet {
            activatedIndex = NSNotFound
            needsSubviews = true
        }
    }
    
    fileprivate var activatedIndex = NSNotFound
    func expand(_ action: Action) {
        guard let index = actions.firstIndex(of: action) else {
            return
        }
        bringSubviewToFront(buttons[index])
        activatedIndex = index
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
        if apply {
            if size.width > 0 && needsSubviews {
                createSubviews(for: actions)
                needsSubviews = false
            }
            let isRTL = effectiveUserInterfaceLayoutDirection == .rightToLeft
            if activatedIndex == NSNotFound {
                let numberOfButtons = CGFloat(subviews.count)
                let buttonDelta = min(size.width, maximumWidth) / numberOfButtons
                var x: CGFloat = isRTL ? size.width - buttonWidth : 0
                for button in buttons {
                    button.frame = CGRect(x: x, y: 0, width: buttonWidth, height: size.height)
                    if isRTL {
                        x -= buttonDelta
                    } else {
                        x += buttonDelta
                    }
                }
            } else {
                var x: CGFloat = isRTL ? size.width : 0 - (buttonWidth * CGFloat(buttons.count - 1))
                for button in buttons {
                    button.clipsToBounds = true
                    if button.tag == activatedIndex {
                        button.frame = CGRect(origin: .zero, size: CGSize(width: size.width, height: size.height))
                    } else {
                        button.frame = CGRect(x: x, y: 0, width: buttonWidth, height: size.height)
                        x += buttonWidth
                    }
                }
            }
        }
        let width = superSize.width == UIView.noIntrinsicMetric ? maximumWidth : superSize.width
        let height = superSize.height == UIView.noIntrinsicMetric ? 50 : superSize.height
        return CGSize(width: width, height: height)
    }
    
    func createSubviews(for actions: [Action]) {
        for view in subviews {
            view.removeFromSuperview()
        }
        buttons = []
        
        var maxButtonWidth: CGFloat = 0
        
        for (index, action) in actions.enumerated() {
            let button = UIButton(type: .custom)
            button.setImage(action.icon, for: .normal)
            button.titleLabel?.numberOfLines = 1
            var deprecatedButton = button as DeprecatedButton
            deprecatedButton.deprecatedContentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
            button.tag = index
            switch action.type {
            case .delete:
                button.backgroundColor = theme.colors.destructive
            case .share:
                button.backgroundColor = theme.colors.secondaryAction
            case .save:
                button.backgroundColor = theme.colors.link
            case .unsave:
                button.backgroundColor = theme.colors.link
            }
            button.imageView?.tintColor = .white
            button.addTarget(self, action: #selector(willPerformAction(_:)), for: .touchUpInside)
            maxButtonWidth = max(maxButtonWidth, button.intrinsicContentSize.width)
            insertSubview(button, at: 0)
            buttons.append(button)
        }

        backgroundColor = buttons.last?.backgroundColor
        buttonWidth = max(minButtonWidth, maxButtonWidth)
        maximumWidth = buttonWidth * CGFloat(subviews.count)
        setNeedsLayout()
    }

    public weak var delegate: ActionDelegate?
    
    private var activeSender: UIButton?
    
    @objc func willPerformAction(_ sender: UIButton) {
        activeSender = sender
        let action = actions[sender.tag]
        _ = delegate?.willPerformAction(action)
    }
    
    func updateConfirmationImage(for action: Action, completion: @escaping () -> Bool) -> Bool {
        if let image = action.confirmationIcon {
            activeSender?.setImage(image, for: .normal)
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
                _ = completion()
            }
        } else {
            return completion()
        }
        return true
    }
    
    public func apply(theme: Theme) {
        self.theme = theme
        backgroundColor = theme.colors.baseBackground
    }
}
