import UIKit
import SwiftUI
import WMFData

public class WMFYearInReviewSlideHighlightsViewModel {

    public struct LocalizedStrings {
        let title: String
        let subtitle: String
        let buttonTitle: String

        public init(title: String, subtitle: String, buttonTitle: String) {
            self.title = title
            self.subtitle = subtitle
            self.buttonTitle = buttonTitle
        }
    }

    let infoBoxViewModel: WMFInfoboxViewModel
    let loggingID: String
    public let localizedStrings: LocalizedStrings
    private weak var coordinatorDelegate: YearInReviewCoordinatorDelegate?

    init(infoBoxViewModel: WMFInfoboxViewModel, loggingId: String, localizedStrings: LocalizedStrings, coordinatorDelegate: YearInReviewCoordinatorDelegate?) {
        self.infoBoxViewModel = infoBoxViewModel
        self.loggingID = loggingId
        self.localizedStrings = localizedStrings
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
