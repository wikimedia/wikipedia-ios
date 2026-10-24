import UIKit

/// Column counts for card grids, shared by the article tabs grid and the interests grid so
/// they read as the same experience. Kept here (rather than inline) so the counts are
/// unit-testable and reusable.
enum WMFCardGridColumns {

    /// - Parameters:
    ///   - size: the *viewport* size, not the grid's content size — portrait/landscape is
    ///     derived from it.
    ///   - isAccessibilitySize: scaled-up text needs the full width, so it collapses to one column.
    static func count(
        for size: CGSize,
        isAccessibilitySize: Bool
    ) -> Int {
        if isAccessibilitySize {
            return 1
        }

        let isPortrait = size.height > size.width
        guard isPortrait else {
            return 4
        }

        // Based on width rather than idiom, so a wide iPhone window (iPhone Duo's inner
        // display) gets the iPad grid and a narrow iPad window gets the phone grid.
        guard size.width >= 600 else {
            return 2
        }

        // Narrower wide windows (iPad mini) keep 3 columns so the cards don't get too cramped.
        return size.width <= 744 ? 3 : 4
    }
}
