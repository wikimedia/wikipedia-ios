import SwiftUI
import UIKit

public final class WMFYearInReviewEndHostingController: UIHostingController<WMFYearInReviewEndView> {

    public let viewModel: WMFYearInReviewEndViewModel

    public init(viewModel: WMFYearInReviewEndViewModel) {
        self.viewModel = viewModel
        super.init(rootView: WMFYearInReviewEndView(viewModel: viewModel))
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
