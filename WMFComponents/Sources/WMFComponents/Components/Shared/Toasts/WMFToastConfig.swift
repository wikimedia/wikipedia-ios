import SwiftUI

public struct WMFToastConfig: Sendable {
    let title: String
    let subtitle: String?
    @preconcurrency let icon: UIImage?
    let duration: TimeInterval?
    let buttonTitle: String?
    let canBeDismissed: Bool
    let tapAction: (@Sendable () -> Void)?
    let buttonAction: (@Sendable () -> Void)?

    public init(
        title: String,
        subtitle: String? = nil,
        icon: UIImage? = nil,
        duration: TimeInterval? = 2,
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
