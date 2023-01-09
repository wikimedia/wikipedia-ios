import Foundation

/// Implemented in `PageHistoryCountsViewController.xib`
final class PageHistoryCountsView: UIView {

    // MARK: - Overrides

    /// Required by `allowsUnderbarHitsFallThrough` to scroll through interaction
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard !UIAccessibility.isVoiceOverRunning else {
            return super.point(inside: point, with: event)
        }

        return false
    }

}
