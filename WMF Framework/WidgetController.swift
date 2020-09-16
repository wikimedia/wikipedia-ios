import Foundation
import WidgetKit

@objc(WMFWidgetController)
public final class WidgetController: NSObject {

    // MARK: Nested Types

    public enum SupportedWidget: String {
        case pictureOfTheDay = "org.wikimedia.wikipedia.widgets.potd"
        case onThisDay = "org.wikimedia.wikipedia.widgets.onThisDay"
        case topRead = "org.wikimedia.wikipedia.widgets.topRead"

        public var identifier: String {
            return self.rawValue
        }
    }

    // MARK: Properties

	@objc public static let shared = WidgetController()

    // MARK: Public

	@objc public func reloadAllWidgetsIfNecessary() {
        guard !Bundle.main.isAppExtension else {
            return
        }
		if #available(iOS 14.0, *) {
			WidgetCenter.shared.reloadAllTimelines()
		}
	}
    
    /// For requesting background time from widgets
    /// - Parameter userCompletion: the completion block to call with the result
    /// - Parameter task: block that takes the `MWKDataStore` to use for updates and the completion block to call when done as parameters
    public func startWidgetUpdateTask<T>(_ userCompletion: @escaping (T) -> Void, _ task: @escaping (MWKDataStore, @escaping (T) -> Void) -> Void)  {
        let processInfo = ProcessInfo.processInfo
        let start = processInfo.beginActivity(options: .background, reason: "Updating Wikipedia Widgets - " + UUID().uuidString)
        getRetainedSharedDataStore { dataStore in
            task(dataStore, { result in
                userCompletion(result)
                self.releaseSharedDataStore()
                processInfo.endActivity(start)
            })
        }
    }
    
    private var dataStoreRetainCount: Int = 0
    private var _dataStore: MWKDataStore?
    private let lock = NSRecursiveLock()
    
    /// Returns a `MWKDataStore`for use with widget updates.
    /// Manages a shared instance and a reference count for use by multiple widgets.
    /// Call `releaseSharedDataStore()` when finished with the data store.
    private func getRetainedSharedDataStore(completion: @escaping (MWKDataStore) -> Void) {
        lock.lock()
        if let dataStore = _dataStore {
            completion(dataStore)
            return
        }
        let dataStore = MWKDataStore()
        dataStore.performLibraryUpdates {
            self.dataStoreRetainCount += 1
            self._dataStore = dataStore
            self.lock.unlock()
            completion(dataStore)
        } needsMigrateBlock: {
            DDLogDebug("Needed a migration from the widgets")
        }
    }
    
    /// Releases the shared `MWKDataStore` returned by `getRetainedSharedDataStore()`.
    private func releaseSharedDataStore() {
        lock.lock()
        defer {
            lock.unlock()
        }
        dataStoreRetainCount -= 1
        guard dataStoreRetainCount <= 0 else {
            return
        }
        _dataStore = nil
        dataStoreRetainCount = 0
    }
    
}
