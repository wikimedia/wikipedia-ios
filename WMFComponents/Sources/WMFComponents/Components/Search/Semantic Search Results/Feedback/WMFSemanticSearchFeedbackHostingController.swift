import SwiftUI
import UIKit

/// Hosts the feedback card shown in the article. Present it as is: it sets up a sheet that
/// fits its content and follows the content as the text field grows.
public final class WMFSemanticSearchFeedbackHostingController: WMFComponentHostingController<WMFSemanticSearchFeedbackView> {

    /// Measured by the card at the sheet's width. `preferredContentSize` can't be used for this:
    /// it measures at an unlimited width, where the question never wraps.
    private var cardHeight: CGFloat = 0

    public init(viewModel: WMFSemanticSearchFeedbackViewModel) {
        super.init(rootView: WMFSemanticSearchFeedbackView(viewModel: viewModel))
        rootView = WMFSemanticSearchFeedbackView(viewModel: viewModel) { [weak self] height in
            self?.cardHeightDidChange(height)
        }

        modalPresentationStyle = .pageSheet
        if let sheet = sheetPresentationController {
            sheet.detents = [.custom { [weak self] context in
                // Until the card reports its height, start at half height. A sheet with no
                // active detent traps, and the card measures itself as the sheet lays out.
                let height = (self?.cardHeight ?? 0) > 0 ? self?.cardHeight ?? 0 : context.maximumDetentValue / 2
                return min(height, context.maximumDetentValue)
            }]
            sheet.prefersGrabberVisible = true
        }
    }

    @available(*, unavailable)
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func cardHeightDidChange(_ height: CGFloat) {
        guard height != cardHeight else { return }

        cardHeight = height
        guard let sheet = sheetPresentationController else { return }
        sheet.animateChanges {
            sheet.invalidateDetents()
        }
    }
}
