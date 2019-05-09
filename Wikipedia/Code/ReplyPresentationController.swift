
import Foundation
import UIKit

protocol ReplyDismissDelegate: class {
    func willDismiss()
    func cancelDismiss()
}

final class ReplyPresentationController: UIPresentationController {
    
    var topChromeHeight: CGFloat
    var navigationBarHeight: CGFloat
    var spacing: CGFloat {
        get {
            return topChromeHeight + navigationBarHeight
        }
    }
    private var originalContainerViewBounds: CGRect?
    weak var dismissDelegate: ReplyDismissDelegate?
    
    init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?, topChromeHeight: CGFloat, navigationBarHeight: CGFloat) {
        
        self.topChromeHeight = topChromeHeight
        self.navigationBarHeight = navigationBarHeight
        
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }
    
    func containerViewFrame() -> CGRect {
        
        guard let originalContainerViewBounds = originalContainerViewBounds else {
            return .zero
        }
        
        let containerBounds = originalContainerViewBounds
        
        return CGRect(origin: CGPoint(x: 0, y: spacing), size: CGSize(width: containerBounds.width, height: containerBounds.height - spacing))
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        guard let originalContainerViewBounds = originalContainerViewBounds else {
            return
        }
        
        self.originalContainerViewBounds = CGRect(x: originalContainerViewBounds.minY, y: originalContainerViewBounds.minX, width: size.width, height: size.height)
        
        if let presentingView = presentingViewController.view {
            coordinator.animate(alongsideTransition: nil) { (context) in
                presentingView.frame = CGRect(x: 0, y: -size.height + self.spacing + 35, width: size.width, height: size.height)
            }
        }
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        
        guard let containerView = containerView else {
            return .zero
        }
        
        return CGRect(x: 0, y: 0, width: containerView.bounds.width, height: containerView.bounds.height)
    }
    
    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        dismissDelegate?.willDismiss()
    }
    
    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        
        if originalContainerViewBounds == nil {
            originalContainerViewBounds = containerView?.bounds
        }

        containerView?.frame = containerViewFrame()
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
}
