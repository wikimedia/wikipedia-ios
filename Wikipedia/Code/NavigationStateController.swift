@objc(WMFNavigationStateController)
final class NavigationStateController: NSObject {
    private let key = "nav_state"
    private let dataStore: MWKDataStore

    init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
        super.init()
    }
}
