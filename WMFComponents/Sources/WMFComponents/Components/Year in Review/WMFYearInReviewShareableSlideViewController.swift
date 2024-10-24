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
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        share()
    }

    private func share() {
        let screenSize = UIScreen.main.bounds.size
        let snapshot = hostingController.rootView.snapshot(with: screenSize)
        let text = "\(viewModel.localizedStrings.shareText) (\(viewModel.shareLink))\(viewModel.hashtag)"

        let activityItems: [Any] = [ShareActivityImageItemProvider(image: snapshot), text]

        let activityController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        activityController.excludedActivityTypes = [.print, .assignToContact, .addToReadingList]

        activityController.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
            self.dismiss(animated: true, completion: nil)
        }

        if let popover = activityController.popoverPresentationController {
            popover.sourceRect = self.hostingController.view.bounds
            popover.sourceView = self.hostingController.view
        }

        self.present(activityController, animated: true, completion: nil)
    }
}

fileprivate class ShareActivityImageItemProvider: UIActivityItemProvider, @unchecked Sendable {
    let image: UIImage

    required init(image: UIImage) {
        self.image = image
        super.init(placeholderItem: image)
    }

    override var item: Any {
        let type = activityType ?? .message
        switch type {
        default:
            return image
        }
    }
}
