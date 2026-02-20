import SwiftUI

@objc public enum WMFToastType: Int, Sendable {
    case normal = 0
    case success
    case warning
    case error
}

// View Model equivalent
public struct WMFToastConfig: Sendable {
    let title: String
    let subtitle: String?
    let type: WMFToastType
    @preconcurrency let icon: UIImage?
    let duration: TimeInterval?
    let buttonTitle: String?
    let canBeDismissed: Bool
    let tapAction: (@Sendable () -> Void)?
    let buttonAction: (@Sendable () -> Void)?

    public init(
        title: String,
        subtitle: String? = nil,
        type: WMFToastType = .normal,
        icon: UIImage? = nil,
        duration: TimeInterval? = 2,
        buttonTitle: String? = nil,
        canBeDismissed: Bool = true,
        tapAction: (@Sendable () -> Void)? = nil,
        buttonAction: (@Sendable () -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.type = type
        self.icon = icon
        self.duration = duration
        self.buttonTitle = buttonTitle
        self.canBeDismissed = canBeDismissed
        self.tapAction = tapAction
        self.buttonAction = buttonAction
    }
}
