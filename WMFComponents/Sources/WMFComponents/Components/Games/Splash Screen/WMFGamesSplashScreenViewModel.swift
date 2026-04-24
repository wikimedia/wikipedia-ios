import Foundation
import SwiftUI

/// Generic view model for the games splash screen, designed to be reused across different games.
@MainActor
public final class WMFGamesSplashScreenViewModel: ObservableObject {

    // MARK: - Nested Types

    public struct LocalizedStrings {
        let title: String
        let subtitle: String
        let playButtonTitle: String
        let aboutButtonTitle: String

        public init(
            title: String,
            subtitle: String,
            playButtonTitle: String,
            aboutButtonTitle: String
        ) {
            self.title = title
            self.subtitle = subtitle
            self.playButtonTitle = playButtonTitle
            self.aboutButtonTitle = aboutButtonTitle
        }
    }

    // MARK: - Properties

    public let localizedStrings: LocalizedStrings
    /// SF Symbol name or custom icon name for the game icon displayed above the title.
    public let icon: UIImage?
    /// The date label shown in the navigation bar (e.g. "January 6").
    public let dateString: String?
    /// Background color applied to the full splash screen.
    public let backgroundColor: UIColor

    // MARK: - Callbacks

    public var didTapPlay: (@MainActor @Sendable () -> Void)?
    public var didTapAbout: (@MainActor @Sendable () -> Void)?
    public var didTapClose: (@MainActor @Sendable () -> Void)?
    public var didTapMore: (@MainActor @Sendable () -> Void)?

    // MARK: - Initialization

    public init(
        localizedStrings: LocalizedStrings,
        icon: UIImage?,
        dateString: String? = nil,
        backgroundColor: UIColor,
        didTapPlay: (@MainActor @Sendable () -> Void)? = nil,
        didTapAbout: (@MainActor @Sendable () -> Void)? = nil,
        didTapClose: (@MainActor @Sendable () -> Void)? = nil,
        didTapMore: (@MainActor @Sendable () -> Void)? = nil
    ) {
        self.localizedStrings = localizedStrings
        self.icon = icon
        self.dateString = dateString
        self.backgroundColor = backgroundColor
        self.didTapPlay = didTapPlay
        self.didTapAbout = didTapAbout
        self.didTapClose = didTapClose
        self.didTapMore = didTapMore
    }
}

