import Foundation

class ShiftingNavigationBarView: SetupView, CustomNavigationViewShiftingSubview {
    let order: Int
    private let navigationItems: [UINavigationItem]
    private let config: Config
    private weak var popDelegate: UIViewController? // Navigation back actions will be forwarded to this view controller
    
    var contentHeight: CGFloat {
        return bar.frame.height
    }
    
    struct Config {
        let reappearOnScrollUp: Bool
        let shiftOnScrollUp: Bool
        let needsProgressView: Bool
        
        init(reappearOnScrollUp: Bool = true, shiftOnScrollUp: Bool = true, needsProgressView: Bool = false) {
            self.reappearOnScrollUp = reappearOnScrollUp
            self.shiftOnScrollUp = shiftOnScrollUp
            self.needsProgressView = needsProgressView
        }
    }
    
    private lazy var progressView: UIProgressView = {
        let progressView = UIProgressView()
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressViewStyle = .bar
        progressView.trackTintColor = .clear
        progressView.progressTintColor = .blue // todo: theme
        return progressView
    }()
    
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
        
        guard config.shiftOnScrollUp else {
            return .shifted(0)
        }
        
        goingUp = lastAmount > amount
        
        // Adjust number for sensitivity
        let flickingUp = (lastAmount - amount) > 8
        
        if config.reappearOnScrollUp {
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
        let adjustedAmount = config.reappearOnScrollUp && amount > 0 ? amount - (amountWhenDirectionChanged) : amount
        
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
        bar.delegate = self
        return bar
    }()
    
    init(order: Int, config: Config, navigationItems: [UINavigationItem], popDelegate: UIViewController) {
        self.order = order
        self.config = config
        self.navigationItems = navigationItems
        self.popDelegate = popDelegate
        super.init(frame: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setup() {
        super.setup()
        
        translatesAutoresizingMaskIntoConstraints = false
        
        bar.setItems(navigationItems, animated: false)
        
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
        
        if config.needsProgressView {
            addSubview(progressView)
            NSLayoutConstraint.activate([
                progressView.leadingAnchor.constraint(equalTo: bar.leadingAnchor),
                progressView.trailingAnchor.constraint(equalTo: bar.trailingAnchor),
                progressView.bottomAnchor.constraint(equalTo: bar.bottomAnchor)
            ])
        }
        
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

extension ShiftingNavigationBarView: FakeProgressReceiving, FakeProgressDelegate {
    @objc public func setProgressHidden(_ hidden: Bool, animated: Bool) {
        let changes = {
            self.progressView.alpha = hidden ? 0 : 1
        }
        if animated {
            UIView.animate(withDuration: 0.2, animations: changes)
        } else {
            changes()
        }
    }
    
    @objc public func setProgress(_ progress: Float, animated: Bool) {
        progressView.setProgress(progress, animated: animated)
    }
    
    public var progress: Float {
        get {
            return progressView.progress
        }
        set {
            progressView.progress = newValue
        }
    }
}

extension ShiftingNavigationBarView: UINavigationBarDelegate {
    func navigationBar(_ navigationBar: UINavigationBar, shouldPop item: UINavigationItem) -> Bool {
        popDelegate?.navigationController?.popViewController(animated: true)
        return false
    }

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
