import Foundation

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
    
    public var mediaWikiService: WMFService?
    public internal(set) var basicService: WMFService? = WMFBasicService()
    
    public var userAgentUtility: (() -> String)?
    public var appInstallIDUtility: (() -> String?)?
    public var acceptLanguageUtility: (() -> String)?
    
    public internal(set) var userDefaultsStore: WMFKeyValueStore? = WMFUserDefaultsStore()
    public var sharedCacheStore: WMFKeyValueStore?
    public var coreDataStore: WMFCoreDataStore?
}
