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

    @Published public var appData = WMFAppData(appLanguages: [])
    
    public var mediaWikiService: WKService?
    public internal(set) var basicService: WKService? = WKBasicService()
    
    public var userAgentUtility: (() -> String)?
    public var appInstallIDUtility: (() -> String?)?
    public var acceptLanguageUtility: (() -> String)?
    
    public internal(set) var userDefaultsStore: WKKeyValueStore? = WKUserDefaultsStore()
    public var sharedCacheStore: WKKeyValueStore?
}
