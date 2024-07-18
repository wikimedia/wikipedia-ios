import Foundation

extension WMFBarButtonItemPopoverMessageViewController: Themeable {
    public func apply(theme: Theme) {
        view.backgroundColor = theme.colors.paperBackground
        titleLabel.textColor = theme.colors.primaryText
        messageLabel.textColor = theme.colors.secondaryText
    }
}
