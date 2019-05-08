
import Foundation
import UIKit

final class ReplyPresentationController: UIPresentationController {
    
    let backgroundView: UIView = UIView(frame: .zero)
    private var tapGestureRecognizer: UITapGestureRecognizer!
    
    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismiss))
        
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        backgroundView.isUserInteractionEnabled = true
        backgroundView.addGestureRecognizer(tapGestureRecognizer)
        backgroundView.backgroundColor = .clear
    }
    
    
    override var frameOfPresentedViewInContainerView: CGRect {
        
        guard let containerView = containerView else {
            return .zero
        }
        
        return CGRect(origin: CGPoint(x: 0, y: containerView.frame.height / 2), size: CGSize(width: containerView.frame.width, height: containerView.frame.height / 2))
    }
    
    override func dismissalTransitionWillBegin() {
        
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) in
            self.backgroundView.alpha = 0
        }, completion: { (UIViewControllerTransitionCoordinatorContext) in
            self.backgroundView.removeFromSuperview()
        })
    }
    
    override func presentationTransitionWillBegin() {
        
        backgroundView.alpha = 0
        containerView?.addSubview(backgroundView)
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) in
            self.backgroundView.alpha = 1
        }, completion: nil)
    }
    
    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        
        presentedView?.frame = frameOfPresentedViewInContainerView
        
        if let containerView = containerView {
            backgroundView.frame = containerView.bounds
        }
    }
    
    @objc func dismiss() {
        self.presentedViewController.dismiss(animated: true, completion: nil)
    }
    
}
