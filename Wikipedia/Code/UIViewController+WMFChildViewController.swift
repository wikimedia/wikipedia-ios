import Foundation

extension UIView {
    
    /// Configures the container to expand vertically dynamically to encompass the height of the controller's view even if the controller's view's height changes as a result of AutoLayout changes. Details: http://stackoverflow.com/a/35431534/135557
    ///
    /// - Parameters:
    ///   - childView: View to be added to containerView's view hierarchy (not by this function). childView's height must be defined in terms of its subviews' contraints - ie it should not have a fixed height constraint, but should be configured such that the storyboard doesn't complain about any missing constraints. This is similiar to how you use Autolayout with UIScrollView.
    ///   - containerView:  View to which childView will be added as a subview (not by this function)
    fileprivate func wmf_deactivateHeightConstraint() {
        let containerViewHeight = constraints.first(where: {constraint in
            return (constraint.firstAttribute == .height)
        })
        containerViewHeight?.isActive = false
    }
    
    @objc public func wmf_addHeightDeterminingSubviewWithConstraintsToEdges(_ subview: UIView) {
        wmf_addHeightDeterminingSubview(subview, withConstraintsToEdgesWithInsets: .zero)
    }
    
    @objc public func wmf_addHeightDeterminingSubview(_ subview: UIView, withConstraintsToEdgesWithInsets insets: UIEdgeInsets, priority: UILayoutPriority = .required) {
        wmf_deactivateHeightConstraint()
        subview.translatesAutoresizingMaskIntoConstraints = false
        subview.frame = UIEdgeInsetsInsetRect(bounds, insets)
        addSubview(subview)
        let topConstraint = topAnchor.constraint(equalTo: subview.topAnchor, constant: insets.top)
        topConstraint.priority = priority
        let bottomConstraint = bottomAnchor.constraint(equalTo: subview.bottomAnchor, constant: insets.bottom)
        topConstraint.priority = priority
        let leftConstraint = leftAnchor.constraint(equalTo: subview.leftAnchor, constant: insets.left)
        topConstraint.priority = priority
        let rightConstraint = rightAnchor.constraint(equalTo: subview.rightAnchor, constant: insets.right)
        topConstraint.priority = priority
        addConstraints([topConstraint, bottomConstraint, leftConstraint, rightConstraint])
    }
}

extension UIViewController {
    /// Embeds a view controller's view in a container view ensuring the container view expands vertically as needed to encompass any AutoLayout changes to the embedded view which affect its height.
    ///
    /// - Parameters:
    ///   - childController: Controller whose view will be embedded in containerView
    ///   - containerView: View to which childController's view will be added as a subview
    @objc public func wmf_add(childController: UIViewController!, andConstrainToEdgesOfContainerView containerView: UIView!) {
        containerView.wmf_addHeightDeterminingSubviewWithConstraintsToEdges(childController.view)
    }
}
