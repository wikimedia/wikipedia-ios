
import Foundation

class ReplyTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    
    var lastSeenView: UIView?
    var additionalPresentationAnimations: (() -> Void)?
    var additionalDismissalAnimations: (() -> Void)?
    var topChromeHeight: CGFloat = 75
    var navigationBarHeight: CGFloat = 0
    var topChromeExtraOffset: CGFloat = 0
    private let duration = 0.5
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        guard let updateVC = dismissed as? TalkPageUpdateViewController,
        let lastSeenView = lastSeenView else {
            assertionFailure("Unexpected setup to animate dismissal.")
            return nil
        }
        return ReplyDismissAnimator(duration: duration, interactionController: updateVC.swipeInteractionController, lastSeenView: lastSeenView, additionalAnimations: additionalDismissalAnimations)
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        guard let lastSeenView = lastSeenView else {
            assertionFailure("Need last seen view to animate presentation.")
            return nil
        }
        
        return ReplyPresentAnimator(duration: duration, lastSeenView: lastSeenView, additionalAnimations: additionalPresentationAnimations, topChromeHeight: topChromeHeight, navigationBarHeight: navigationBarHeight, topChromeExtraOffset: topChromeExtraOffset)
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        
        let replyPresentationController = ReplyPresentationController(presentedViewController: presented, presenting: presenting, topChromeHeight: topChromeHeight, navigationBarHeight: navigationBarHeight)
        
        if let presenting = presenting as? TalkPageReplyListViewController {
            replyPresentationController.dismissDelegate = presenting
        }
        
        return replyPresentationController
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
            
        guard let animator = animator as? ReplyDismissAnimator,
            let interactionController = animator.interactionController,
            interactionController.interactionInProgress else {
            return nil
        }
        return interactionController
            
    }
}
