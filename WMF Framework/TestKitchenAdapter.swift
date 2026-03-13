import UIKit
import WMFTestKitchen
import CocoaLumberjackSwift

@objc public class TestKitchenAdapter: NSObject, ClientDataCallback, EventSender {

    @objc public static let shared = TestKitchenAdapter()

    public lazy var client: TestKitchenClient = {
        TestKitchenClient(
            clientDataCallback: self,
            eventSender: self
        )
    }()

    private override init() {
        super.init()
    }

    // MARK: - ClientDataCallback

    public func getAgentData() -> AgentData? {
        let appInstallId = UserDefaults.standard.wmf_appInstallId
        let versionName = WikipediaAppUtils.versionName()
        let buildNumber = Int(Bundle.main.wmf_bundleVersion() ?? "0")
        let deviceFamily = WikipediaAppUtils.formFactor()

        let deviceLanguage = Locale.preferredLanguages.first ?? "en"

        // Release status must be 1 of 3 values: debug, dev or prod
        
        #if DEBUG
        let releaseStatus = "debug"
        #elseif WMF_STAGING
        let releaseStatus = "dev"
        #elseif WMF_EXPERIMENTAL
        let releaseStatus = "dev"
        #elseif UITESTS
        let releaseStatus = "dev"
        #elseif TEST
        let releaseStatus = "dev"
        #elseif WMF_LOCAL
        let releaseStatus = "dev"
        #else
        let releaseStatus = "prod"
        #endif
        
        var appFlavor: String?
        #if NDEBUG
        if Bundle.main.isTestFlight() {
            appFlavor = "TestFlight"
        } else {
            appFlavor = "AppStore"
        }
        #endif

        return AgentData(
            appFlavor: appFlavor,
            appInstallId: appInstallId,
            appTheme: UserDefaults.standard.themeAnalyticsName,
            appVersion: buildNumber,
            appVersionName: versionName,
            clientPlatform: "ios",
            clientPlatformFamily: "app",
            deviceFamily: deviceFamily,
            deviceLanguage: deviceLanguage,
            releaseStatus: releaseStatus
        )
    }

    public func getMediawikiData() -> MediawikiData? {
        
        guard let primarySiteURL = MWKDataStore.shared().primarySiteURL,
              let project = WikimediaProject(siteURL: primarySiteURL) else {
            return nil
        }
        
        let databaseIdentifier = project.notificationsApiWikiIdentifier
        
        return MediawikiData(database: databaseIdentifier)
    }

    public func getPerformerData() -> PerformerData? {
        let dataStore = MWKDataStore.shared()
        let isLoggedIn = dataStore.authenticationManager.authStateIsPermanent
        let isTemp = dataStore.authenticationManager.authStateIsTemporary
        let sessionId = EventPlatformClient.shared.sessionID

        let languageCodes = dataStore.languageLinkController.preferredLanguages.compactMap { $0.languageCode }
        let languageGroups = languageCodes.joined(separator: ",")
        let languagePrimary = EventPlatformClient.shared.primaryLanguage

        return PerformerData(
            isLoggedIn: isLoggedIn,
            isTemp: isTemp,
            sessionId: sessionId,
            languageGroups: languageGroups,
            languagePrimary: languagePrimary
        )
    }

    // MARK: - EventSender

    public func sendEvents(_ events: [Event]) {
        guard let storageManager = EventPlatformClient.shared.storageManager else {
            DDLogError("TestKitchenAdapter: StorageManager unavailable")
            return
        }
        
        let encoder = JSONEncoder()
        for event in events {
            guard let data = try? encoder.encode(event) else {
                DDLogError("TestKitchenAdapter: Failed to encode event")
                continue
            }
            
#if DEBUG
            // Convert to loose dictionary so we can sort keys and print that way.
            if let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                let printablePayload = PrintableEventPayload(payload: dict)
                DDLogDebug("\n\n🧑‍🍳TestKitchen: Scheduling event to be sent to \(EventPlatformClient.eventIntakeURI):")
                DDLogDebug("\(printablePayload)")
            }
#endif
            
            storageManager.push(data: data, stream: .productMetricsAppBase)
        }
    }
}
