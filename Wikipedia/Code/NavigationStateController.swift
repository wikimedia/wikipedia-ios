@objc(WMFNavigationStateController)
final class NavigationStateController: NSObject {
    private let dataStore: MWKDataStore

    init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
        super.init()
    }
}
