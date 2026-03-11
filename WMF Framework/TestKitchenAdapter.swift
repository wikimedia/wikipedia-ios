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
        let versionName = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let buildNumber = Int(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "")

        var deviceFamily = "unknown"
        switch UIDevice.current.userInterfaceIdiom {
        case .phone: deviceFamily = "phone"
        case .pad: deviceFamily = "tablet"
        default: break
        }

        let deviceLanguage = Locale.preferredLanguages.first ?? "en"

        #if STAGING
        let releaseStatus = "dev"
        let appFlavor = "staging"
        #elseif LOCAL
        let releaseStatus = "dev"
        let appFlavor = "local"
        #else
        let releaseStatus = "prod"
        let appFlavor = "prod"
        #endif

        return AgentData(
            appFlavor: appFlavor,
            appInstallId: appInstallId,
            appTheme: nil,
            appVersion: buildNumber,
            appVersionName: versionName.map { "WikipediaApp/\($0)" },
            clientPlatform: "ios",
            clientPlatformFamily: "app",
            deviceFamily: deviceFamily,
            deviceLanguage: deviceLanguage,
            releaseStatus: releaseStatus
        )
    }

    public func getMediawikiData() -> MediawikiData? {
        let primaryLanguage = EventPlatformClient.shared.primaryLanguage
        return MediawikiData(database: "\(primaryLanguage)wiki")
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

    public func sendEvents(destinationEventService: DestinationEventService, events: [Event]) {
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
            storageManager.push(data: data, stream: .productMetricsAppBase)
        }
    }

    // MARK: - Lifecycle

    @objc public func appDidEnterBackground() {
        client.onAppPause()
    }

    // MARK: - ObjC convenience for auth instrumentation

    @objc public func logLogoutStart() {
        let instrument = client.getInstrument(name: "apps-authentication")
            .startFunnel(name: "logout_account")
        instrument.submitInteraction(action: "click", actionSource: "settings", elementId: "logout_button")
    }

    @objc public func logLogoutConfirm() {
        let instrument = client.getInstrument(name: "apps-authentication")
        instrument.submitInteraction(action: "click", actionSource: "logout_warning", elementId: "confirm_button")
    }

    @objc public func logBackgroundLogoutImpression() {
        _ = client.getInstrument(name: "apps-authentication")
            .setDefaultActionSource("logout_background_dialog")
            .startFunnel(name: "logout_account_background")
            .submitInteraction(action: "impression")
    }
}
