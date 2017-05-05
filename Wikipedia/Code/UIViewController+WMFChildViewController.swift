import Foundation
import Masonry

extension UIViewController {
    /// Embeds a view controller's view in a container view ensuring the container view expands vertically as needed to encompass any AutoLayout changes to the embedded view which affect its height.
    ///
    /// - Parameters:
    ///   - childController: Controller whose view will be embedded in containerView
    ///   - containerView: View to which childController's view will be added as a subview
    public func wmf_add(childController: UIViewController!, andConstrainToEdgesOfContainerView containerView: UIView!) {
        wmf_add(childController:childController, withContainerView: containerView, constraints: { make in
            _ = make?.top.bottom().leading().and().trailing().equalTo()(containerView)
        })
    }

    fileprivate func wmf_add(childController: UIViewController, withContainerView containerView: UIView, constraints: ((MASConstraintMaker?) -> Void)!){
        guard
            let childView = childController.view
            else{
                assertionFailure("Expected child controller view")
                return
        }
        wmf_configureForDynamicHeight(childView: childView, containerView: containerView)
        addChildViewController(childController)
        containerView.addSubview(childView)
        childController.view.mas_makeConstraints(constraints)
        childController.didMove(toParentViewController: self)
    }

    /// Configures the container to expand vertically dynamically to encompass the height of the controller's view even if the controller's view's height changes as a result of AutoLayout changes. Details: http://stackoverflow.com/a/35431534/135557
    ///
    /// - Parameters:
    ///   - childView: View to be added to containerView's view hierarchy (not by this function). childView's height must be defined in terms of its subviews' contraints - ie it should not have a fixed height constraint, but should be configured such that the storyboard doesn't complain about any missing constraints. This is similiar to how you use Autolayout with UIScrollView.
    ///   - containerView:  View to which childView will be added as a subview (not by this function)
    fileprivate func wmf_configureForDynamicHeight(childView: UIView, containerView: UIView){
        childView.translatesAutoresizingMaskIntoConstraints = false
        let containerViewHeight = containerView.constraints.first(where: {constraint in
            return (constraint.firstAttribute == .height)
        })
        containerViewHeight?.isActive = false
    }
}
