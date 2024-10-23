import SwiftUI
import UIKit

fileprivate final class WMFYearInReviewShareableSlideHostingController: WMFComponentHostingController<WMFYearInReviewShareableSlideView> {

    init(viewModel: WMFYearInReviewViewModel, slide: Int) {
        super.init(rootView: WMFYearInReviewShareableSlideView(viewModel: viewModel, slide: slide))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public final class WMFYearInReviewShareableSlideViewController: WMFCanvasViewController {
    fileprivate let hostingController: WMFYearInReviewShareableSlideHostingController
    private let viewModel: WMFYearInReviewViewModel
    public init(viewModel: WMFYearInReviewViewModel, slide: Int) {
        self.viewModel = viewModel
        self.hostingController = WMFYearInReviewShareableSlideHostingController(viewModel: viewModel, slide: slide)
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        addComponent(hostingController, pinToEdges: true)
        // Share activity
    }
}
