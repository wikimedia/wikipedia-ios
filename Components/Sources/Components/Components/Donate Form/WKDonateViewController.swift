import Foundation

public final class WKDonateViewController: WKCanvasViewController {
    
    // MARK: - Properties

    fileprivate let hostingViewController: WKDonateHostingViewController
    private let viewModel: WKDonateViewModel
    
    // MARK: - Lifecycle
    
    public init(viewModel: WKDonateViewModel, delegate: WKDonateDelegate?) {
        self.viewModel = viewModel
        self.hostingViewController = WKDonateHostingViewController(viewModel: viewModel, delegate: delegate)
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.title = viewModel.localizedStrings.title
        addComponent(hostingViewController, pinToEdges: true)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
}

fileprivate final class WKDonateHostingViewController: WKComponentHostingController<WKDonateView> {

    init(viewModel: WKDonateViewModel, delegate: WKDonateDelegate?) {
        super.init(rootView: WKDonateView(viewModel: viewModel, delegate: delegate))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
