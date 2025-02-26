import SwiftUI

public class WMFTempAccountsToastHostingController: UIHostingController<WMFTempAccountsToastView> {
    var viewModel: WMFTempAccountsToastViewModel
    var toastViewController: WMFTempAccountsToastHostingController?

    public init(viewModel: WMFTempAccountsToastViewModel) {
        self.viewModel = viewModel
        super.init(rootView: WMFTempAccountsToastView(viewModel: viewModel))
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented. Use init(viewModel:) instead.")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }
}
