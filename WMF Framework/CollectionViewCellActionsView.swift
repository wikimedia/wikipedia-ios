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

public protocol SwipeableDelegate: NSObjectProtocol {
    func didOpenActionPane(_ didOpen: Bool, at: IndexPath)
    func didPerformAction(_ sender: UIButton)
    func isArticleSaved(at indexPath: IndexPath) -> Bool
}

public class CollectionViewCellActionsView: UIView {
    
    var cell: ArticleCollectionViewCell
    var maximumWidth: CGFloat = 0
    public var theme = Theme.standard
    
    var actions: [CollectionViewCellAction] = [] {
        didSet {
            createSubviews(for: self.actions)
        }
    }
    
    var swipeType: CollectionViewCellSwipeType = .none {
        didSet {
            swipeType == .primary ? layoutPrimaryActions() : layoutSecondaryActions()
        }
    }
    
    init(frame: CGRect, cell: ArticleCollectionViewCell) {
        self.cell = cell
        super.init(frame: frame)
        
        self.isUserInteractionEnabled = false
    }
    
    func createSubviews(for actions: [CollectionViewCellAction]) {
        
        for view in self.subviews {
            view.removeFromSuperview()
        }
        
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
                button.backgroundColor = self.theme.colors.link
            }
            
            button.addTarget(self, action: #selector(didPerformAction(_:)), for: .touchUpInside)
            
            // Wrapper around each button.
            let wrapper = UIView(frame: .zero)
            wrapper.clipsToBounds = true
            wrapper.addSubview(button)
            self.addSubview(wrapper)
            maxButtonWidth = max(maxButtonWidth, button.intrinsicContentSize.width)
        }
        
        maximumWidth = maxButtonWidth * CGFloat(self.subviews.count)
    }
    
    public weak var delegate: SwipeableDelegate?
    
    @objc func didPerformAction(_ sender: UIButton) {
        delegate?.didPerformAction(sender)
    }
    
    func layoutPrimaryActions() {
        
        let numberOfButtonWrappers = self.subviews.count
        
        let buttonWrapperWidth = maximumWidth / CGFloat(numberOfButtonWrappers)
        var previousButtonWrapper: UIView?
        
        for buttonWrapper in self.subviews {
            
            if let button = buttonWrapper.subviews.first as? UIButton {
                
                var buttonWrapperFrame = CGRect(x: 0, y: self.frame.origin.y, width: buttonWrapperWidth, height: self.frame.height)
                
                button.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                
                let last = button.viewWithTag(numberOfButtonWrappers - 1)
                self.backgroundColor = last?.backgroundColor
                
                if numberOfButtonWrappers > 1 {
                    switch button.tag {
                    case 0:
                        previousButtonWrapper = buttonWrapper
                    case 1:
                        // Fallthrough?
                        if let previous = previousButtonWrapper {
                            buttonWrapperFrame.origin.x = previous.frame.origin.x + previous.frame.width
                            previousButtonWrapper = buttonWrapper
                        }
                    case 2:
                        if let previous = previousButtonWrapper {
                            buttonWrapperFrame.origin.x = previous.frame.origin.x + previous.frame.width
                            previousButtonWrapper = buttonWrapper
                        }
                    default:
                        break
                    }
                }
                
                buttonWrapper.frame = buttonWrapperFrame
                buttonWrapper.autoresizesSubviews = true
                buttonWrapper.backgroundColor = UIColor.clear
            }
        }
        
    }
    
    func layoutSecondaryActions() {
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
