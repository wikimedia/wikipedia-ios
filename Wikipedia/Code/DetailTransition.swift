import UIKit

protocol DetailTransitionSourceProviding {
    var detailTransitionSourceRect: CGRect? { get }
}

class DetailTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    let detailViewController: ViewController
    let detailSourceViewController: DetailTransitionSourceProviding & UIViewController
    
    required init(detailViewController: ViewController, detailSourceViewController: DetailTransitionSourceProviding & UIViewController) {
        self.detailViewController = detailViewController
        self.detailSourceViewController = detailSourceViewController
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
        
        let isEnteringDetail: Bool = toViewController === detailViewController
        let containerView = transitionContext.containerView

        let toFrame = transitionContext.finalFrame(for: toViewController)
        toViewController.view.frame = toFrame
        containerView.addSubview(toViewController.view)
        
        let fromFrame = transitionContext.initialFrame(for: fromViewController)
        
        guard
            let toSnapshot = toViewController.view.snapshotView(afterScreenUpdates: true),
            let fromSnapshot = fromViewController.view.snapshotView(afterScreenUpdates: false)
        else {
            transitionContext.completeTransition(true)
            return
        }
        
        let backgroundView = UIView()
        backgroundView.backgroundColor = detailViewController.theme.colors.paperBackground
        backgroundView.frame = CGRect(origin: .zero, size: containerView.bounds.size)
        containerView.addSubview(backgroundView)
        
        toSnapshot.frame = toFrame
        fromSnapshot.frame = fromFrame
        
        containerView.addSubview(fromSnapshot)
        
        if (isEnteringDetail) {
            containerView.insertSubview(toSnapshot, belowSubview: fromSnapshot)
        } else {
            containerView.addSubview(toSnapshot)
        }
        
        let transform: CGAffineTransform
        
        let scaleUp = CGAffineTransform(scaleX: 1.25, y: 1.25)
        if let rect = detailSourceViewController.detailTransitionSourceRect {
            let translation = CGAffineTransform(translationX: detailSourceViewController.view.bounds.midX - rect.midX, y:  detailSourceViewController.view.bounds.midY - rect.midY)
            transform = scaleUp.concatenating(translation)
        } else {
            transform = scaleUp
        }
        
        let totalHeight = containerView.bounds.size.height
        let tabBar = self.detailViewController.tabBarController?.tabBar
        let tabBarDeltaY = totalHeight - (tabBar?.frame.minY ?? totalHeight)
        let tabBarHiddenTransform = CGAffineTransform(translationX: 0, y: tabBarDeltaY)
        
        if isEnteringDetail {
            toSnapshot.transform = transform.inverted()
        } else {
            toSnapshot.alpha = 0
            toSnapshot.transform = transform
            tabBar?.transform = tabBarHiddenTransform
            tabBar?.isHidden = false
        }
        
        let duration = self.transitionDuration(using: transitionContext)
        UIView.animateKeyframes(withDuration: duration, delay: 0, options: [], animations: {
            if isEnteringDetail {
                tabBar?.transform = tabBarHiddenTransform
            } else {
                tabBar?.transform = .identity
            }
            toSnapshot.transform = .identity
            if isEnteringDetail {
                fromSnapshot.alpha = 0
                fromSnapshot.transform = transform
            } else {
                toSnapshot.alpha = 1
                fromSnapshot.transform = transform.inverted()
            }
        }) { (finished) in
            backgroundView.removeFromSuperview()
            toSnapshot.removeFromSuperview()
            fromSnapshot.removeFromSuperview()
            transitionContext.completeTransition(true)
            if isEnteringDetail {
                tabBar?.isHidden = true
            }
            tabBar?.transform = .identity
        }
    }
    
}

