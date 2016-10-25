
import Foundation

class WMFReferencePanelViewController: UIViewController {
    
    @IBOutlet private var containerViewHeightConstraint:NSLayoutConstraint!
    @IBOutlet private var containerView:UIView!
    var reference = WMFReference.init()
    
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let heightPercentage:CGFloat = UIDeviceOrientationIsPortrait(UIDevice.currentDevice().orientation) ? 0.4 : 0.6
        
        adjustContainerViewHeightToPercentageOfScreenHeight(heightPercentage)

        containerController.scrollEnabled = true
        containerController.scrollToTop()
    }

    private func adjustContainerViewHeightToPercentageOfScreenHeight(percentage: CGFloat) {
        containerViewHeightConstraint.constant = view.frame.size.height * percentage
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
