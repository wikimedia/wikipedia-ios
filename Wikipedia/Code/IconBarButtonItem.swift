import UIKit
import WMF

class IconBarButtonItem: UIBarButtonItem {
    
    private var theme: Theme?

    convenience init(iconName: String, target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        self.init(iconName: iconName, target: target, action: action, for: controlEvents, iconInsets: .zero)
    }
    
    convenience init(iconName: String, target: Any?, action: Selector, for controlEvents: UIControl.Event, iconInsets: UIEdgeInsets) {
        let image = UIImage(named: iconName)
        let customView = UIButton(type: .system)
        customView.setImage(image, for: .normal)
        customView.addTarget(target, action: action, for: controlEvents)
        var deprecatedCustomView = customView as DeprecatedButton
        deprecatedCustomView.deprecatedAdjustsImageWhenDisabled = false
        if iconInsets != .zero { deprecatedCustomView.deprecatedImageEdgeInsets = iconInsets }
        self.init(customView: customView)
    }
    
    convenience init(image: UIImage?, iconInsets: UIEdgeInsets = .zero, menu: UIMenu) {
        
        let customView = UIButton(type: .system)
        customView.setImage(image, for: .normal)
        var deprecatedCustomView = customView as DeprecatedButton
        deprecatedCustomView.deprecatedAdjustsImageWhenDisabled = false
        if iconInsets != .zero {
            deprecatedCustomView.deprecatedImageEdgeInsets = iconInsets
        }
        
        customView.menu = menu
        customView.showsMenuAsPrimaryAction = true
        
        self.init(customView: customView)
    }

    @objc convenience init(systemName: String, target: Any?, action: Selector, for controlEvent: UIControl.Event = .primaryActionTriggered) {
        self.init(systemName: systemName, target: target, action: action, for: controlEvent)
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
