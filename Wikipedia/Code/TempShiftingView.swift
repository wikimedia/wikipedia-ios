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
    
    func apply(theme: Theme) {
        
    }
}

class TempShiftingTalkPageHeaderView: SetupView, CustomNavigationViewShiftingSubview {
    let order: Int
    let viewModel: TalkPageViewModel
    private(set) var theme: Theme
    
    var contentHeight: CGFloat {
        return headerView.frame.height
    }
    
    private var isCollapsed = false
    
    func shift(amount: CGFloat) -> ShiftingStatus {
        
        print("sending in amount to talk header view: \(amount)")
        
        let limitedShiftAmount = max(0, min(amount, contentHeight))
        
        let percent = limitedShiftAmount / contentHeight
        alpha = 1.0 - percent
        
        if (self.equalHeightToContentConstraint?.constant ?? 0) != -limitedShiftAmount {
            self.equalHeightToContentConstraint?.constant = -limitedShiftAmount
        }
        
        if -(self.equalHeightToContentConstraint?.constant ?? 0) == contentHeight {
            isCollapsed = true
        }
        
        if isCollapsed {
            return .shifted(limitedShiftAmount)
        } else {
            return .shifting
        }
    }
    
    private var equalHeightToContentConstraint: NSLayoutConstraint?
    lazy var headerView: TalkPageHeaderView = {
        let view = TalkPageHeaderView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    init(order: Int, viewModel: TalkPageViewModel, theme: Theme) {
        self.order = order
        self.viewModel = viewModel
        self.theme = theme
        super.init(frame: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setup() {
        super.setup()
        
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(headerView)
        
        // top defaultHigh priority allows label to slide upward
        // height 999 priority allows parent view to shrink
        let top = headerView.topAnchor.constraint(equalTo: topAnchor)
        top.priority = .defaultHigh
        let bottom = bottomAnchor.constraint(equalTo: headerView.bottomAnchor)
        let leading = headerView.leadingAnchor.constraint(equalTo: leadingAnchor)
        let trailing = trailingAnchor.constraint(equalTo: headerView.trailingAnchor)
        
        let height = heightAnchor.constraint(equalTo: headerView.heightAnchor)
        height.priority = UILayoutPriority(999)
        self.equalHeightToContentConstraint = height
        
        NSLayoutConstraint.activate([
            top,
            bottom,
            leading,
            trailing,
            height
        ])
        
        headerView.configure(viewModel: viewModel, theme: theme)
        
        clipsToBounds = true
        apply(theme: theme)
    }
    
    func apply(theme: Theme) {
        self.theme = theme
        headerView.apply(theme: theme)
    }
}
