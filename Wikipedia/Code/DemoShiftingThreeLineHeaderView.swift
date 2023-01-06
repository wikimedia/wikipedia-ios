import UIKit

class DemoShiftingThreeLineHeaderView: ShiftingTopView, Themeable {

    private(set) var theme: Theme

    private lazy var headerView: ThreeLineHeaderView = {
        let view = ThreeLineHeaderView()
        view.topSmallLine.text = "Test 1"
        view.middleLargeLine.text = "Test 2"
        view.bottomSmallLine.text = "Test 3"
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var topConstraint: NSLayoutConstraint?

    init(shiftOrder: Int, theme: Theme) {
        self.theme = theme
        super.init(shiftOrder: shiftOrder)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setup() {
        super.setup()

        addSubview(headerView)

        let top = headerView.topAnchor.constraint(equalTo: topAnchor)
        let bottom = bottomAnchor.constraint(equalTo: headerView.bottomAnchor)
        let leading = headerView.leadingAnchor.constraint(equalTo: leadingAnchor)
        let trailing = trailingAnchor.constraint(equalTo: headerView.trailingAnchor)

        NSLayoutConstraint.activate([
            top,
            bottom,
            leading,
            trailing
        ])

        self.topConstraint = top
        clipsToBounds = true
        apply(theme: theme)
    }

    // MARK: Overrides
    
    override var contentHeight: CGFloat {
        return headerView.frame.height
    }

    private var isFullyHidden: Bool {
       return -(topConstraint?.constant ?? 0) == contentHeight
    }

    override func shift(amount: CGFloat) -> ShiftingTopView.AmountShifted {

        let limitedShiftAmount = max(0, min(amount, contentHeight))

        let percent = limitedShiftAmount / contentHeight
        alpha = 1.0 - percent

        if (self.topConstraint?.constant ?? 0) != -limitedShiftAmount {
            self.topConstraint?.constant = -limitedShiftAmount
        }

        return limitedShiftAmount
    }

    // MARK: Themeable
    
    func apply(theme: Theme) {
        self.theme = theme
        backgroundColor = theme.colors.paperBackground
        headerView.apply(theme: theme)
    }
}
