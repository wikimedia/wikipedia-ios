import UIKit
import WMF

// Only use this for SSTableViews where the header and footer aren't easily accessible or updatable with a call to [UITableView reloadData]
extension UITableView {
    public func wmf_applyThemeToHeadersAndFooters(_ theme: Theme) {
        wmf_recursivelyApply(theme: theme, to: self, isInHeaderOrFooter: false)

    }
    
    fileprivate func wmf_recursivelyApply(theme: Theme, to view: UIView, isInHeaderOrFooter: Bool) {
        for subview in view.subviews {
            if let headerOrFooter = subview as? UITableViewHeaderFooterView {
                headerOrFooter.contentView.backgroundColor = theme.colors.baseBackground
                wmf_recursivelyApply(theme: theme, to: headerOrFooter, isInHeaderOrFooter: true)
            } else if isInHeaderOrFooter, let label = subview as? UILabel {
                label.textColor = theme.colors.secondaryText
            } else if let _ = subview as? UITableViewCell {
                continue
            } else {
                wmf_recursivelyApply(theme: theme, to: subview, isInHeaderOrFooter: isInHeaderOrFooter)
            }
        }
    }
    
}


