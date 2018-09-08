import UIKit

@objc public extension UIView {
    fileprivate func wmf_deactivateHeightConstraint() {
        let containerViewHeight = constraints.first(where: {constraint in
            return (constraint.firstAttribute == .height)
        })
        containerViewHeight?.isActive = false
    }
    
    /// Configures the view to expand vertically dynamically to encompass the height of the subview even if the subview's height changes as a result of AutoLayout changes. Details: http://stackoverflow.com/a/35431534/135557
    @objc public func wmf_addHeightDeterminingSubviewWithConstraintsToEdges(_ subview: UIView) {
        wmf_addHeightDeterminingSubview(subview, withConstraintsToEdgesWithInsets: .zero)
    }
    
    @objc public func wmf_addHeightDeterminingSubview(_ subview: UIView, withConstraintsToEdgesWithInsets insets: UIEdgeInsets, priority: UILayoutPriority = .required) {
        wmf_deactivateHeightConstraint()
        subview.translatesAutoresizingMaskIntoConstraints = false
        wmf_addSubview(subview, withConstraintsToEdgesWithInsets: insets, priority: priority)
    }
    
    @objc public func wmf_addSubviewWithConstraintsToEdges(_ subview: UIView) {
        wmf_addSubview(subview, withConstraintsToEdgesWithInsets: .zero)
    }
    
    @objc public func wmf_addSubview(_ subview: UIView, withConstraintsToEdgesWithInsets insets: UIEdgeInsets, priority: UILayoutPriority = .required) {
        addSubview(subview)
        wmf_addConstraintsToEdgesOfView(subview, withInsets: insets, priority: priority)
    }

    // Until we drop iOS 10 and can use NSDirectionalEdgeInsets, assume insets.left == leading & insets.right == trailing
    @objc public func wmf_addConstraintsToEdgesOfView(_ subview: UIView, withInsets insets: UIEdgeInsets = .zero, priority: UILayoutPriority = .required) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        subview.frame = bounds.inset(by: insets)
        let topConstraint = subview.topAnchor.constraint(equalTo: topAnchor, constant: insets.top)
        topConstraint.priority = priority
        let bottomConstraint = bottomAnchor.constraint(equalTo: subview.bottomAnchor, constant: insets.bottom)
        bottomConstraint.priority = priority
        let leftConstraint = subview.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left)
        leftConstraint.priority = priority
        let rightConstraint = trailingAnchor.constraint(equalTo: subview.trailingAnchor, constant: insets.right)
        rightConstraint.priority = priority
        addConstraints([topConstraint, bottomConstraint, leftConstraint, rightConstraint])
    }
}
