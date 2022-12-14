import Foundation

class TempShiftingView: SetupView, CustomNavigationViewShiftingSubview {
    let order: Int
    let color: UIColor
    
    var contentHeight: CGFloat {
        return label.frame.height
    }
    
    func shift(amount: CGFloat) -> ShiftingStatus {
        
        var didChangeHeight = false
        
        let limitedShiftAmount = max(0, min(amount, label.frame.height))
        
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
    private lazy var label: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()
    
    init(color: UIColor, order: Int) {
        self.order = order
        self.color = color
        super.init(frame: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setup() {
        super.setup()
        
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = color

        addSubview(label)
        
        // top defaultHigh priority allows label to slide upward
        // height 999 priority allows parent view to shrink
        let top = label.topAnchor.constraint(equalTo: topAnchor)
        top.priority = .defaultHigh
        let bottom = bottomAnchor.constraint(equalTo: label.bottomAnchor)
        let leading = label.leadingAnchor.constraint(equalTo: leadingAnchor)
        let trailing = trailingAnchor.constraint(equalTo: label.trailingAnchor)
        
        let height = heightAnchor.constraint(equalTo: label.heightAnchor)
        height.priority = UILayoutPriority(999)
        self.equalHeightToContentConstraint = height
        
        NSLayoutConstraint.activate([
            top,
            bottom,
            leading,
            trailing,
            height
        ])
        
        label.text = "I am a view!"
        
        clipsToBounds = true
    }
}
