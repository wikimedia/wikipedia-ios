import UIKit

class ShiftingNavigationBarView: ShiftingTopView, Themeable, Loadable {

    private let navigationItems: [UINavigationItem]
    private let hidesOnScroll: Bool
    private weak var popDelegate: UIViewController? // Navigation back actions will be forwarded to this view controller
    
    private var topConstraint: NSLayoutConstraint?

    private lazy var bar: UINavigationBar = {
        let bar = UINavigationBar()
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.delegate = self
        return bar
    }()
    
    // MARK: Loading bar properties
    
    private lazy var fakeProgressController: FakeProgressController = {
        let progressController = FakeProgressController(progress: self, delegate: self)
        progressController.delay = 0.0
        return progressController
    }()

    private lazy var progressView: UIProgressView = {
        let progressView = UIProgressView()
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressViewStyle = .bar
        return progressView
    }()
    
    // MARK: Tracking properties for reappearance upon flick up
    
    private var lastAmount: CGFloat = 0
    private var amountWhenDirectionChanged: CGFloat = 0
    private var scrollingUp = false
    
    init(shiftOrder: Int, navigationItems: [UINavigationItem], hidesOnScroll: Bool, popDelegate: UIViewController) {
        self.navigationItems = navigationItems
        self.hidesOnScroll = hidesOnScroll
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
        
        addSubview(progressView)
        
        NSLayoutConstraint.activate([
            top,
            bottom,
            leading,
            trailing,
            progressView.leadingAnchor.constraint(equalTo: bar.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: bar.trailingAnchor),
            progressView.bottomAnchor.constraint(equalTo: bar.bottomAnchor)
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
    
    private var isFullyShowing: Bool {
       return -(topConstraint?.constant ?? 0) == 0
    }

    override func shift(amount: CGFloat) -> ShiftingTopView.AmountShifted {
        
        defer {
            lastAmount = amount
        }
        
        // Early exit if navigation bar shouldn't move.
        guard hidesOnScroll else {
            return 0
        }

        // Calculate amountWhenDirectionChanged, so that new hiding offsets can begin from wherever user flicked up
        let oldScrollingUp = scrollingUp
        scrollingUp = lastAmount > amount

        if oldScrollingUp != scrollingUp {

            // Clear out if it's near the top...otherwise it throws off top bouncing calculations
            if amount <= contentHeight {
                amountWhenDirectionChanged = 0
            } else {

                if isFullyShowing || isFullyHidden { // If it is in the middle of collapsing, resetting this property thows things off. Only set change direction amount if it's already fully collapsed or expanded
                    amountWhenDirectionChanged = lastAmount
                }
            }
        }

        // Adjust constant for sensitivity
        let flickingUp = (lastAmount - amount) > 8

        // If flicking up and fully collapsed, animate nav bar back in
        if flickingUp && isFullyHidden {
            topConstraint?.constant = 0

            setNeedsLayout()
            UIView.animate(withDuration: 0.2) {
                self.alpha = 1.0
                let resetTransform = CGAffineTransform.identity
                for subview in self.bar.subviews {
                    for subview in subview.subviews {
                        subview.transform = resetTransform
                    }
                }
                self.layoutIfNeeded()
            }
            return contentHeight
        }

        // Various cases where it helps to bail early
        
        // Do not re-appear if slowly scrolling up when further down the scroll view. But when slowly going up near the top (amount <= contentHeight), allow it to go through and adjust height constraint.
        if scrollingUp && isFullyHidden && amount > contentHeight {
           return contentHeight
        }

        // If scrolling up and already showing, don't do anything.
        if scrollingUp && isFullyShowing {
            return contentHeight
        }

        // If scrolling down and fully collapsed, don't do anything
       if !scrollingUp && isFullyHidden {
           return contentHeight
       }

        var adjustedAmount = amount
        // Adjust shift amount to be against wherever direction last changed, if needed. This is so that bar can slowly disappear again when scrolling down further in the view after flicking to show it
        if amount > contentHeight {
            adjustedAmount = amount - amountWhenDirectionChanged
        }

        // Only allow navigation bar to move just out of frame
        let limitedShiftAmount = max(0, min(adjustedAmount, contentHeight))

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
        
        progressView.progressViewStyle = .bar
        progressView.trackTintColor = .clear
        progressView.progressTintColor = theme.colors.link
    }
    
    // MARK: Loadable
    
    func startLoading() {
        fakeProgressController.start()
    }

    func stopLoading() {
        fakeProgressController.stop()
    }
}

// MARK: UINavigationBarDelegate

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

// MARK: FakeProgressReceiving, FakeProgressDelegate

extension ShiftingNavigationBarView: FakeProgressReceiving, FakeProgressDelegate {
    func setProgressHidden(_ hidden: Bool, animated: Bool) {
        let changes = {
            self.progressView.alpha = hidden ? 0 : 1
        }
        if animated {
            UIView.animate(withDuration: 0.2, animations: changes)
        } else {
            changes()
        }
    }

    func setProgress(_ progress: Float, animated: Bool) {
        progressView.setProgress(progress, animated: animated)
    }

    var progress: Float {
        get {
            return progressView.progress
        }
        set {
            progressView.progress = newValue
        }
    }
}
