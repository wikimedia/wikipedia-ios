import UIKit

/// A Themeable UIBarButtonItem with title text only
class TextBarButtonItem: UIBarButtonItem, Themeable {

    // MARK: - Properties

    private var theme: Theme?

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

    // MARK: - Lifecycle

    @objc convenience init(title: String, target: Any?, action: Selector?) {
        self.init(title: title, style: .plain, target: target, action: action)
    }

    // MARK: - Themeable

    public func apply(theme: Theme) {
        self.theme = theme
        if let customView = customView as? UIButton {
            customView.tintColor = isEnabled ? theme.colors.link : theme.colors.disabledLink
        } else {
            tintColor = isEnabled ? theme.colors.link : theme.colors.disabledLink
        }
    }

}
