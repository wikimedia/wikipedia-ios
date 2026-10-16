import Foundation

extension WMFYearInReviewDataController {

    /// The surface about to show the Year in Review announcement.
    ///
    /// Home and Explore know about deep links for the whole session, so each takes the session flag.
    /// A reader who arrived through a link is not interrupted, so the link is not covered by a pop-up.
    public enum AnnouncementPresentationContext: Sendable {
        case home(isFromDeepLink: Bool)
        case explore(isFromDeepLink: Bool)

        public var allowsAnnouncement: Bool {
            switch self {
            case .home(let isFromDeepLink), .explore(let isFromDeepLink):
                return !isFromDeepLink
            }
        }
    }
}
