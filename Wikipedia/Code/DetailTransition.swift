import UIKit

protocol DetailTransitionSourceProviding {
    var detailTransitionSourceRect: CGRect? { get }
    var tabBarSnapshotImage: UIImage? { get }
}

@objc(WMFImageScaleTransitionProviding)
protocol ImageScaleTransitionProviding {
    var imageScaleTransitionView: UIImageView? { get }
    @objc optional func prepareForIncomingImageScaleTransition() // before views load
    @objc(prepareViewsForIncomingImageScaleTransitionWithImageView:)
    optional func prepareViewsForIncomingImageScaleTransition(with imageView: UIImageView?) // after views load
    @objc optional func prepareForOutgoingImageScaleTransition()
}

class DetailTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    let detailSourceViewController: DetailTransitionSourceProviding & ViewController
    
    var theme: Theme {
        return detailSourceViewController.theme
    }
    
    required init(detailSourceViewController: DetailTransitionSourceProviding & ViewController, incomingImageScaleTransitionProvider: ImageScaleTransitionProviding?, outgoingImageScaleTransitionProvider: ImageScaleTransitionProviding?) {
        self.detailSourceViewController = detailSourceViewController
        incomingImageScaleTransitionProvider?.prepareForIncomingImageScaleTransition?()
        outgoingImageScaleTransitionProvider?.prepareForOutgoingImageScaleTransition?()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let toViewController = transitionContext.viewController(forKey: .to),
            let fromViewController = transitionContext.viewController(forKey: .from)
        else {
            transitionContext.completeTransition(false)
            return
        }
        
        let maybeToISP = (toViewController as? UITabBarController)?.selectedViewController ?? toViewController
        let maybeFromISP = (fromViewController as? UITabBarController)?.selectedViewController ?? fromViewController
        
        let isEnteringDetail: Bool = maybeFromISP === detailSourceViewController
        let containerView = transitionContext.containerView
        
        let toFrame = transitionContext.finalFrame(for: toViewController)
        toViewController.view.frame = toFrame
        containerView.addSubview(toViewController.view)
        
        let fromImageView: UIImageView?
        let toImageView: UIImageView?
        let isImageScaleTransitioning: Bool
        
        if let fromISTP = maybeFromISP as? ImageScaleTransitionProviding, let toISTP = maybeToISP as? ImageScaleTransitionProviding {
            fromImageView = fromISTP.imageScaleTransitionView
            toImageView = toISTP.imageScaleTransitionView
            isImageScaleTransitioning = fromImageView != nil && toImageView != nil && fromImageView?.image != nil
            if isImageScaleTransitioning {
                toISTP.prepareViewsForIncomingImageScaleTransition?(with: fromImageView)
            }
        } else {
            fromImageView = nil
            toImageView = nil
            isImageScaleTransitioning = false
        }
        
        let fromFrame = transitionContext.initialFrame(for: fromViewController)
        
        guard
            let toSnapshot = maybeToISP.view.snapshotView(afterScreenUpdates: true),
            let fromSnapshot = maybeFromISP.view.snapshotView(afterScreenUpdates: false)
        else {
            transitionContext.completeTransition(true)
            return
        }
        
        let backgroundView = UIView()
        backgroundView.backgroundColor = detailSourceViewController.theme.colors.paperBackground
        backgroundView.frame = CGRect(origin: .zero, size: containerView.bounds.size)
        containerView.addSubview(backgroundView)
        
        toSnapshot.frame = toFrame
        fromSnapshot.frame = fromFrame
        
        containerView.addSubview(fromSnapshot)
        
        if isEnteringDetail {
            containerView.insertSubview(toSnapshot, belowSubview: fromSnapshot)
        } else {
            containerView.addSubview(toSnapshot)
        }
        
        let transform: CGAffineTransform
        
        if isImageScaleTransitioning, let detailImageView = isEnteringDetail ? toImageView : fromImageView, let sourceImageView = isEnteringDetail ? fromImageView : toImageView {
            let sourceFrame = containerView.convert(sourceImageView.frame, from: sourceImageView.superview)
            let detailFrame = containerView.convert(detailImageView.frame, from: detailImageView.superview)
            let deltaX = detailFrame.midX - sourceFrame.midX
            let deltaY = detailFrame.midY - sourceFrame.midY
            let scaleX = detailFrame.size.width / sourceFrame.size.width
            let scaleY = detailFrame.size.height / sourceFrame.size.height
            if abs(scaleX - scaleY) > 0.1 || max(scaleX, scaleY) > 1.5 || min(scaleX, scaleY) < 0.5 {
                let scale = CGAffineTransform(scaleX: 1.25, y: 1.25)
                let delta = CGAffineTransform(translationX: deltaX, y: deltaY)
                transform = scale.concatenating(delta)
            } else {
                let scale = CGAffineTransform(scaleX: scaleX, y: scaleY)
                let delta = CGAffineTransform(translationX: deltaX, y: deltaY)
                transform = scale.concatenating(delta)
            }
        } else if let rect = detailSourceViewController.detailTransitionSourceRect {
            let scaleUp = CGAffineTransform(scaleX: 1.25, y: 1.25)
            let translation = CGAffineTransform(translationX: detailSourceViewController.view.bounds.midX - rect.midX, y:  detailSourceViewController.view.bounds.midY - rect.midY)
            transform = scaleUp.concatenating(translation)
        } else {
            transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
        }
        
        if isEnteringDetail {
            toSnapshot.transform = transform.inverted()
        } else {
            toSnapshot.alpha = 0
            toSnapshot.transform = transform
        }
        
        // tab bar handling
        var detailSourceTabBar: UITabBar?
        var detailSourceTabBarSnapshotImageView: UIImageView?
        if let tabBarSnapshotImage = detailSourceViewController.tabBarSnapshotImage,
           let tabBar = detailSourceViewController.tabBarController?.tabBar {
            let imageView = UIImageView(image: tabBarSnapshotImage)
            containerView.addSubview(imageView)
            let yValue = isEnteringDetail ? containerView.frame.height - imageView.frame.height : containerView.frame.height
            imageView.frame = CGRect(x: 0, y: yValue, width: imageView.frame.width, height: imageView.frame.height)
            detailSourceTabBarSnapshotImageView = imageView
            detailSourceTabBar = tabBar
            detailSourceTabBar?.alpha = 0
        }
        
        let duration = self.transitionDuration(using: transitionContext)
        UIView.animateKeyframes(withDuration: duration, delay: 0, options: [], animations: {
            toSnapshot.transform = .identity
            if isEnteringDetail {
                fromSnapshot.alpha = 0
                fromSnapshot.transform = transform
            } else {
                toSnapshot.alpha = 1
                fromSnapshot.transform = transform.inverted()
            }
            
            // tab bar handling
            if let detailSourceTabBar, let detailSourceTabBarSnapshotImageView {
                let oldFrame = detailSourceTabBarSnapshotImageView.frame
                let yValue = isEnteringDetail ? containerView.frame.height : containerView.frame.height - detailSourceTabBarSnapshotImageView.frame.height
                detailSourceTabBarSnapshotImageView.frame = CGRect(x: oldFrame.minX, y: yValue, width: oldFrame.width, height: oldFrame.height)
                detailSourceTabBar.alpha = 0
            }
            
            
        }) { (finished) in
            
            // tab bar handling
            if let detailSourceTabBar, let detailSourceTabBarSnapshotImageView {
                detailSourceTabBar.alpha = 1
                detailSourceTabBarSnapshotImageView.removeFromSuperview()
            }
            
            backgroundView.removeFromSuperview()
            toSnapshot.removeFromSuperview()
            fromSnapshot.removeFromSuperview()
            transitionContext.completeTransition(true)
        }
    }
    
}

