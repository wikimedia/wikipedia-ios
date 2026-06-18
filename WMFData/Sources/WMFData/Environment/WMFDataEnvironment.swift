import Foundation
import WMFTestKitchen

public struct WMFAppData {
    let appLanguages: [WMFLanguage]
    
    public init(appLanguages: [WMFLanguage]) {
        self.appLanguages = appLanguages
    }
}

public final class WMFDataEnvironment: ObservableObject {

	public static let current = WMFDataEnvironment()
    
    public var serviceEnvironment: WMFServiceEnvironment = .production
    public var appContainerURL: URL?

    @Published public var appData = WMFAppData(appLanguages: [])
    
    public var primaryAppLanguage: WMFLanguage? {
        return appData.appLanguages.first
    }
    
    public var mediaWikiService: WMFService?
    public var basicService: WMFService? = WMFBasicService()
    
    public var userAgentUtility: (() -> String)?
    public var appInstallIDUtility: (() -> String?)?
    public var acceptLanguageUtility: (() -> String)?
    
    public internal(set) var userDefaultsStore: WMFKeyValueStore? = WMFUserDefaultsStore()
    
    public internal(set) var crossProcessUserDefaultsStore: WMFKeyValueStore? = {
        guard let defaults = UserDefaults(suiteName: "group.org.wikimedia.wikipedia") else {
            return nil
        }
        return WMFUserDefaultsStore(defaults: defaults)
    }()

    public var sharedCacheStore: WMFKeyValueStore? {
        didSet {
            if sharedCacheStore != nil {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: WMFNSNotification.sharedCacheStoreSetup, object: nil)
                }
            }
        }
    }
    
    public var testKitchenClient: TestKitchenClient?

    public var coreDataStore: WMFCoreDataStore? {
        didSet {
            if coreDataStore != nil {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: WMFNSNotification.coreDataStoreSetup, object: nil)
                }
            }
        }
    }
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
