import SwiftUI
import UIKit

/// A UIKit view that shows `WMFEmptyView`, for callers that add the empty state as a subview.
///
/// The view uses the scrollable layout of `WMFEmptyView`.
public final class WMFEmptyHostingView: UIView {

    private let hostingController: UIHostingController<WMFEmptyView>

    /// - Parameter viewModel: The image and the text to show.
    public init(viewModel: WMFEmptyViewModel) {
        self.hostingController = UIHostingController(rootView: WMFEmptyView(viewModel: viewModel, delegate: nil, type: .noItems, isScrollable: true))
        super.init(frame: .zero)

        // The callers set a frame that already excludes the keyboard. Thus, keep only the container
        // safe area, so that the content does not move up a second time.
        hostingController.safeAreaRegions = .container
        hostingController.view.backgroundColor = .clear
        hostingController.view.frame = bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(hostingController.view)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
