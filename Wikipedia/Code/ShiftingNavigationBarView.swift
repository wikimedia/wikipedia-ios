import UIKit

class ShiftingNavigationBarView: ShiftingTopView, Themeable {

    private let navigationItems: [UINavigationItem]
    private weak var popDelegate: UIViewController? // Navigation back actions will be forwarded to this view controller
    
    private var topConstraint: NSLayoutConstraint?

    private lazy var bar: UINavigationBar = {
        let bar = UINavigationBar()
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.delegate = self
        return bar
    }()

    init(shiftOrder: Int, navigationItems: [UINavigationItem], popDelegate: UIViewController) {
        self.navigationItems = navigationItems
        self.popDelegate = popDelegate
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

// MARK: Themeable

extension ShiftingNavigationBarView: UINavigationBarDelegate {
    func navigationBar(_ navigationBar: UINavigationBar, shouldPop item: UINavigationItem) -> Bool {
        popDelegate?.navigationController?.popViewController(animated: true)
        return false
    }

    // Taken from NavigationBar.swift
    func navigationBar(_ navigationBar: UINavigationBar, didPop item: UINavigationItem) {
        // During iOS 14's long press to access back history, this function is called *after* the unneeded navigationItems have been popped off.
        // However, with our custom navBar the actual articleVC isn't changed. So we need to find the articleVC for the top navItem, and pop to it.
        // This should be in `shouldPop`, but as of iOS 14.0, `shouldPop` isn't called when long pressing a back button. Once this is fixed by Apple,
        // we should move this to `shouldPop` to improve animations. (Update: A bug tracker was filed w/ Apple, and this won't be fixed anytime soon.
        // Apple: "This is expected behavior. Due to side effects that many clients have in the shouldPop handler, we do not consult it when using the back
        // button menu. We instead recommend that you hide the back button when you wish to disallow popping past a particular point in the navigation stack.")
        if let topNavigationItem = navigationBar.items?.last,
           let navController = popDelegate?.navigationController,
           let tappedViewController = navController.viewControllers.first(where: {$0.navigationItem == topNavigationItem}) {
            popDelegate?.navigationController?.popToViewController(tappedViewController, animated: true)
        }
    }
}
