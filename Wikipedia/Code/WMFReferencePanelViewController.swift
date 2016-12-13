
import Foundation
import BlocksKitUIKitExtensions

class WMFReferencePanelViewController: UIViewController {
    
    @IBOutlet fileprivate var containerViewHeightConstraint:NSLayoutConstraint!
    @IBOutlet var containerView:UIView!
    var reference:WMFReference?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tapRecognizer = UITapGestureRecognizer.bk_recognizer { (sender, state, location) in
            if state == .ended {
                self.presentingViewController?.dismiss(animated: true, completion: nil)
            }
        }
        view.addGestureRecognizer(tapRecognizer)
        embedContainerControllerView()
    }

    fileprivate func panelHeight() -> CGFloat {
        return view.frame.size.height * (self.view.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.compact ? 0.4 : 0.6)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        containerViewHeightConstraint.constant = panelHeight()
        
        containerController.scrollEnabled = true
        containerController.scrollToTop()
    }
    
    fileprivate lazy var containerController: WMFReferencePopoverMessageViewController = {
        let referenceVC = WMFReferencePopoverMessageViewController.wmf_initialViewControllerFromClassStoryboard()
        referenceVC?.reference = self.reference
        return referenceVC!
    }()

    fileprivate func embedContainerControllerView() {
        containerController.willMove(toParentViewController: self)
        containerController.view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(containerController.view!)
        containerView.bringSubview(toFront: containerController.view!)
        containerController.view.mas_makeConstraints { make in
            _ = make?.top.bottom().leading().and().trailing().equalTo()(self.containerView)
        }
        self.addChildViewController(containerController)
        containerController.didMove(toParentViewController: self)
    }
}
