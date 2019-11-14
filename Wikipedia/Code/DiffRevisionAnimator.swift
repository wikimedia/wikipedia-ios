
import Foundation

protocol DiffRevisionAnimating: class {
    var embeddedViewController: UIViewController? { get }
    var animateDirection: DiffRevisionAnimator.Direction?  { get set }
}

class DiffRevisionAnimator : NSObject, UIViewControllerAnimatedTransitioning {
    
    enum Direction {
        case up
        case down
    }
    
    let direction: Direction
    
    init(direction: Direction) {
        self.direction = direction
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {

        let container = transitionContext.containerView

        guard let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from) else { return }
        guard let toView = transitionContext.view(forKey: UITransitionContextViewKey.to) else { return }
        guard let toVC = (transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) as? DiffRevisionAnimating) else { return }
        
        let fromEmbedVC = (transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) as? DiffRevisionAnimating)?.embeddedViewController
        toVC.animateDirection = direction

        toView.alpha = 0
        container.addSubview(toView)
        toView.frame = fromView.frame
        
        var oldFromEmbedVCFrame: CGRect?
        var newFromEmbedVCFrame: CGRect?
        
        if let fromFrame = fromEmbedVC?.view.frame {
            
            let newY = direction == .down ? fromFrame.minY - fromFrame.height : fromFrame.maxY
            newFromEmbedVCFrame = CGRect(x: fromFrame.minX, y: newY, width: fromFrame.width, height: fromFrame.height)
            
             oldFromEmbedVCFrame = fromFrame
        }
        
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {
            toView.alpha = 1
            
            if let newFromEmbedVCFrame = newFromEmbedVCFrame {
                fromEmbedVC?.view.frame = newFromEmbedVCFrame
            }
        }) { (finished) in
            if let oldFromEmbedVCFrame = oldFromEmbedVCFrame {
                fromEmbedVC?.view.frame = oldFromEmbedVCFrame
            }
            
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
}
