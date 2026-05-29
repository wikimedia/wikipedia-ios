import Foundation
import SwiftUI
import WMFData
import WMFNativeLocalizations

/// Generic view model for the games splash screen, designed to be reused across different games.
@MainActor
public final class WMFGamesSplashScreenViewModel: ObservableObject {

    // MARK: - Properties

    /// SF Symbol name or custom icon name for the game icon displayed above the title.
    public let icon: UIImage?
    /// The date label shown in the navigation bar (e.g. "January 6").
    public let dateString: String?

    public let title: String
    public let subtitle: String
    public let aboutButtonTitle: String

    /// Reflects the current play button label. Updated via `update(sessionStatus:)`.
    @Published public var playButtonTitle: String

    // MARK: - Callbacks

    public var didTapPlay: (@MainActor @Sendable () -> Void)?
    public var didTapAbout: (@MainActor @Sendable () -> Void)?
    public var didTapClose: (@MainActor @Sendable () -> Void)?
    public var didTapLearnMore: (@MainActor @Sendable () -> Void)?
    public var didTapReportProblem: (@MainActor @Sendable () -> Void)?

    // MARK: - Initialization

    public init(
        icon: UIImage?,
        dateString: String? = nil,
        didTapPlay: (@MainActor @Sendable () -> Void)? = nil,
        didTapAbout: (@MainActor @Sendable () -> Void)? = nil,
        didTapClose: (@MainActor @Sendable () -> Void)? = nil,
        didTapLearnMore: (@MainActor @Sendable () -> Void)? = nil,
        didTapReportProblem: (@MainActor @Sendable () -> Void)? = nil
    ) {
        self.icon = icon
        self.dateString = dateString
        self.title = WMFLocalizedString(
            "which-came-first-splash-title",
            value: "Which came first?",
            comment: "Title shown on the Which Came First game splash screen."
        )
        self.subtitle = WMFLocalizedString(
            "which-came-first-splash-subtitle",
            value: "Guess which event came first on this day in history.",
            comment: "Subtitle shown on the Which Came First game splash screen."
        )
        self.aboutButtonTitle = WMFLocalizedString(
            "which-came-first-splash-about-button",
            value: "About this game",
            comment: "Button title to learn more about the Which Came First game."
        )
        self.playButtonTitle = CommonStrings.playTodaysGameTitle
        self.didTapPlay = didTapPlay
        self.didTapAbout = didTapAbout
        self.didTapClose = didTapClose
        self.didTapLearnMore = didTapLearnMore
        self.didTapReportProblem = didTapReportProblem
    }

    // MARK: - Public

    /// Updates `playButtonTitle` based on the persisted session status.
    public func update(sessionStatus: WMFGameSessionStatus) {
        switch sessionStatus {
        case .inProgress:
            playButtonTitle = WMFLocalizedString(
                "which-came-first-splash-continue-button",
                value: "Continue today's game",
                comment: "Button title to continue an in-progress Which Came First game."
            )
        case .completed:
            playButtonTitle = WMFLocalizedString(
                "which-came-first-splash-review-button",
                value: "Review results",
                comment: "Button title to review results of a completed Which Came First game."
            )
        }
    }
}
