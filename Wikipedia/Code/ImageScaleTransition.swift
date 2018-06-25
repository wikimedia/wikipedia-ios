import UIKit

@objc(WMFImageScaleTransitionProviding)
protocol ImageScaleTransitionProviding {
    var imageScaleTransitionView: UIImageView? { get }
}

@objc(WMFImageScaleTransitionController)
class ImageScaleTransitionController: NSObject, UIViewControllerAnimatedTransitioning {
    let fromImageView: UIImageView?
    let toImageView: UIImageView?
    
    @objc(initWithFromImageView:toImageView:)
    init(fromImageView: UIImageView?, toImageView: UIImageView?) {
        self.fromImageView = fromImageView
        self.toImageView = toImageView
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let toViewController = transitionContext.viewController(forKey: .to)//,
            //let fromViewController = transitionContext.viewController(forKey: .from)
            else {
                return
        }
        let containerView = transitionContext.containerView
//        if let fromImageView = fromImageView {
//        }
//        if let toImageView = toImageView {
//
//        }
        let toFinalFrame = transitionContext.finalFrame(for: toViewController)
        toViewController.view.frame = toFinalFrame
        containerView.addSubview(toViewController.view)
        transitionContext.completeTransition(true)
        
    }
}


@objc(WMFImageScaleTransitionDelegate)
class ImageScaleTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    @objc static let shared = ImageScaleTransitionDelegate()
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard
            let to = presented as? ImageScaleTransitionProviding,
            let from = presenting as? ImageScaleTransitionProviding else {
            return nil
        }
        return ImageScaleTransitionController(fromImageView: from.imageScaleTransitionView, toImageView: to.imageScaleTransitionView)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }
}
