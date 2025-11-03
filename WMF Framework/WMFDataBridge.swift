import Foundation
import WMFData

/// Ensure `WMFDataEnvironment.current.coreDataStore` is initialized, safe to call multiple times
@objc final class WMFDataBridge: NSObject {

    private static let initLock = NSLock()

    @objc static func ensureDataStoreReadySynchronously(timeout: TimeInterval = 15) -> Bool {
        // Never block the main thread – hop to a background queue if needed.
        if Thread.isMainThread {
            var ready = false
            DispatchQueue.global(qos: .userInitiated).sync {
                ready = ensureDataStoreReadySynchronously(timeout: timeout)
            }
            return ready
        }

        initLock.lock()
        defer { initLock.unlock() }

        if WMFDataEnvironment.current.coreDataStore != nil {
            return true
        }

        let groupURL = FileManager.default.wmf_containerURL()
        WMFDataEnvironment.current.appContainerURL = groupURL

        let sempahore = DispatchSemaphore(value: 0)
        var ok = false

        Task { @MainActor in
            do {
                let store = try await WMFCoreDataStore()
                WMFDataEnvironment.current.coreDataStore = store
                ok = true
            } catch {
                print("Error setting up WMFCoreDataStore: \(error)")
            }
            sempahore.signal()
        }

        let result = sempahore.wait(timeout: .now() + timeout)
        return (result == .success) && ok
    }
}
