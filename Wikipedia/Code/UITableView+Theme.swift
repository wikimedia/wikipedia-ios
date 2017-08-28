import UIKit
import WMF

// Only use this for SSTableViews where the header and footer aren't easily accessible or updatable with a call to [UITableView reloadData]
extension UITableView {
    @objc public func wmf_applyThemeToHeadersAndFooters(_ theme: Theme) {
        wmf_recursivelyApply(theme: theme, isInHeaderOrFooter: false)
    }
}

extension UITableViewHeaderFooterView {
    @objc(wmf_applyTheme:)
    public func wmf_apply(theme: Theme) {
        wmf_recursivelyApply(theme: theme, isInHeaderOrFooter: true)
    }
}

extension UIView {
    fileprivate func wmf_recursivelyApply(theme: Theme, isInHeaderOrFooter: Bool) {
        for subview in subviews {
            if let headerOrFooter = subview as? UITableViewHeaderFooterView {
                headerOrFooter.contentView.backgroundColor = theme.colors.baseBackground
                headerOrFooter.wmf_recursivelyApply(theme: theme, isInHeaderOrFooter: true)
            } else if isInHeaderOrFooter, let label = subview as? UILabel {
                label.textColor = theme.colors.secondaryText
            } else if let _ = subview as? UITableViewCell {
                continue
            } else {
                subview.wmf_recursivelyApply(theme: theme, isInHeaderOrFooter: isInHeaderOrFooter)
            }
        }
    }
}


