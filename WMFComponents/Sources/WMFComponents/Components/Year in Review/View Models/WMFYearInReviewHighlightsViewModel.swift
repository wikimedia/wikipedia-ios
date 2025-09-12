import UIKit
import SwiftUI
import WMFData

public class WMFYearInReviewSlideHighlightsViewModel {
    let infoBoxViewModel: WMFInfoTableViewModel
    private let loggingId: String
    private weak var coordinatorDelegate: YearInReviewCoordinatorDelegate?

    init(infoBoxViewModel: WMFInfoTableViewModel, loggingId: String, coordinatorDelegate: YearInReviewCoordinatorDelegate?) {
        self.infoBoxViewModel = infoBoxViewModel
        self.loggingId = loggingId
        self.coordinatorDelegate = coordinatorDelegate
    }

    @MainActor
    func tappedShare() {
        let view = WMFYearInReviewSlideHighlightShareableView(viewModel: self)
        let renderer = ImageRenderer(content: view)
        renderer.proposedSize = .init(width: 402, height: nil)
        renderer.scale = UIScreen.main.scale
        if let uiImage = renderer.uiImage {
            coordinatorDelegate?.handleYearInReviewAction(.share(image: uiImage))
        }
    }

}
