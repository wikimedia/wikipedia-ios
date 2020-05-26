import UIKit

@objc public extension UIView {
    func addCenteredSubview(_ subview: UIView) {
        addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false
        let centerXConstraint = centerXAnchor.constraint(equalTo: subview.centerXAnchor)
        let centerYConstraint = centerYAnchor.constraint(equalTo: subview.centerYAnchor)
        NSLayoutConstraint.activate([centerXConstraint, centerYConstraint])
    }
    
    @objc func wmf_addSubviewWithConstraintsToEdges(_ subview: UIView) {
        wmf_addSubview(subview, withConstraintsToEdgesWithInsets: .zero)
    }
    
    @objc func wmf_addSubview(_ subview: UIView, withConstraintsToEdgesWithInsets insets: UIEdgeInsets, priority: UILayoutPriority = .required, belowSubview: UIView? = nil) {
        if let belowSubview = belowSubview {
            insertSubview(subview, belowSubview: belowSubview)
        } else {
            addSubview(subview)
        }
        wmf_addConstraintsToEdgesOfView(subview, withInsets: insets, priority: priority)
    }

    // Until we drop iOS 10 and can use NSDirectionalEdgeInsets, assume insets.left == leading & insets.right == trailing
    @objc func wmf_addConstraintsToEdgesOfView(_ subview: UIView, withInsets insets: UIEdgeInsets = .zero, priority: UILayoutPriority = .required) {
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
