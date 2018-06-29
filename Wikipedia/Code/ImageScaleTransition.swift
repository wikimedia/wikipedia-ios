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
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let toViewController = transitionContext.viewController(forKey: .to),
            let fromViewController = transitionContext.viewController(forKey: .from)
            else {
                return
        }
        let containerView = transitionContext.containerView
        let toFinalFrame = transitionContext.finalFrame(for: toViewController)
        toViewController.view.frame = toFinalFrame
        containerView.insertSubview(toViewController.view, belowSubview: fromViewController.view)
        
        guard let fromImageView = fromImageView, let toImageView = toImageView else {
            transitionContext.completeTransition(true)
            return
        }
        
        if toImageView.image == nil {
            toImageView.image = fromImageView.image
        }
        toViewController.view.layoutIfNeeded()
        
        let fromFrame = containerView.convert(fromImageView.frame, from: fromImageView.superview)
        let toFrame = containerView.convert(toImageView.frame, from: toImageView.superview)
        let deltaX = toFrame.midX - fromFrame.midX
        let deltaY = toFrame.midY - fromFrame.midY
        let scaleX = toFrame.size.width / fromFrame.size.width
        let scaleY = toFrame.size.height / fromFrame.size.height
        let scale = CGAffineTransform(scaleX: scaleX, y: scaleY)
        let delta = CGAffineTransform(translationX: deltaX, y: deltaY)
        let transform = scale.concatenating(delta)
        
        toViewController.view.transform = transform.inverted()
        
        let duration = self.transitionDuration(using: transitionContext)
        UIView.animateKeyframes(withDuration: duration, delay: 0, options: .allowUserInteraction, animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1, animations: {
                fromViewController.view.transform = transform
                toViewController.view.transform = CGAffineTransform.identity
            })
            UIView.addKeyframe(withRelativeStartTime: 0.33, relativeDuration: 0.67, animations: {
                fromViewController.view.alpha = 0
            })
        }) { (finished) in
            transitionContext.completeTransition(true)
            fromViewController.view.alpha = 1
            fromViewController.view.transform = CGAffineTransform.identity
        }
        
        
        
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
