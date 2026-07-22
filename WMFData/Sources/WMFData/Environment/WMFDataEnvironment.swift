import Foundation
import WMFTestKitchen

public struct WMFAppData {
    let appLanguages: [WMFLanguage]

    public init(appLanguages: [WMFLanguage]) {
        self.appLanguages = appLanguages
    }
}

// MARK: - Concurrency
//
// `WMFDataEnvironment` is `@unchecked Sendable` so that `.current` can be read safely
// from the actors and background Core Data contexts elsewhere in WMFData.
//
// The genuine shared-mutable state is the set of service and store slots below
// (`mediaWikiService`, `basicService`, and the four stores). These are configured once
// during the app-launch sequence (and in test `setUp`) and then read concurrently from
// many threads, so they are guarded by `environmentLock` for real mutual exclusion.
// The remaining members (`serviceEnvironment`, `appContainerURL`, the `@Published`
// `appData`, the utility closures, and `testKitchenClient`) are left unguarded in this
// phase; they are also configured at launch and then effectively read-only.
//
// We deliberately do NOT make this type fully immutable (all `let`, injected at `init`)
// in this phase: the slots are assigned *after* construction by legacy app-side code.
// The Wikipedia target still owns authentication/session wiring and injects
// `mediaWikiService`, and it configures the stores during launch — that injection can't
// move into this initializer until that code is itself migrated.
//
// TODO: Once the Wikipedia app target has been migrated to Swift 6 and its launch-time
// configuration can be passed into this initializer, make these slots `let` (injected at
// `init`), then drop both `environmentLock` and `@unchecked` — the type becomes truly
// immutable / `Sendable` with no manual synchronization.
public final class WMFDataEnvironment: ObservableObject, @unchecked Sendable {

	public static let current = WMFDataEnvironment()

    /// Guards the service and store slots (see the note above). A single lock is fine:
    /// these are written rarely (at launch) so contention is negligible.
    private let environmentLock = NSLock()

    public var serviceEnvironment: WMFServiceEnvironment = .production
    public var appContainerURL: URL?

    @Published public var appData = WMFAppData(appLanguages: [])

    public var primaryAppLanguage: WMFLanguage? {
        return appData.appLanguages.first
    }

    // MARK: - Lock-guarded service & store slots

    public var mediaWikiService: WMFService? {
        get { environmentLock.withLock { _mediaWikiService } }
        set { environmentLock.withLock { _mediaWikiService = newValue } }
    }
    private var _mediaWikiService: WMFService?

    public var basicService: WMFService? {
        get { environmentLock.withLock { _basicService } }
        set { environmentLock.withLock { _basicService = newValue } }
    }
    private var _basicService: WMFService? = WMFBasicService()

    public var userAgentUtility: (() -> String)?
    public var appInstallIDUtility: (() -> String?)?
    public var acceptLanguageUtility: (() -> String)?

    public internal(set) var userDefaultsStore: WMFKeyValueStore? {
        get { environmentLock.withLock { _userDefaultsStore } }
        set { environmentLock.withLock { _userDefaultsStore = newValue } }
    }
    private var _userDefaultsStore: WMFKeyValueStore? = WMFUserDefaultsStore()

    public internal(set) var crossProcessUserDefaultsStore: WMFKeyValueStore? {
        get { environmentLock.withLock { _crossProcessUserDefaultsStore } }
        set { environmentLock.withLock { _crossProcessUserDefaultsStore = newValue } }
    }
    private var _crossProcessUserDefaultsStore: WMFKeyValueStore? = {
        guard let defaults = UserDefaults(suiteName: "group.org.wikimedia.wikipedia") else {
            return nil
        }
        return WMFUserDefaultsStore(defaults: defaults)
    }()

    public var sharedCacheStore: WMFKeyValueStore? {
        get { environmentLock.withLock { _sharedCacheStore } }
        set {
            environmentLock.withLock { _sharedCacheStore = newValue }
            // Post after releasing the lock to avoid any reentrancy via observers.
            if newValue != nil {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: WMFNSNotification.sharedCacheStoreSetup, object: nil)
                }
            }
        }
    }
    private var _sharedCacheStore: WMFKeyValueStore?

    public var testKitchenClient: TestKitchenClient?

    public var coreDataStore: WMFCoreDataStore? {
        get { environmentLock.withLock { _coreDataStore } }
        set {
            environmentLock.withLock { _coreDataStore = newValue }
            // Post after releasing the lock to avoid any reentrancy via observers.
            if newValue != nil {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: WMFNSNotification.coreDataStoreSetup, object: nil)
                }
            }
        }
    }
    private var _coreDataStore: WMFCoreDataStore?
}

@_spi(Testing) public struct WMFDataEnvironmentSnapshot {
    fileprivate let serviceEnvironment: WMFServiceEnvironment
    fileprivate let appContainerURL: URL?
    fileprivate let appData: WMFAppData
    fileprivate let mediaWikiService: WMFService?
    fileprivate let basicService: WMFService?
    fileprivate let userAgentUtility: (() -> String)?
    fileprivate let appInstallIDUtility: (() -> String?)?
    fileprivate let acceptLanguageUtility: (() -> String)?
    fileprivate let userDefaultsStore: WMFKeyValueStore?
    fileprivate let crossProcessUserDefaultsStore: WMFKeyValueStore?
    fileprivate let sharedCacheStore: WMFKeyValueStore?
    fileprivate let testKitchenClient: TestKitchenClient?
    fileprivate let coreDataStore: WMFCoreDataStore?
}

@_spi(Testing) public extension WMFDataEnvironment {

    func snapshotForTesting() -> WMFDataEnvironmentSnapshot {
        return WMFDataEnvironmentSnapshot(
            serviceEnvironment: serviceEnvironment,
            appContainerURL: appContainerURL,
            appData: appData,
            mediaWikiService: mediaWikiService,
            basicService: basicService,
            userAgentUtility: userAgentUtility,
            appInstallIDUtility: appInstallIDUtility,
            acceptLanguageUtility: acceptLanguageUtility,
            userDefaultsStore: userDefaultsStore,
            crossProcessUserDefaultsStore: crossProcessUserDefaultsStore,
            sharedCacheStore: sharedCacheStore,
            testKitchenClient: testKitchenClient,
            coreDataStore: coreDataStore
        )
    }

    func restoreForTesting(_ snapshot: WMFDataEnvironmentSnapshot) {
        serviceEnvironment = snapshot.serviceEnvironment
        appContainerURL = snapshot.appContainerURL
        appData = snapshot.appData
        mediaWikiService = snapshot.mediaWikiService
        basicService = snapshot.basicService
        userAgentUtility = snapshot.userAgentUtility
        appInstallIDUtility = snapshot.appInstallIDUtility
        acceptLanguageUtility = snapshot.acceptLanguageUtility
        userDefaultsStore = snapshot.userDefaultsStore
        crossProcessUserDefaultsStore = snapshot.crossProcessUserDefaultsStore
        sharedCacheStore = snapshot.sharedCacheStore
        testKitchenClient = snapshot.testKitchenClient
        coreDataStore = snapshot.coreDataStore
    }
}
