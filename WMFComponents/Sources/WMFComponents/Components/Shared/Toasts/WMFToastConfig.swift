import SwiftUI

public struct WMFToastConfig: Sendable {
    let title: String
    let subtitle: String?
    // UIImage is not Sendable; suppress only for this stored property.
    @preconcurrency let icon: UIImage?
    let duration: TimeInterval?
    let buttonTitle: String?
    let canBeDismissed: Bool
    // Closures are non-Sendable because call sites include @objc Objective-C bridges that cannot provide
    // @Sendable closures. WMFToastConfig is only ever constructed and used from @MainActor contexts,
    // so there is no actual data race risk. Suppress the Sendable check at this boundary only.
    @preconcurrency let tapAction: (() -> Void)?
    @preconcurrency let buttonAction: (() -> Void)?

    public init(
        title: String,
        subtitle: String? = nil,
        icon: UIImage? = nil,
        duration: TimeInterval? = 5,
        buttonTitle: String? = nil,
        canBeDismissed: Bool = true,
        tapAction: (() -> Void)? = nil,
        buttonAction: (() -> Void)? = nil
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
