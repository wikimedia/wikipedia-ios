import Foundation

class ShiftingNavigationBarView: SetupView, CustomNavigationViewShiftingSubview {
    let order: Int
    
    var contentHeight: CGFloat {
        return bar.frame.height
    }
    
    func shift(amount: CGFloat) -> ShiftingStatus {
        
        var didChangeHeight = false
        
        let limitedShiftAmount = max(0, min(amount, bar.frame.height))
        
        if (self.equalHeightToContentConstraint?.constant ?? 0) != -limitedShiftAmount {
            self.equalHeightToContentConstraint?.constant = -limitedShiftAmount
            didChangeHeight = true
        }
        
        if !didChangeHeight {
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
    
    init(order: Int) {
        self.order = order
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
