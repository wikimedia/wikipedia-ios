import Foundation

protocol DiffRevisionAnimating: AnyObject {
    var embeddedViewController: UIViewController? { get }
    var animateDirection: DiffRevisionTransition.Direction? { get set }
}

class DiffRevisionTransition : NSObject, UIViewControllerAnimatedTransitioning {
    
    static let duration = TimeInterval(0.3)
    
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

        guard let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from),
        let toView = transitionContext.view(forKey: UITransitionContextViewKey.to),
        let toVC = (transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) as? DiffRevisionAnimating) else {
            
            transitionContext.completeTransition(false)
            return
        }
        
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
        
        UIView.animate(withDuration: DiffRevisionTransition.duration, delay: 0.0, options: .curveEaseInOut, animations: {
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
        return DiffRevisionTransition.duration
    }
}
