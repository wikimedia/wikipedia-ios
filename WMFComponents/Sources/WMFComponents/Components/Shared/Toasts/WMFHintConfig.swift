import SwiftUI

public struct WMFHintConfig: Sendable {
    public let title: String

    // UIImage is not Sendable. Keep it isolated from strict Sendable checking.
    @preconcurrency public let icon: UIImage?

    public let duration: TimeInterval?
    public let buttonTitle: String?
    public let canBeDismissed: Bool

    public let tapAction: (@Sendable () -> Void)?
    public let buttonAction: (@Sendable () -> Void)?

    public init(
        title: String,
        icon: UIImage? = nil,
        duration: TimeInterval? = 13,
        buttonTitle: String? = nil,
        canBeDismissed: Bool = true,
        tapAction: (@Sendable () -> Void)? = nil,
        buttonAction: (@Sendable () -> Void)? = nil
    ) {
        self.title = title
        self.icon = icon
        self.duration = duration
        self.buttonTitle = buttonTitle
        self.canBeDismissed = canBeDismissed
        self.tapAction = tapAction
        self.buttonAction = buttonAction
    }
}


@MainActor
public final class WMFHintModel: ObservableObject {
    @Published public var config: WMFHintConfig

    public init(config: WMFHintConfig) {
        self.config = config
    }
}
