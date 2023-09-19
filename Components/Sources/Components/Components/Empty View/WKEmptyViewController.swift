import SwiftUI

final public class WKEmptyViewController: WKCanvasViewController {

    var hostingController: WKEmptyViewHostingController
    weak var delegate: WKEmptyViewDelegate?

    public init(viewModel: WKEmptyViewModel, type: WKEmptyViewStateType, delegate: WKEmptyViewDelegate?) {
        self.hostingController = WKEmptyViewHostingController(viewModel: viewModel, type: type, delegate: delegate)
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

final class WKEmptyViewHostingController: WKComponentHostingController<WKEmptyView> {

    init(viewModel: WKEmptyViewModel, type: WKEmptyViewStateType, delegate: WKEmptyViewDelegate?) {
        super.init(rootView: WKEmptyView(viewModel: viewModel, delegate: delegate, type: type))

    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
