import Foundation
import UIKit

public final class WMFDonateViewController: WMFCanvasViewController {
    
    // MARK: - Properties

    fileprivate let hostingViewController: WMFDonateHostingViewController
    private let viewModel: WMFDonateViewModel
    
    // MARK: - Lifecycle
    
    public init(viewModel: WMFDonateViewModel) {
        self.viewModel = viewModel
        self.hostingViewController = WMFDonateHostingViewController(viewModel: viewModel)
        super.init()
        hidesBottomBarWhenPushed = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.title = viewModel.localizedStrings.title
        addComponent(hostingViewController, pinToEdges: true)
        
        if navigationController?.viewControllers.first === self {
            let image = WMFSFSymbolIcon.for(symbol: .close)
            let closeButton = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(closeButtonTapped(_:)))
            navigationItem.leftBarButtonItem = closeButton
        }
    }
    
    @objc func closeButtonTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.loggingDelegate?.handleDonateLoggingAction(.nativeFormDidAppear)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
}

fileprivate final class WMFDonateHostingViewController: WMFComponentHostingController<WMFDonateView> {

    init(viewModel: WMFDonateViewModel) {
        super.init(rootView: WMFDonateView(viewModel: viewModel))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
