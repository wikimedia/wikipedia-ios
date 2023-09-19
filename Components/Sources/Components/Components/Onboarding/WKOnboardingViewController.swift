import SwiftUI


public protocol WKOnboardingViewDelegate: AnyObject {
    func didClickPrimaryButton()
    func didClickSecondaryButton()
}

public class WKOnboardingViewController: WKCanvasViewController {
    
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
    }
}

public final class WKOnboardingHostingViewController: WKComponentHostingController<WKOnboardingView>, UIAdaptivePresentationControllerDelegate {

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

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presentationController?.delegate = self
    }

    func primaryButtonAction() {
        delegate?.didClickPrimaryButton()
    }

    func secondaryButtonAction() {
        delegate?.didClickSecondaryButton()
    }

}
