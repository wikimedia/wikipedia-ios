import Foundation
import WMF

extension UIViewController {
    /// Embeds a view controller's view in a container view ensuring the container view expands vertically as needed to encompass any AutoLayout changes to the embedded view which affect its height.
    ///
    /// - Parameters:
    ///   - childController: Controller whose view will be embedded in containerView
    ///   - containerView: View to which childController's view will be added as a subview
    @objc public func wmf_add(childController: UIViewController!, andConstrainToEdgesOfContainerView containerView: UIView!, belowSubview: UIView? = nil) {
        addChild(childController)
        containerView.wmf_addHeightDeterminingSubviewWithConstraintsToEdges(childController.view, belowSubview: belowSubview)
        childController.didMove(toParent: self)
    }
}
