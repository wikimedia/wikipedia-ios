
import Foundation

class ReplyTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        guard let updateVC = dismissed as? TalkPageUpdateViewController else {
            return nil
        }
        return FadePopAnimator(duration: 1.0, interactionController: updateVC.swipeInteractionController)
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadePushAnimator(duration: 1.0)
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        
        let replyPresentationController = ReplyPresentationController(presentedViewController: presented, presenting: presenting)
        if let talkPageUpdatedVC = presented as? TalkPageUpdateViewController {
            talkPageUpdatedVC.swipeInteractionController?.backgroundView = replyPresentationController.backgroundView
        }
        return replyPresentationController
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
            
        guard let animator = animator as? FadePopAnimator,
            let interactionController = animator.interactionController,
            interactionController.interactionInProgress else {
            return nil
        }
        return interactionController
            
    }
}
