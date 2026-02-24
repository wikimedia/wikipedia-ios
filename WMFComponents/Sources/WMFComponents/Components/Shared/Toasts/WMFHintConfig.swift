import SwiftUI

public struct WMFHintConfig: Sendable {
    public let title: String
    public let subtitle: String?
    @preconcurrency public let icon: UIImage?
    public let duration: TimeInterval?
    public let buttonTitle: String?
    public let canBeDismissed: Bool
    public let tapAction: (@Sendable () -> Void)?
    public let buttonAction: (@Sendable () -> Void)?

    public init(
        title: String,
        subtitle: String? = nil,
        icon: UIImage? = nil,
        duration: TimeInterval? = 13,
        buttonTitle: String? = nil,
        canBeDismissed: Bool = true,
        tapAction: (@Sendable () -> Void)? = nil,
        buttonAction: (@Sendable () -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.duration = duration
        self.buttonTitle = buttonTitle
        self.canBeDismissed = canBeDismissed
        self.tapAction = tapAction
        self.buttonAction = buttonAction
    }
}
