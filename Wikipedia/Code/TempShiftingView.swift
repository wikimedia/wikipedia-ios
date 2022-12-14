import Foundation

class TempShiftingView: SetupView, CustomNavigationViewShiftingSubview {
    let order: Int
    let color: UIColor
    
    var contentHeight: CGFloat {
        return label.frame.height
    }
    
    func shift(amount: CGFloat) -> ShiftingStatus {

        var didChangeHeight = false
        
        // content
        
        // Cool example of last item only collapsing to a certain amount
        // let heightOffset = order == 2 ? min(0, max((-label.frame.height/2), scrollAmount)) : min(0, max(-label.frame.height, scrollAmount))
        
        let heightOffset = min(0, max(-label.frame.height, amount))
        
        if (self.equalHeightToContentConstraint?.constant ?? 0) != heightOffset {
            self.equalHeightToContentConstraint?.constant = heightOffset
            didChangeHeight = true
        }
        
        if !didChangeHeight {
            return .shifted((heightOffset * -1))
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
