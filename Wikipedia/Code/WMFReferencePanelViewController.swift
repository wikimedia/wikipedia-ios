
import Foundation

class WMFReferencePanelViewController: UIViewController {
    
    var referenceDictionary = [String: AnyObject]()
    @IBOutlet private var containerViewHeightConstraint:NSLayoutConstraint!
    @IBOutlet private var containerView:UIView!
    
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
        adjustContainerViewHeightToMatchReferenceHeight()
    }

    private func adjustContainerViewHeightToMatchReferenceHeight() {
        if let containerController = containerController, containerViewHeightConstraint = self.containerViewHeightConstraint {
            // First set the containerController's width, then ask it how tall its content will be at that width, then
            // set the containerViewHeightConstraint to use that height, but not exceed around 75% of the view's height.
            containerController.width = self.containerView.frame.size.width
            containerController.scrollEnabled = false
            assert(containerController.scrollEnabled == false, "Scrolling should be disabled until after we ask for preferredContentSize - otherwise preferredContentSize won't necessarily reflect the full height of the reference textview's content.")
            containerViewHeightConstraint.constant = min(containerController.preferredContentSize.height, view.frame.size.height * 0.75)
            containerController.scrollEnabled = true
            containerController.scrollToTop()
        }
    }
    
    private lazy var containerController: WMFReferencePopoverMessageViewController? = {
        let referenceVC = WMFReferencePopoverMessageViewController.wmf_initialViewControllerFromClassStoryboard()
        if let text = self.referenceDictionary["text"] as? String {
            referenceVC.linkText = text
        }
        if let html = self.referenceDictionary["html"] as? String {
            referenceVC.HTML = html
        }
        return referenceVC
    }()

    private func embedContainerControllerView() {
        if let containerController = containerController {
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
}
