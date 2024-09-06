import SwiftUI


public protocol WMFOnboardingViewDelegate: AnyObject {
    func onboardingViewDidClickPrimaryButton()
    func onboardingViewDidClickSecondaryButton()
    func onboardingViewWillSwipeToDismiss()
    func onboardingDidSwipeToDismiss()
}

public extension WMFOnboardingViewDelegate {
    func onboardingViewWillSwipeToDismiss() {
        
    }
    
    func onboardingDidSwipeToDismiss() {
        
    }
}

public class WMFOnboardingViewController: WMFCanvasViewController {

    public weak var delegate: WMFOnboardingViewDelegate? {
        didSet {
            hostingController.delegate = delegate
        }
    }
    
   // MARK: - Properties

     public var hostingController: WMFOnboardingHostingViewController

    public init(viewModel: WMFOnboardingViewModel) {
        self.hostingController = WMFOnboardingHostingViewController(viewModel: viewModel)
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

    public override func viewDidLoad() {
        super.viewDidLoad()
        addComponent(hostingController, pinToEdges: true)
        presentationController?.delegate = self
    }
}

extension WMFOnboardingViewController: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        delegate?.onboardingViewWillSwipeToDismiss()
    }
    
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        delegate?.onboardingDidSwipeToDismiss()
    }
}


public final class WMFOnboardingHostingViewController: WMFComponentHostingController<WMFOnboardingView> {

    // MARK: - Properties

    public weak var delegate: WMFOnboardingViewDelegate?

    // MARK: - Properties
    init(viewModel: WMFOnboardingViewModel) {
        super.init(rootView: WMFOnboardingView(viewModel: viewModel))
        self.rootView.primaryButtonAction = { [weak self] in
            self?.primaryButtonAction()
        }

        self.rootView.secondaryButtonAction = { [weak self] in
            self?.secondaryButtonAction()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func primaryButtonAction() {
        delegate?.onboardingViewDidClickPrimaryButton()
    }

    func secondaryButtonAction() {
        delegate?.onboardingViewDidClickSecondaryButton()
    }

}
