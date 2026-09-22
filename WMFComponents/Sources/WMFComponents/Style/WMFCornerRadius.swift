import Foundation

/// Corner radius scale for cards and thumbnails. Codex has no matching scale, so these values
/// are specific to the iOS app.
public enum WMFCornerRadius {
    /// 4pt. Small thumbnails and tags.
    public static let small: CGFloat = 4
    /// 8pt. Thumbnails inside cards.
    public static let medium: CGFloat = 8
    /// 12pt. Buttons and callouts.
    public static let large: CGFloat = 12
    /// 16pt. Cards.
    public static let xLarge: CGFloat = 16
}
