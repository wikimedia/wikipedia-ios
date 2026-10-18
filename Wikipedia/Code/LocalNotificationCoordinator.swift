import UIKit
import WMF
import WMFData
import WMFComponents

/// App-side owner of local notifications. An instance shows the destination of a tapped notification; the static members own
/// the notification strings and scheduling (from background app refresh and Developer Settings), which need no navigation.
/// Each `WMFLocalNotificationType` switch is exhaustive, so adding a type fails to compile until it has content and a destination.
@MainActor
final class LocalNotificationCoordinator: Coordinator {

    let navigationController: UINavigationController
    private let dataStore: MWKDataStore
    private let theme: Theme
    private let type: WMFLocalNotificationType

    init(navigationController: UINavigationController, dataStore: MWKDataStore, theme: Theme, type: WMFLocalNotificationType) {
        self.navigationController = navigationController
        self.dataStore = dataStore
        self.theme = theme
        self.type = type
    }

    /// Pushes the destination of the tapped notification. Returns false if there is nothing to show, leaving the caller's current screen.
    @discardableResult
    func start() -> Bool {
        switch type {
        case .dailyTopRead:
            guard let topReadGroup = dataStore.viewContext.newestVisibleGroup(of: .topRead, forSiteURL: dataStore.primarySiteURL),
                  let topReadViewController = topReadGroup.detailViewControllerWithDataStore(dataStore, theme: theme) else {
                return false
            }
            navigationController.pushViewController(topReadViewController, animated: true)
            return true
        }
    }

    // MARK: - Scheduling

    static var applicationStateDescription: String {
        switch UIApplication.shared.applicationState {
        case .active: return "active"
        case .inactive: return "inactive"
        case .background: return "background"
        @unknown default: return "unknown"
        }
    }

    /// Only call from background app refresh, or the Developer Settings "Run notification refresh now" button. Schedules any local notifications that are due.
    static func scheduleNotificationsIfNeeded(dataStore: MWKDataStore) async {
        let appLanguage = dataStore.languageLinkController.appLanguage
        let language = WMFLanguage(languageCode: appLanguage?.languageCode ?? "en", languageVariantCode: appLanguage?.languageVariantCode)
        // todo: localize if this prototype becomes a real experiment
        let dailyTopReadBodyFormat = "%1$@ is the top trending article today, tap here to see more"
        await WMFDailyTopReadNotificationDataController.shared.scheduleIfNeeded(project: .wikipedia(language), bodyFormat: dailyTopReadBodyFormat, appState: applicationStateDescription)
    }

    static func developerSettingsActions(dataStore: MWKDataStore) -> WMFDeveloperSettingsLocalNotificationActions {
        WMFDeveloperSettingsLocalNotificationActions(runDailyTopReadRefreshNow: {
            await scheduleNotificationsIfNeeded(dataStore: dataStore)
        })
    }

    // MARK: - Taps

    static func logTap(type: WMFLocalNotificationType) {
        let appState = applicationStateDescription
        switch type {
        case .dailyTopRead:
            Task {
                await WMFDailyTopReadNotificationDataController.shared.logTap(appState: appState)
            }
        }
    }
}

// MARK: - Developer Settings

extension WMFDeveloperSettingsViewModel {
    /// Attaches the "Run notification refresh now" action. Used by both Developer Settings entry points (Profile and About).
    @objc func configureLocalNotificationActions(dataStore: MWKDataStore) {
        localNotificationActions = LocalNotificationCoordinator.developerSettingsActions(dataStore: dataStore)
    }
}
