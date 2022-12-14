import Foundation

class ShiftingNavigationBarView: SetupView, CustomNavigationViewShiftingSubview {
    let order: Int
    
    var contentHeight: CGFloat {
        return bar.frame.height
    }
    
    private let reappearOnScrollUp: Bool
    
    private var lastReappearAmount: CGFloat?
    private var isCollapsed = false
    private var lastAmount: CGFloat = 0
    private var amountWhenDirectionChanged: CGFloat = 0
    private var goingUp = false {
        didSet {
            if oldValue != goingUp {
                if lastAmount < 0 { // clear out if bouncing at top
                    amountWhenDirectionChanged = 0
                } else {
                    amountWhenDirectionChanged = lastAmount
                }
            }
        }
    }
    
    func shift(amount: CGFloat) -> ShiftingStatus {
        
        goingUp = lastAmount > amount
        
        // Adjust number for sensitivity
        let flickingUp = (lastAmount - amount) > 8
        
        if reappearOnScrollUp {
            // If flicking up and fully collapsed, animate nav bar back in
            if flickingUp && isCollapsed {
                lastAmount = amount
                equalHeightToContentConstraint?.constant = 0
                setNeedsLayout()
                UIView.animate(withDuration: 0.2) {
                    self.layoutIfNeeded()
                }
                isCollapsed = false
                return .shifting
            } else if goingUp && isCollapsed {
                lastAmount = amount
                return .shifting
            }
            
        }
        
        // adjust amount to start from when direction last changed, if needed
        let adjustedAmount = reappearOnScrollUp && amount > 0 ? amount - (amountWhenDirectionChanged) : amount
        
        let limitedShiftAmount = max(0, min(adjustedAmount, contentHeight))
        
        let percent = limitedShiftAmount / contentHeight
        
        // Shrink items within
        let barScaleTransform = CGAffineTransformMakeScale(1.0 - (percent/2), 1.0 - (percent/2))
        for subview in self.bar.subviews {
            for subview in subview.subviews {
                subview.transform = barScaleTransform
            }
        }
        
        alpha = 1.0 - percent
        
        // Shift Y placement
        if (self.equalHeightToContentConstraint?.constant ?? 0) != -limitedShiftAmount {
            self.equalHeightToContentConstraint?.constant = -limitedShiftAmount
            isCollapsed = false
        } else {
            if -(self.equalHeightToContentConstraint?.constant ?? 0) == contentHeight {
                isCollapsed = true
            }
        }
        
        lastAmount = amount

        if isCollapsed {
            return .shifted(limitedShiftAmount)
        } else {
            return .shifting
        }
    }
    
    private var equalHeightToContentConstraint: NSLayoutConstraint?
    private lazy var bar: UINavigationBar = {
        let bar = UINavigationBar(frame: .zero)
        bar.translatesAutoresizingMaskIntoConstraints = false
        return bar
    }()
    
    init(order: Int, reappearOnScrollUp: Bool = true) {
        self.order = order
        self.reappearOnScrollUp = reappearOnScrollUp
        // self.color = color
        super.init(frame: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setup() {
        super.setup()
        
        translatesAutoresizingMaskIntoConstraints = false
        // backgroundColor = color

        let item = UINavigationItem(title: "Testing!")
        bar.setItems([item], animated: false)
        addSubview(bar)
        
        // top defaultHigh priority allows label to slide upward
        // height 999 priority allows parent view to shrink
        let top = bar.topAnchor.constraint(equalTo: topAnchor)
        top.priority = .defaultHigh
        let bottom = bottomAnchor.constraint(equalTo: bar.bottomAnchor)
        let leading = bar.leadingAnchor.constraint(equalTo: leadingAnchor)
        let trailing = trailingAnchor.constraint(equalTo: bar.trailingAnchor)
        
        let height = heightAnchor.constraint(equalTo: bar.heightAnchor)
        height.priority = UILayoutPriority(999)
        self.equalHeightToContentConstraint = height
        
        NSLayoutConstraint.activate([
            top,
            bottom,
            leading,
            trailing,
            height
        ])
        
        clipsToBounds = true
    }
}
