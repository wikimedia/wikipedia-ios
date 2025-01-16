import Foundation

/// A delegate  for handling actions triggered from the Profile view, to comunicate with the Profile delegate.
public protocol ProfileCoordinatorDelegate: AnyObject {
    func handleProfileAction(_ action: ProfileAction)
}

/// Represents the various actions that can be performed from the Profile view.
public enum ProfileAction {
    case showNotifications
    case showSettings
    case showDonate
    case showUserPage
    case showUserTalkPage
    case showWatchlist
    case login
    case logout
    case logDonateTap
    case showYearInReview
    case logYearInReviewTap
}
