import Foundation

public struct CollectionViewCellAction: Equatable {
    let title: String
    let icon: UIImage?
    public let type: CollectionViewCellActionType
    
    public static func ==(lhs: CollectionViewCellAction, rhs: CollectionViewCellAction) -> Bool {
        return lhs.title == rhs.title && lhs.icon == rhs.icon && lhs.type == rhs.type
    }
}

public enum CollectionViewCellActionType {
    case delete, save, unsave, share
    
    public var action: CollectionViewCellAction {
        switch self {
        case .delete:
            return CollectionViewCellAction(title: CommonStrings.deleteActionTitle, icon: nil, type: .delete)
        case .save:
            return CollectionViewCellAction(title: CommonStrings.shortSaveTitle, icon: nil, type: .save)
        case .unsave:
            return CollectionViewCellAction(title: CommonStrings.shortUnsaveTitle, icon: nil, type: .unsave)
        case .share:
            return CollectionViewCellAction(title: CommonStrings.shareActionTitle, icon: nil, type: .share)
        }
    }
}

public protocol CollectionViewSwipeToEditDelegate: NSObjectProtocol {
    func didPerformAction(_ action: CollectionViewCellAction, at indexPath: IndexPath)
    
    func primaryActions(for indexPath: IndexPath) -> [CollectionViewCellAction]
    func secondaryActions(for indexPath: IndexPath) -> [CollectionViewCellAction]
}

public protocol ActionsViewDelegate: NSObjectProtocol {
    func didPerformAction(_ action: CollectionViewCellAction)
}

public class CollectionViewCellActionsView: SizeThatFitsView {
    var maximumWidth: CGFloat = 0
    var buttonWidth: CGFloat  = 0
    var buttons: [UIButton] = []
    
    public var theme = Theme.standard
    
    var actions: [CollectionViewCellAction] = [] {
        didSet {
            createSubviews(for: self.actions)
        }
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
            let numberOfButtons = CGFloat(subviews.count)
            let buttonDelta = bounds.size.width / numberOfButtons
            let buttonWidth = max(self.buttonWidth, buttonDelta)
            let isRTL = semanticContentAttribute == .forceRightToLeft
            let buttons = isRTL ? self.buttons.reversed() : self.buttons
            var x: CGFloat = 0
            for button in buttons {
                button.frame = CGRect(x: x, y: 0, width: buttonWidth, height: bounds.height)
                x += buttonDelta
            }
        }
        let width = superSize.width == UIViewNoIntrinsicMetric ? maximumWidth : superSize.width
        let height = superSize.height == UIViewNoIntrinsicMetric ? 50 : superSize.height
        return CGSize(width: width, height: height)
    }
    
    func createSubviews(for actions: [CollectionViewCellAction]) {
        for view in subviews {
            view.removeFromSuperview()
        }
        buttons = []
        
        var maxButtonWidth: CGFloat = 0
        
        for (index, action) in actions.enumerated() {
            let button = UIButton(type: .custom)
            button.setTitle(action.title, for: .normal)
            button.titleLabel?.numberOfLines = 1
            button.contentEdgeInsets = UIEdgeInsetsMake(0, 14, 0, 14)
            button.tag = index
            
            switch (action.type) {
            case .delete:
                button.backgroundColor = theme.colors.destructive
            case .share:
                button.backgroundColor = theme.colors.secondaryAction
            case .save:
                button.backgroundColor = theme.colors.link
            case .unsave:
                button.backgroundColor = theme.colors.link
            }
            button.addTarget(self, action: #selector(didPerformAction(_:)), for: .touchUpInside)
            maxButtonWidth = max(maxButtonWidth, button.intrinsicContentSize.width)
            insertSubview(button, at: 0)
            buttons.append(button)
        }
        
        buttonWidth = maxButtonWidth
        maximumWidth = maxButtonWidth * CGFloat(subviews.count)
        setNeedsLayout()
    }

    public weak var delegate: ActionsViewDelegate?
    
    @objc func didPerformAction(_ sender: UIButton) {
        let action = actions[sender.tag]
        delegate?.didPerformAction(action)
    }
    
}
