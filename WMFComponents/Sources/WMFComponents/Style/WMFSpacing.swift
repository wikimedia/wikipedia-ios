import Foundation

/// Spacing scale for padding and gaps. The values follow the Codex spacing tokens
/// (spacing-12 … spacing-200) so the scale matches the web design system.
public enum WMFSpacing {
    /// 2pt. Codex `spacing-12`. Hairline gaps.
    public static let xxSmall: CGFloat = 2
    /// 4pt. Codex `spacing-25`. Gap between an icon and its label.
    public static let xSmall: CGFloat = 4
    /// 8pt. Codex `spacing-50`. Gap between rows inside a card.
    public static let small: CGFloat = 8
    /// 12pt. Codex `spacing-75`. Padding of compact controls.
    public static let medium: CGFloat = 12
    /// 16pt. Codex `spacing-100`. Card padding and list margins.
    public static let large: CGFloat = 16
    /// 24pt. Codex `spacing-150`. Space between sections.
    public static let xLarge: CGFloat = 24
    /// 32pt. Codex `spacing-200`. Bottom padding of floating sheets.
    public static let xxLarge: CGFloat = 32
}
