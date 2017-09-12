import Foundation

public protocol Actionable {
    var swipeToEditController: CollectionViewSwipeToEditController? { get set }
}

public protocol Swipeable {

}

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

class CollectionViewCellActionsView: UIView {
    var cell: CollectionViewCell
    var maxActionWidth: CGFloat = 0
    
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
    
    init(frame: CGRect, cell: CollectionViewCell) {
        self.cell = cell
        super.init(frame: frame)
        
        self.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        self.isUserInteractionEnabled = false
    }
    
    func createSubviews(for actions: [CollectionViewCellAction]) {
        for view in self.subviews {
            view.removeFromSuperview()
        }
        
        var maxButtonWidth: CGFloat = 0
        
        for action in actions {
            let button = UIButton(type: .custom)
            button.setTitle(action.title, for: .normal)
            button.titleLabel?.numberOfLines = 0
            button.contentEdgeInsets = UIEdgeInsetsMake(0, 8, 0, 8)
            
            var didTapButton: Selector
            
            switch (action.type) {
            case .delete:
                didTapButton = #selector(didTapDelete)
            case .share:
                didTapButton = #selector(didTapShare)
            case .save:
                didTapButton = #selector(didTapSave)
            case .unsave:
                didTapButton = #selector(didTapUnsave)
            }
            
            button.addTarget(self, action: didTapButton, for: .touchUpInside)
            
            let wrapper = UIView(frame: .zero)
            wrapper.clipsToBounds = true
            wrapper.addSubview(button)
            self.addSubview(wrapper)
            wrapper.addSubview(button)
            
            // SWIPE: Adjust backgroundColor for action types.
            wrapper.backgroundColor = UIColor.cyan
            maxButtonWidth = max(maxButtonWidth, button.intrinsicContentSize.width)
        }
        
        maxActionWidth = maxButtonWidth * CGFloat(self.subviews.count)
    }
    
    @objc func didTapDelete() {
        print("didTapDelete")
    }
    
    @objc func didTapShare() {
        print("didTapShare")
    }
    
    @objc func didTapSave() {
        print("didTapShare")
    }
    
    @objc func didTapUnsave() {
        print("didTapUnsave")
        if let indexPath = cell.indexPathForActiveCell {
            delegate?.didTapUnsave(at: indexPath)
        }
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
    
    func action(from button: UIButton) -> CollectionViewCellAction {
        let index = button.tag
        return actions[index]
    }
    
    // MARK: - Swift rubbish
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
