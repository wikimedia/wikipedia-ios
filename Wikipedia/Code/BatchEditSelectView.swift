import UIKit

public class BatchEditSelectView: SizeThatFitsView, Themeable {
    public var theme = Theme.standard
    public func apply(theme: Theme) {
        self.theme = theme
    }
    
    fileprivate var multiSelectIndicator: UIImageView?
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        createSubview()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public var isSelected: Bool = false {
        didSet {
            updateMultiSelectIndicatorImage()
        }
    }

    public var isSelectionDisabled: Bool = false {
        didSet {
            updateMultiSelectIndicatorImage()
        }
    }

    public var selectedImage: UIImage? {
        didSet {
            updateMultiSelectIndicatorImage()
        }
    }
    
    fileprivate func updateMultiSelectIndicatorImage() {
        guard !isSelectionDisabled else {
            multiSelectIndicator?.image = UIImage(named: "selection-disabled", in: Bundle.main, compatibleWith: nil)
            multiSelectIndicator?.tintColor = theme.colors.midBackground
            return
        }
        multiSelectIndicator?.image = isSelected ? (selectedImage ?? theme.multiSelectIndicatorImage) : UIImage(named: "unselected", in: Bundle.main, compatibleWith: nil)
    }
    
    public override var frame: CGRect {
        didSet {
            setNeedsLayout()
        }
    }
    
    public static let fixedWidth: CGFloat = 60
    
    public override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let superSize = super.sizeThatFits(size, apply: apply)
        let width = superSize.width == UIView.noIntrinsicMetric ? BatchEditSelectView.fixedWidth : superSize.width
        if (apply) {
            multiSelectIndicator?.frame = CGRect(x: 0, y: 0, width: width, height: size.height)
        }
        let height = superSize.height == UIView.noIntrinsicMetric ? 50 : superSize.height
        return CGSize(width: width, height: height)
    }
    
    fileprivate func createSubview() {
        for view in subviews {
            view.removeFromSuperview()
        }
        
        let multiSelectIndicator = UIImageView()
        multiSelectIndicator.backgroundColor = .clear
        insertSubview(multiSelectIndicator, at: 0)
        multiSelectIndicator.contentMode = .center
        self.multiSelectIndicator = multiSelectIndicator
        updateMultiSelectIndicatorImage()

        backgroundColor = multiSelectIndicator.backgroundColor
        setNeedsLayout()
    }
}

public enum EditingState: Int {
    case unknown // pre-init state, nil delegate state
    case empty // collection view is empty
    case none // initial state
    case open // batch editing pane is open
    case closed // batch editing pane is closed
    case swiping // swipe action is open
    case editing // user is editing text
    case cancelled // user pressed cancel bar button
    case done // user pressed done bar button
    
    var tag: Int {
        return self.rawValue
    }
}

public enum BatchEditToolbarActionType {
    case update, addTo, addToList, moveTo, unsave, remove, delete
        
    public func action(with target: Any?) -> BatchEditToolbarAction {
        var title: String = CommonStrings.updateActionTitle
        var type: BatchEditToolbarActionType = .update
        switch self {
        case .moveTo:
            title = CommonStrings.moveToActionTitle
            type = .moveTo
        case .addTo:
            title = CommonStrings.addToActionTitle
            type = .addTo
        case .addToList:
            title = CommonStrings.addToReadingListShortActionTitle
            type = .addTo
        case .unsave:
            title = CommonStrings.shortUnsaveTitle
            type = .unsave
        case .delete:
            title = CommonStrings.deleteActionTitle
            type = .delete
        case .remove:
            title = CommonStrings.removeActionTitle
            type = .remove
        default:
            break
        }
        return BatchEditToolbarAction(title: title, type: type, target: target)
    }
}

public class BatchEditToolbarAction: UIAccessibilityCustomAction {
    let title: String
    public let type: BatchEditToolbarActionType
    
    public init(title: String, type: BatchEditToolbarActionType, target: Any?) {
        self.title = title
        self.type = type
        super.init(name: title, target: target, selector: #selector(ActionDelegate.didPerformBatchEditToolbarAction(_:completion:)))
    }
}

public protocol BatchEditableCell: NSObjectProtocol {
    var isBatchEditing: Bool { get set }
    var isBatchEditable: Bool { get set }
    var batchEditSelectView: BatchEditSelectView? { get }
    func layoutIfNeeded() // call to layout views after setting batch edit translation
}

