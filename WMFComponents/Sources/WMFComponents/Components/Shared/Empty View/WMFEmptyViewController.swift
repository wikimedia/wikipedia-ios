import SwiftUI

final public class WMFEmptyViewController: WMFCanvasViewController {

    var hostingController: WMFEmptyViewHostingController
    weak var delegate: WMFEmptyViewDelegate?

    public init(viewModel: WMFEmptyViewModel, type: WMFEmptyViewStateType, delegate: WMFEmptyViewDelegate?) {
        self.hostingController = WMFEmptyViewHostingController(viewModel: viewModel, type: type, delegate: delegate)
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        addComponent(hostingController, pinToEdges: true)
    }
}

final class WMFEmptyViewHostingController: WMFComponentHostingController<WMFEmptyView> {

    init(viewModel: WMFEmptyViewModel, type: WMFEmptyViewStateType, delegate: WMFEmptyViewDelegate?) {
        super.init(rootView: WMFEmptyView(viewModel: viewModel, delegate: delegate, type: type))

    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
