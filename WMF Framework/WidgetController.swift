import Foundation
import WidgetKit
import CocoaLumberjackSwift

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
        guard #available(iOS 14.0, *), !Bundle.main.isAppExtension else {
            return
        }
        WidgetCenter.shared.reloadAllTimelines()
	}
    
    /// For requesting background time from widgets
    /// - Parameter userCompletion: the completion block to call with the result
    /// - Parameter task: block that takes the `MWKDataStore` to use for updates and the completion block to call when done as parameters
    public func startWidgetUpdateTask<T>(_ userCompletion: @escaping (T) -> Void, _ task: @escaping (MWKDataStore, @escaping (T) -> Void) -> Void)  {
        getRetainedSharedDataStore { dataStore in
            task(dataStore, { result in
                DispatchQueue.main.async {
                    self.releaseSharedDataStore {
                        userCompletion(result)
                    }
                }
            })
        }
    }
    
    public func fetchNewestWidgetContentGroup(with kind: WMFContentGroupKind, in dataStore: MWKDataStore, isNetworkFetchAllowed: Bool, isAnyLanguageAllowed: Bool = false, completion:  @escaping (WMFContentGroup?) -> Void) {
        fetchCachedWidgetContentGroup(with: kind, isAnyLanguageAllowed: isAnyLanguageAllowed, in: dataStore) { (contentGroup) in
            guard let todaysContentGroup = contentGroup, todaysContentGroup.isForToday else {
                guard isNetworkFetchAllowed else {
                    completion(contentGroup)
                    return
                }
                self.updateFeedContent(in: dataStore) {
                    // if there's no cached content group after update, return nil
                    self.fetchCachedWidgetContentGroup(with: kind, isAnyLanguageAllowed: isAnyLanguageAllowed, in: dataStore, completion: completion)
                }
                return
            }
            completion(todaysContentGroup)
        }
    }
    
    private func fetchCachedWidgetContentGroup(with kind: WMFContentGroupKind, isAnyLanguageAllowed: Bool, in dataStore: MWKDataStore, completion:  @escaping (WMFContentGroup?) -> Void) {
        assert(Thread.isMainThread, "Cached widget content group must be fetched from the main queue")
        let moc = dataStore.viewContext
        let siteURL = isAnyLanguageAllowed ? dataStore.primarySiteURL : nil
        completion(moc.newestGroup(of: kind, forSiteURL: siteURL))
    }
    
    public func updateFeedContent(in dataStore: MWKDataStore, completion: @escaping () -> Void) {
        dataStore.feedContentController.performDeduplicatedFetch(completion)
    }
    
    private var dataStoreRetainCount: Int = 0
    private var _dataStore: MWKDataStore?
    private var completions: [(MWKDataStore) -> Void] = []
    private var isCreatingDataStore: Bool = false
    private var backgroundActivity: NSObjectProtocol?
    
    /// Returns a `MWKDataStore`for use with widget updates.
    /// Manages a shared instance and a reference count for use by multiple widgets.
    /// Call `releaseSharedDataStore()` when finished with the data store.
    private func getRetainedSharedDataStore(completion: @escaping (MWKDataStore) -> Void) {
        assert(Thread.isMainThread, "Data store must be obtained from the main queue")
        dataStoreRetainCount += 1
        if let dataStore = _dataStore {
            completion(dataStore)
            return
        }
        completions.append(completion)
        guard !isCreatingDataStore else {
            return
        }
        isCreatingDataStore = true
        backgroundActivity = ProcessInfo.processInfo.beginActivity(options: [.background, .suddenTerminationDisabled, .automaticTerminationDisabled], reason: "Wikipedia Extension - " + UUID().uuidString)
        let dataStore = MWKDataStore()
        dataStore.performLibraryUpdates {
            DispatchQueue.main.async {
                self._dataStore = dataStore
                self.isCreatingDataStore = false
                self.completions.forEach { $0(dataStore) }
                self.completions.removeAll()
            }
        } needsMigrateBlock: {
            DDLogDebug("Needed a migration from the widgets")
        }
    }
    
    /// Releases the shared `MWKDataStore` returned by `getRetainedSharedDataStore()`.
    private func releaseSharedDataStore(completion: @escaping () -> Void) {
        assert(Thread.isMainThread, "Data store must be released from the main queue")
        dataStoreRetainCount -= 1
        guard dataStoreRetainCount <= 0 else {
            completion()
            return
        }
        dataStoreRetainCount = 0
        let asyncBackgroundActivity = backgroundActivity
        defer {
            backgroundActivity = nil
        }
        let finishBackgroundActivity = {
            if let asyncBackgroundActivity = asyncBackgroundActivity {
                ProcessInfo.processInfo.endActivity(asyncBackgroundActivity)
            }
        }
        guard let dataStoreToTeardown = _dataStore else {
            completion()
            finishBackgroundActivity()
            return
        }
        _dataStore = nil
        dataStoreToTeardown.teardown {
            completion()
            finishBackgroundActivity()
            #if DEBUG
            guard !self.isCreatingDataStore, self._dataStore == nil else { // Don't check open files if another MWKDataStore was created after this one was destroyed
                return
            }
            let openFiles = self.openFilePaths()
            let openSqliteFile = openFiles.first(where: { $0.hasSuffix(".sqlite") })
            assert(openSqliteFile == nil, "There should be no open sqlite files (which in our case are Core Data persistent stores) in the shared app container after the data store is released. The widget still has a lock on these files: \(openFiles)")
            #endif
        }
    }
    
    #if DEBUG
    /// From https://developer.apple.com/forums/thread/655225?page=2
    func openFilePaths() -> [String] {
        (0..<getdtablesize()).compactMap { fd in
            // Return nil for invalid file descriptors.
            var flags: CInt = 0
            guard fcntl(fd, F_GETFL, &flags) >= 0 else {
                return nil
            }
            // Return "?" for file descriptors not associated with a path, for
            // example, a socket.
            var path = [CChar](repeating: 0, count: Int(MAXPATHLEN))
            guard fcntl(fd, F_GETPATH, &path) >= 0 else {
                return "?"
            }
            return String(cString: path)
        }
    }
    #endif
    
}
