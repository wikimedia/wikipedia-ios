
import Foundation

class WMFReferencePanelViewController: UIViewController {
    
    @IBOutlet private var containerViewHeightConstraint:NSLayoutConstraint!
    @IBOutlet var containerView:UIView!
    var reference:WMFReference?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tapRecognizer = UITapGestureRecognizer.bk_recognizerWithHandler { (sender, state, location) in
            if state == .Ended {
                self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
            }
        }
        view.addGestureRecognizer((tapRecognizer as? UITapGestureRecognizer)!)
        embedContainerControllerView()
    }

    private func panelHeight() -> CGFloat {
        return view.frame.size.height * (UIDeviceOrientationIsPortrait(UIDevice.currentDevice().orientation) ? 0.4 : 0.6)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        containerViewHeightConstraint.constant = panelHeight()
        
        containerController.scrollEnabled = true
        containerController.scrollToTop()
    }
    
    private lazy var containerController: WMFReferencePopoverMessageViewController = {
        let referenceVC = WMFReferencePopoverMessageViewController.wmf_initialViewControllerFromClassStoryboard()
        referenceVC.reference = self.reference
        return referenceVC
    }()

    private func embedContainerControllerView() {
        containerController.willMoveToParentViewController(self)
        containerController.view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(containerController.view!)
        containerView.bringSubviewToFront(containerController.view!)
        containerController.view.mas_makeConstraints { make in
            make.top.bottom().leading().and().trailing().equalTo()(self.containerView)
        }
        self.addChildViewController(containerController)
        containerController.didMoveToParentViewController(self)
    }
}
