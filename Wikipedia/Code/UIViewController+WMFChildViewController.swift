import Foundation
import WMF

extension UIViewController {
    /// Embeds a view controller's view in a container view ensuring the VC's view is constrained to the edges of the given view
    ///
    /// - Parameters:
    ///   - childController: Controller whose view will be embedded in containerView
    ///   - containerView: View to which childController's view will be added as a subview
    @objc public func wmf_add(childController: UIViewController?, andConstrainToEdgesOfContainerView containerView: UIView, belowSubview: UIView? = nil) {
        guard let childController = childController else {
            return
        }
        addChild(childController)
        containerView.wmf_addSubview(childController.view, withConstraintsToEdgesWithInsets: .zero, priority: .required, belowSubview: belowSubview)
        childController.didMove(toParent: self)
    }
}
