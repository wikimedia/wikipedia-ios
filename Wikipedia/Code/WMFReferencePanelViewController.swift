
import Foundation

class WMFReferencePanelViewController: UIViewController {
    
    @IBOutlet fileprivate var containerViewHeightConstraint:NSLayoutConstraint!
    @IBOutlet var containerView:UIView!
    var reference:WMFReference?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.handleTapGestureRecognizer(_:))))
        embedContainerControllerView()
    }

    func handleTapGestureRecognizer(_ recognizer: UITapGestureRecognizer) {
        switch recognizer.state {
        case .ended:
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        default:
            break
        }
    }

    fileprivate func panelHeight() -> CGFloat {
        return view.frame.size.height * (view.frame.size.height > view.frame.size.width ? 0.4 : 0.6)
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
