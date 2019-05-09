
import Foundation

class ReplySwipeInteractionController: UIPercentDrivenInteractiveTransition {
    
    var interactionInProgress = false
    
    private var shouldCompleteTransition = false
    private weak var viewController: UIViewController!
    weak var dismissDelegate: ReplyDismissDelegate?
    
    weak var scrollView: UIScrollView! {
        didSet {
            prepareGestureRecognizer(in: scrollView)
        }
    }
    
    init(viewController: UIViewController) {
        super.init()
        self.viewController = viewController
    }
    
    private func prepareGestureRecognizer(in scrollView: UIScrollView) {
        scrollView.panGestureRecognizer.addTarget(self, action: #selector(handleGesture(_:)))
        
    }
    
    @objc func handleGesture(_ gestureRecognizer: UIPanGestureRecognizer) {

        let translation = gestureRecognizer.translation(in: gestureRecognizer.view!.superview!)
        var progress = (translation.y / 200)
        progress = CGFloat(fminf(fmaxf(Float(progress), 0.0), 1.0))
        
        switch gestureRecognizer.state {
            
        case .began:
            interactionInProgress = true
            viewController.dismiss(animated: true, completion: nil)
            
        case .changed:
            shouldCompleteTransition = progress > 0.5
            update(progress)
            
        case .cancelled:
            interactionInProgress = false
            cancel()
            
        case .ended:
            interactionInProgress = false
            if shouldCompleteTransition {
                dismissDelegate?.willDismiss()
                finish()
            } else {
                dismissDelegate?.cancelDismiss()
                cancel()
            }
        default:
            break
        }
    }
}
