import Foundation

public struct WMFAppData {
    let appLanguages: [WKLanguage]
    
    public init(appLanguages: [WKLanguage]) {
        self.appLanguages = appLanguages
    }
}

public final class WMFDataEnvironment: ObservableObject {

	public static let current = WMFDataEnvironment()
    
    public var serviceEnvironment: WKServiceEnvironment = .production

    @Published public var appData = WMFAppData(appLanguages: [])
    
    public var mediaWikiService: WKService?
    public internal(set) var basicService: WKService? = WKBasicService()
    
    public var userAgentUtility: (() -> String)?
    public var appInstallIDUtility: (() -> String?)?
    public var acceptLanguageUtility: (() -> String)?
    
    public internal(set) var userDefaultsStore: WKKeyValueStore? = WKUserDefaultsStore()
    public var sharedCacheStore: WKKeyValueStore?
}
