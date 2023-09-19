import Foundation

public struct WKAppData {
    let appLanguages: [WKLanguage]
    
    public init(appLanguages: [WKLanguage]) {
        self.appLanguages = appLanguages
    }
}

public final class WKDataEnvironment: ObservableObject {

	public static let current = WKDataEnvironment()

    @Published public var appData = WKAppData(appLanguages: [])
    public var mediaWikiService: WKService?
    public internal(set) var userDefaultsStore: WKKeyValueStore? = WKUserDefaultsStore()
    public var sharedCacheStore: WKKeyValueStore?
}
