import UIKit

class ShiftingNavigationBarView: ShiftingTopView, Themeable {

    private let navigationItems: [UINavigationItem]
    
    private var topConstraint: NSLayoutConstraint?

    private lazy var bar: UINavigationBar = {
        let bar = UINavigationBar()
        bar.translatesAutoresizingMaskIntoConstraints = false
        return bar
    }()

    init(shiftOrder: Int, navigationItems: [UINavigationItem]) {
        self.navigationItems = navigationItems
        super.init(shiftOrder: shiftOrder)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setup() {
        super.setup()

        bar.setItems(navigationItems, animated: false)
        addSubview(bar)

        let top = bar.topAnchor.constraint(equalTo: topAnchor)
        let bottom = bottomAnchor.constraint(equalTo: bar.bottomAnchor)
        let leading = bar.leadingAnchor.constraint(equalTo: leadingAnchor)
        let trailing = trailingAnchor.constraint(equalTo: bar.trailingAnchor)

        NSLayoutConstraint.activate([
            top,
            bottom,
            leading,
            trailing
        ])

        self.topConstraint = top

        clipsToBounds = true
    }

    // MARK: Overrides
    
    override var contentHeight: CGFloat {
        return bar.frame.height
    }

    private var isFullyHidden: Bool {
       return -(topConstraint?.constant ?? 0) == contentHeight
    }

    override func shift(amount: CGFloat) -> ShiftingTopView.AmountShifted {

        // Only allow navigation bar to move just out of frame
        let limitedShiftAmount = max(0, min(amount, contentHeight))

        // Shrink and fade
        let percent = limitedShiftAmount / contentHeight
        let barScaleTransform = CGAffineTransformMakeScale(1.0 - (percent/2), 1.0 - (percent/2))
        for subview in self.bar.subviews {
            for subview in subview.subviews {
                subview.transform = barScaleTransform
            }
        }
        alpha = 1.0 - percent

        // Shift Y placement
        if (self.topConstraint?.constant ?? 0) != -limitedShiftAmount {
            self.topConstraint?.constant = -limitedShiftAmount
        }

        return limitedShiftAmount
    }

    // MARK: Themeable
    
    func apply(theme: Theme) {
        bar.setBackgroundImage(theme.navigationBarBackgroundImage, for: .default)
        bar.titleTextAttributes = theme.navigationBarTitleTextAttributes
        bar.isTranslucent = false
        bar.barTintColor = theme.colors.chromeBackground
        bar.shadowImage = theme.navigationBarShadowImage
        bar.tintColor = theme.colors.chromeText
    }
}
