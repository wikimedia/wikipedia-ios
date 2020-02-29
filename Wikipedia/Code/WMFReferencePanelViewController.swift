import WMF

class WMFReferencePanelViewController: ViewController {
    var articleURL: URL?
    
    override func apply(theme: Theme) {
        guard viewIfLoaded != nil else {
            return
        }
        
    }
    
    @IBOutlet fileprivate var containerViewHeightConstraint:NSLayoutConstraint!
    @IBOutlet var containerView:UIView!
    @objc var reference:WMFLegacyReference?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.handleTapGestureRecognizer(_:))))
        embedContainerControllerView()
    }

    @objc func handleTapGestureRecognizer(_ recognizer: UITapGestureRecognizer) {
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
        referenceVC?.articleURL = articleURL
        if let trc = referenceVC as Themeable? {
            trc.apply(theme: self.theme)
        }
        referenceVC?.reference = self.reference
        return referenceVC!
    }()

    fileprivate func embedContainerControllerView() {
        guard let view = containerController.view else {
            return
        }
        addChild(containerController)
        containerView.wmf_addSubviewWithConstraintsToEdges(view)
        containerView.bringSubviewToFront(view)
        containerController.didMove(toParent: self)
    }
}
