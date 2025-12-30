import Foundation

public struct WMFAppData: Sendable {
    let appLanguages: [WMFLanguage]
    
    public init(appLanguages: [WMFLanguage]) {
        self.appLanguages = appLanguages
    }
}

public final class WMFDataEnvironment: @unchecked Sendable {

    public static let current = WMFDataEnvironment()

    private let queue = DispatchQueue(label: "org.wikipedia.WMFDataEnvironment.queue", attributes: .concurrent)

    // MARK: - Mutable properties (private)
    private var _serviceEnvironment: WMFServiceEnvironment = .production
    private var _appContainerURL: URL?
    private var _appData: WMFAppData = WMFAppData(appLanguages: [])
    private var _mediaWikiService: WMFService?
    private var _basicService: WMFService? = WMFBasicService()
    private var _userAgentUtility: (() -> String)?
    private var _appInstallIDUtility: (() -> String?)?
    private var _acceptLanguageUtility: (() -> String)?
    private var _userDefaultsStore: WMFKeyValueStore? = WMFUserDefaultsStore()
    private var _sharedCacheStore: WMFKeyValueStore?
    private var _coreDataStore: WMFCoreDataStore?

    // MARK: - Public Accessors (thread-safe)

    public var serviceEnvironment: WMFServiceEnvironment {
        get { queue.sync { _serviceEnvironment } }
        set { queue.sync { self._serviceEnvironment = newValue } }
    }

    public var appContainerURL: URL? {
        get { queue.sync { _appContainerURL } }
        set { queue.sync { self._appContainerURL = newValue } }
    }

    public var appData: WMFAppData {
        get { queue.sync { _appData } }
        set { queue.sync { self._appData = newValue } }
    }

    public var primaryAppLanguage: WMFLanguage? {
        queue.sync { _appData.appLanguages.first }
    }

    public var mediaWikiService: WMFService? {
        get { queue.sync { _mediaWikiService } }
        set { queue.sync { self._mediaWikiService = newValue } }
    }

    public var basicService: WMFService? {
        get { queue.sync { _basicService } }
        set { queue.sync { self._basicService = newValue } }
    }

    public var userAgentUtility: (() -> String)? {
        get { queue.sync { _userAgentUtility } }
        set { queue.sync { self._userAgentUtility = newValue } }
    }

    public var appInstallIDUtility: (() -> String?)? {
        get { queue.sync { _appInstallIDUtility } }
        set { queue.sync { self._appInstallIDUtility = newValue } }
    }

    public var acceptLanguageUtility: (() -> String)? {
        get { queue.sync { _acceptLanguageUtility } }
        set { queue.sync { self._acceptLanguageUtility = newValue } }
    }

    public var userDefaultsStore: WMFKeyValueStore? {
        get { queue.sync { _userDefaultsStore } }
        set { queue.sync { self._userDefaultsStore = newValue } }
    }

    public var sharedCacheStore: WMFKeyValueStore? {
        get { queue.sync { _sharedCacheStore } }
        set { queue.sync { self._sharedCacheStore = newValue } }
    }

    public var coreDataStore: WMFCoreDataStore? {
        get { queue.sync { _coreDataStore } }
        set { queue.sync {
            _coreDataStore = newValue
            if newValue != nil {
                NotificationCenter.default.post(name: WMFNSNotification.coreDataStoreSetup, object: nil)
            }
        } }
    }
}
