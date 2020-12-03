import UIKit
class IconBarButtonItem: UIBarButtonItem {
    
    private var theme: Theme?
    
    @objc convenience init(iconName: String, target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        self.init(iconName: iconName, target: target, action: action, for: controlEvents, iconInsets: .zero)
    }
    
    @objc convenience init(iconName: String, target: Any?, action: Selector, for controlEvents: UIControl.Event, iconInsets: UIEdgeInsets) {
        let image = UIImage(named: iconName)
        let customView = UIButton(type: .system)
        customView.setImage(image, for: .normal)
        customView.addTarget(target, action: action, for: controlEvents)
        customView.adjustsImageWhenDisabled = false
        if iconInsets != .zero { customView.imageEdgeInsets = iconInsets }
        self.init(customView: customView)
    }
    
    override var isEnabled: Bool {
        get {
            return super.isEnabled
        } set {
            super.isEnabled = newValue
            
            if let theme = theme {
                apply(theme: theme)
            }
        }
    }
}

extension IconBarButtonItem: Themeable {
    public func apply(theme: Theme) {
        self.theme = theme
        if let customView = customView as? UIButton {
            customView.tintColor = isEnabled ? theme.colors.link : theme.colors.disabledLink
        } else {
            tintColor = isEnabled ? theme.colors.link : theme.colors.disabledLink
        }
    }
}
