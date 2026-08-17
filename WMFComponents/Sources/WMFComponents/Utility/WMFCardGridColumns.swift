import UIKit

/// Column counts for card grids, so the interests grid reads as the same experience as the
/// article tabs grid. Mirrors the rules in `WMFArticleTabsViewModel.calculateColumns(for:)`;
/// kept here (rather than inline) so the counts are unit-testable and reusable.
enum WMFCardGridColumns {

    /// - Parameters:
    ///   - size: the *viewport* size, not the grid's content size — portrait/landscape is
    ///     derived from it.
    ///   - isAccessibilitySize: scaled-up text needs the full width, so it collapses to one column.
    ///   - idiom: injectable for testing. Has no default because `UIDevice.current` is main actor
    ///     isolated, and a main actor default value in a nonisolated function is an error in the
    ///     Swift 6 language mode.
    static func count(
        for size: CGSize,
        isAccessibilitySize: Bool,
        idiom: UIUserInterfaceIdiom
    ) -> Int {
        if isAccessibilitySize {
            return 1
        }

        let isPortrait = size.height > size.width
        guard isPortrait else {
            return 4
        }

        guard idiom == .pad else {
            return 2
        }

        // Narrower iPads (mini) keep 3 columns so the cards don't get too cramped.
        return size.width <= 744 ? 3 : 4
    }
}
