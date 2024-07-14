import Foundation

extension WMFBarButtonItemPopoverMessageViewController: Themeable {
    public func apply(theme: Theme) {
        guard self.isViewLoaded else {
            return
        }
        
        view.backgroundColor = theme.colors.paperBackground
        titleLabel.textColor = theme.colors.primaryText
        messageLabel.textColor = theme.colors.secondaryText
    }
}
