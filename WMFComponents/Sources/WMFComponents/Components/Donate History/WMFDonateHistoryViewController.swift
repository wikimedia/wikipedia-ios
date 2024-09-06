import UIKit

final public class WMFDonateHistoryViewController: WMFCanvasViewController {

    fileprivate let hostingViewController: WMFDonateHistoryHostingViewController

    private let viewModel: WMFDonateHistoryViewModel
    public init(viewModel: WMFDonateHistoryViewModel) {
        self.viewModel = viewModel
        self.hostingViewController = WMFDonateHistoryHostingViewController(viewModel: viewModel)
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = viewModel.localizedStrings.viewTitle
        navigationController?.setNavigationBarHidden(false, animated: false)
        addComponent(hostingViewController, pinToEdges: true)
    }

}

final private class WMFDonateHistoryHostingViewController: WMFComponentHostingController<WMFDonateHistoryView> {

    init(viewModel: WMFDonateHistoryViewModel) {

        let rootView = WMFDonateHistoryView(viewModel: viewModel)
        super.init(rootView: rootView)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
