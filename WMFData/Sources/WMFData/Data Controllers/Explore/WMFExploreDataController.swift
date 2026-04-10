import Foundation

public actor WMFExploreDataController {

    private let userDefaultsStore: WMFKeyValueStore?

    public init(userDefaultsStore: WMFKeyValueStore? = WMFDataEnvironment.current.userDefaultsStore) {
        self.userDefaultsStore = userDefaultsStore
    }
}
