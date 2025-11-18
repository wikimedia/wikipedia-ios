public final class WMFExploreDataController {

    private let userDefaultsStore: WMFKeyValueStore?
    
    public init(userDefaultsStore: WMFKeyValueStore? = WMFDataEnvironment.current.userDefaultsStore) {
        self.userDefaultsStore = userDefaultsStore
    }
    
    public var hasSeenExploreSurvey: Bool {
        get {
            return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.hasSeenExploreSurvey.rawValue)) ?? false
        } set {
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.hasSeenExploreSurvey.rawValue, value: newValue)
        }
    }
}
