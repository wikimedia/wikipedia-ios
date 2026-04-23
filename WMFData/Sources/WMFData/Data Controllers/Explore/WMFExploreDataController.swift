public final class WMFExploreDataController {

    private let userDefaultsStore: WMFKeyValueStore?

    public init(userDefaultsStore: WMFKeyValueStore? = WMFDataEnvironment.current.userDefaultsStore) {
        self.userDefaultsStore = userDefaultsStore
    }
}
