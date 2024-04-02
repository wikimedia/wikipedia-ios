import SwiftUI


public protocol WKOnboardingViewDelegate: AnyObject {
    func onboardingViewDidClickPrimaryButton()
    func onboardingViewDidClickSecondaryButton()
    func onboardingViewWillSwipeToDismiss()
}

public class WKOnboardingViewController: WKCanvasViewController {
    
    public weak var delegate: WKOnboardingViewDelegate? {
        didSet {
            hostingController.delegate = delegate
        }
    }
    
   // MARK: - Properties

     public var hostingController: WKOnboardingHostingViewController

    public init(viewModel: WKOnboardingViewModel) {
        self.hostingController = WKOnboardingHostingViewController(viewModel: viewModel)
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

extension WKOnboardingViewController: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        delegate?.onboardingViewWillSwipeToDismiss()
    }
}


public final class WKOnboardingHostingViewController: WKComponentHostingController<WKOnboardingView> {

    // MARK: - Properties

    public weak var delegate: WKOnboardingViewDelegate?

    // MARK: - Properties
    init(viewModel: WKOnboardingViewModel) {
        super.init(rootView: WKOnboardingView(viewModel: viewModel))
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
