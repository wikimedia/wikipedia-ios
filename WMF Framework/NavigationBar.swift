import UIKit

public class SetupView: UIView {
    // MARK - Initializers
    // Don't override these initializers, use setup() instead
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    open func setup() {
        
    }
}

public class NavigationBar: SetupView {
    fileprivate let statusBarUnderlay: UIView =  UIView()
    fileprivate let bar: UINavigationBar = UINavigationBar()
    fileprivate let underBarView: UIView = UIView()
    fileprivate let shadow: UIView = UIView()
    
    override open func setup() {
        super.setup()
        statusBarUnderlay.translatesAutoresizingMaskIntoConstraints = false
        bar.translatesAutoresizingMaskIntoConstraints = false
        underBarView.translatesAutoresizingMaskIntoConstraints = false
        shadow.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(statusBarUnderlay)
        addSubview(bar)
        addSubview(underBarView)
        addSubview(shadow)
        
        bar.delegate = self
        
        let topAnchorForBarTopConstraint: NSLayoutYAxisAnchor
        if #available(iOSApplicationExtension 11.0, *) {
            topAnchorForBarTopConstraint = safeAreaLayoutGuide.topAnchor
        } else {
            topAnchorForBarTopConstraint = topAnchor
        }
        
        let topConstraint = topAnchor.constraint(equalTo: statusBarUnderlay.topAnchor)
        let bottomConstraint = topAnchorForBarTopConstraint.constraint(equalTo: statusBarUnderlay.bottomAnchor)
        let leadingConstraint = leadingAnchor.constraint(equalTo: statusBarUnderlay.leadingAnchor)
        let trailingConstraint = trailingAnchor.constraint(equalTo: statusBarUnderlay.trailingAnchor)
        addSubview(statusBarUnderlay)
        addConstraints([topConstraint, bottomConstraint, leadingConstraint, trailingConstraint])
        
        let barTopConstraint = topAnchorForBarTopConstraint.constraint(equalTo: bar.topAnchor)
        let barLeadingConstraint = leadingAnchor.constraint(equalTo: bar.leadingAnchor)
        let barTrailingConstraint = trailingAnchor.constraint(equalTo: bar.trailingAnchor)
        addConstraints([barTopConstraint, barLeadingConstraint, barTrailingConstraint])
        
        let underBarTopConstraint = bar.bottomAnchor.constraint(equalTo: underBarView.topAnchor)
        let underBarLeadingConstraint = leadingAnchor.constraint(equalTo: underBarView.leadingAnchor)
        let underBarTrailingConstraint = trailingAnchor.constraint(equalTo: underBarView.trailingAnchor)
        addConstraints([underBarTopConstraint, underBarLeadingConstraint, underBarTrailingConstraint])

        let shadowTopConstraint = underBarView.bottomAnchor.constraint(equalTo: shadow.topAnchor)
        let shadowLeadingConstraint = leadingAnchor.constraint(equalTo: shadow.leadingAnchor)
        let shadowTrailingConstraint = trailingAnchor.constraint(equalTo: shadow.trailingAnchor)
        let shadowBottomConstraint = bottomAnchor.constraint(equalTo: shadow.bottomAnchor)
        addConstraints([shadowTopConstraint, shadowLeadingConstraint, shadowTrailingConstraint, shadowBottomConstraint])
        
        let shadowHeightConstraint = shadow.heightAnchor.constraint(equalToConstant: 0.5)
        shadow.addConstraint(shadowHeightConstraint)
    }
    
    @objc public var navigationItem: UINavigationItem = UINavigationItem() {
        didSet {
            let back = UINavigationItem()
            bar.setItems([back, navigationItem], animated: false)
        }
    }
}

extension NavigationBar: Themeable {
    public func apply(theme: Theme) {
        backgroundColor = .clear
        
        statusBarUnderlay.backgroundColor = theme.colors.chromeBackground

        bar.setBackgroundImage(theme.navigationBarBackgroundImage, for: .default)
        bar.titleTextAttributes = theme.navigationBarTitleTextAttributes
        bar.isTranslucent = false
        bar.barTintColor = theme.colors.chromeBackground
        bar.shadowImage = #imageLiteral(resourceName: "transparent-pixel")
        bar.tintColor = theme.colors.chromeText
        
        underBarView.backgroundColor = theme.colors.chromeBackground
        
        shadow.backgroundColor = theme.colors.shadow
    }
}

extension NavigationBar: UINavigationBarDelegate {
    public func navigationBar(_ navigationBar: UINavigationBar, shouldPop item: UINavigationItem) -> Bool {
        return false
    }
}
