import Foundation

/// A delegate  for handling actions triggered from the Settings view, to comunicate with the Settings delegate.
public protocol SettingsCoordinatorDelegate: AnyObject {
    func handleSettingsAction(_ action: SettingsAction)
}

/// Represents the various actions that can be performed from the Settings view
public enum SettingsAction {
    case account
    case tempAccount
    case logIn
    case myLanguages
    case search
    case exploreFeed
    case yearInReview
    case notifications
    case readingPreferences
    case articleSyncing
    case databasePopulation
    case clearCachedData
    case privacyPolicy
    case termsOfUse
    case rateTheApp
    case helpAndFeedback
    case about
}
