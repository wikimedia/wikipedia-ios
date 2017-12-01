import UIKit

public class SetupView: UIView {
    // MARK - Initializers
    // Don't override these initializers, use setup() instead
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    open func setup() {
        
    }
}

class Toolbar: SetupView {
//    override var intrinsicContentSize: CGSize {
//        return CGSize(width: UIViewNoIntrinsicMetric, height: 44)
//    }
}

class NavigationBar: SetupView {
    fileprivate let container: UIView = UIView()
    fileprivate var barHeight: CGFloat = 44
    
    override func setup() {
        super.setup()
        
        backgroundColor = UIColor.green
        
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor.orange
        addSubview(container)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let fullViewFrame = CGRect(origin: .zero, size: bounds.size)
        let containerFrame = UIEdgeInsetsInsetRect(fullViewFrame, layoutMargins)
        container.frame = containerFrame
    }
    
    override func layoutMarginsDidChange() {
        super.layoutMarginsDidChange()
        setNeedsLayout()
        invalidateIntrinsicContentSize()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        barHeight = traitCollection.verticalSizeClass == .compact ? 32 : 44
        setNeedsLayout()
        invalidateIntrinsicContentSize()
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: layoutMargins.top + barHeight)
    }
}
