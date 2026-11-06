import Foundation

/// A delegate  for handling actions triggered from the Settings view, to comunicate with the Settings delegate.
@MainActor
public protocol SettingsCoordinatorDelegate: AnyObject {
    func handleSettingsAction(_ action: SettingsAction)
    func fetchDynamicValues() -> (primaryLanguage: String, readingPreferenceTheme: String)
    /// Called when the Settings screen is dismissed, from Done or from a row that closes Settings.
    func settingsWillClose()
}

public extension SettingsCoordinatorDelegate {
    func settingsWillClose() {}
}

/// Represents the various actions that can be performed from the Settings view
public enum SettingsAction {
    case account
    case tempAccount
    case logIn
    case myLanguages
    case search
    case exploreFeed
    case homeFeed
    case yearInReview
    case discover
    case notifications
    case readingPreferences
    case articleSyncing
    case editingPreferences
    case databasePopulation
    case clearCachedData
    case privacyPolicy
    case termsOfUse
    case rateTheApp
    case helpAndFeedback
    case about
    case deleteDonationHistory
    case donationReminders
    case legalAndSafety
}
