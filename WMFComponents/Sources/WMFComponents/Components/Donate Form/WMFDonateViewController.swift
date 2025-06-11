import Foundation
import UIKit

public final class WMFDonateViewController: WMFCanvasViewController, WMFNavigationBarConfiguring {
    
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
        
        configureNavigationBar()
    }
    
    private func configureNavigationBar() {
        
        let titleConfig = WMFNavigationBarTitleConfig(title: viewModel.localizedStrings.title, customView: nil, alignment: .centerCompact)
        var closeConfig: WMFNavigationBarCloseButtonConfig? = nil
        
        if navigationController?.viewControllers.first === self {
            closeConfig = WMFNavigationBarCloseButtonConfig(text: viewModel.localizedStrings.cancelTitle, target: self, action: #selector(closeButtonTapped(_:)), alignment: .leading)
        }
        
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: closeConfig, profileButtonConfig: nil, tabsButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }
    
    @objc func closeButtonTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.loggingDelegate?.handleDonateLoggingAction(.nativeFormDidAppear)
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
