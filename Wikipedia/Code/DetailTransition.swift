import UIKit

protocol DetailTransitionSourceProviding {
    var detailTransitionSourceRect: CGRect? { get }
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
        
        let totalHeight = containerView.bounds.size.height
        let tabBar = self.detailSourceViewController.tabBarController?.tabBar
        let tabBarSnapshot: UITabBar?
        if let tb = tabBar {
            tabBarSnapshot = UITabBar(frame: tb.frame)
            var selectedItem: UITabBarItem? = nil
            let copiedItems: [UITabBarItem]? = tb.items?.compactMap { (item: UITabBarItem) -> UITabBarItem in
                let copiedItem = UITabBarItem(title: item.title, image: item.image, selectedImage: item.selectedImage)
                copiedItem.badgeValue = item.badgeValue
                copiedItem.apply(theme: theme)
                if item === tb.selectedItem {
                    selectedItem = copiedItem
                }
                return copiedItem
            }
            tabBarSnapshot?.items = copiedItems
            tabBarSnapshot?.apply(theme: theme)
            tabBarSnapshot?.selectedItem = selectedItem
        } else {
            tabBarSnapshot = nil
        }
        
        let tabBarDeltaY = totalHeight - (tabBar?.frame.minY ?? totalHeight)
        let tabBarHiddenTransform = CGAffineTransform(translationX: 0, y: tabBarDeltaY)
        if let tb = tabBar, let tbs = tabBarSnapshot {
            tabBar?.alpha = 0
            tbs.alpha = 1
            tbs.frame = CGRect(x: 0, y: containerView.frame.height - tb.frame.height, width: tb.frame.width, height: tb.frame.height) // hack, it's already positioned off screen here
            if isEnteringDetail {
                tbs.transform = .identity
            } else {
                tbs.transform = tabBarHiddenTransform
            }
            containerView.addSubview(tbs)
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
            if let tbs = tabBarSnapshot {
                if isEnteringDetail {
                    tbs.transform = tabBarHiddenTransform
                } else {
                    tbs.transform = .identity
                }
            }
        }) { (finished) in
            if let tbs = tabBarSnapshot {
                tbs.transform = .identity
                tbs.removeFromSuperview()
            }
            tabBar?.alpha = 1
            backgroundView.removeFromSuperview()
            toSnapshot.removeFromSuperview()
            fromSnapshot.removeFromSuperview()
            transitionContext.completeTransition(true)
        }
    }
    
}

