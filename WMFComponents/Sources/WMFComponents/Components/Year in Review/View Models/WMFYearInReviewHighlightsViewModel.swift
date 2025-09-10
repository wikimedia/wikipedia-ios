import UIKit
import SwiftUI

public class WMFYearInReviewSlideHighlightsViewModel {

    private weak var coordinatorDelegate: YearInReviewCoordinatorDelegate?

    init(coordinatorDelegate: YearInReviewCoordinatorDelegate?) {
        self.coordinatorDelegate = coordinatorDelegate
    }

    func getTableViewModel() -> WMFInfoTableViewModel {
        // mock data
        let item1 = TableItem(title: "Most popular articles on English Wikipedia", text: "1. Pamela Anderson \n2. Pamukkale \n3. History of US science fiction  \n4. Dolphins \n5. Climate change ")
        let item2 = TableItem(title: "Hours spent reading", text: "11111111111")
        let item3 = TableItem(title: "Changes editors made", text: "4234444434343434")
        let item4 = TableItem(title: "Changes editors made", text: "2")

        return WMFInfoTableViewModel(tableItems: [item1, item2, item3, item4])
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
