import SwiftUI
import UIKit

public final class WMFYearInReviewAnnouncementHostingController: WMFComponentHostingController<WMFYearInReviewAnnouncementView> {

    public init(viewModel: WMFYearInReviewAnnouncementViewModel) {
        super.init(rootView: WMFYearInReviewAnnouncementView(viewModel: viewModel))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    public override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
}
