import Foundation
import CoreData
import notify
import CocoaLumberjackSwift

/// Keeps a shared persistent store in sync across different processes (app, widgets,
/// extensions) by posting darwin notifications and archiving the context-did-save
/// userInfo to a file in the shared container.
///
/// Likely should be replaced with Persistent History Tracking introduced in iOS 13:
/// https://developer.apple.com/videos/play/wwdc2017/210/
/// https://www.avanderlee.com/swift/persistent-history-tracking-core-data/
///
/// Converted from Objective-C so its cross-process concurrency is visible to the
/// Swift strict-concurrency checker. @unchecked Sendable: `token` is only mutated in
/// start/stop (caller-serialized, matching the previous Objective-C contract) and the
/// write path is serialized behind `writeLock`.
@objc public final class WMFCrossProcessCoreDataSynchronizer: NSObject, @unchecked Sendable {

    private let identifier: String
    private let containerURL: URL
    // Serializes the write path (archive file + notify state + post). The Objective-C
    // version used a semaphore whose early-return paths never signaled it, which
    // could deadlock all subsequent writes; a lock with `defer` cannot leak.
    private let writeLock = NSLock()
    private var token: Int32 = 0

    private static let bundleHash: UInt64 = UInt64(bitPattern: Int64((Bundle.main.bundleIdentifier as NSString?)?.hash ?? 0))

    @objc public init(identifier: String, storageDirectory: URL) {
        self.identifier = identifier
        self.containerURL = storageDirectory
        super.init()
    }

    deinit {
        stop()
    }

    @objc public func startSynchronizingContexts(_ contexts: [NSManagedObjectContext]) {
        for context in contexts {
            NotificationCenter.default.addObserver(self, selector: #selector(contextDidSave(_:)), name: .NSManagedObjectContextDidSave, object: context)
        }
        notify_register_dispatch(identifier, &token, DispatchQueue.main) { [weak self] token in
            guard let self else {
                return
            }
            var state: UInt64 = 0
            notify_get_state(token, &state)
            let isExternal = state != Self.bundleHash
            if isExternal {
                self.readCrossProcessCoreDataNotification(state: state, into: contexts)
            }
        }
    }

    @objc public func stop() {
        if token != 0 {
            notify_cancel(token)
        }
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Writing Changes from this Process

    @objc private func contextDidSave(_ note: Notification) {
        writeCrossProcessCoreDataNotification(note)
    }

    private func writeCrossProcessCoreDataNotification(_ note: Notification) {
        writeLock.lock()
        defer {
            writeLock.unlock()
        }

        guard let userInfo = note.userInfo as? [String: Any] else {
            return
        }

        let state = Self.bundleHash
        let archivableUserInfo = archivableNotificationUserInfo(for: userInfo)

        let data: Data
        do {
            data = try NSKeyedArchiver.archivedData(withRootObject: archivableUserInfo, requiringSecureCoding: false)
        } catch {
            DDLogError("Error archiving cross process changes: \(error)")
            return
        }

        let fileURL = archivedChangesFileURL(state: state)
        try? data.write(to: fileURL, options: .atomic)

        notify_set_state(token, state)
        notify_post(identifier)
    }

    // MARK: - Reading changes from other processes

    private func readCrossProcessCoreDataNotification(state: UInt64, into contexts: [NSManagedObjectContext]) {
        let fileURL = archivedChangesFileURL(state: state)
        let userInfo: [AnyHashable: Any]
        do {
            userInfo = try unarchivedDictionary(from: fileURL)
        } catch {
            DDLogError("Error unarchiving cross process core data notification: \(error)")
            return
        }
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: userInfo, into: contexts)
    }

    // MARK: - Notification Archive Utilities

    private enum SynchronizerError: Error {
        case missingArchiveData
        case unexpectedArchiveContents
    }

    private func unarchivedDictionary(from fileURL: URL) throws -> [AnyHashable: Any] {
        guard let data = try? Data(contentsOf: fileURL) else {
            throw SynchronizerError.missingArchiveData
        }
        let allowedClasses = NSSecureUnarchiveFromDataTransformer.allowedTopLevelClasses
        guard let dictionary = try NSKeyedUnarchiver.unarchivedObject(ofClasses: allowedClasses, from: data) as? [AnyHashable: Any] else {
            throw SynchronizerError.unexpectedArchiveContents
        }
        return dictionary
    }

    private func archivedChangesFileURL(state: UInt64) -> URL {
        let fileName = "\(state).\(identifier).changes"
        return containerURL.appendingPathComponent(fileName, isDirectory: false)
    }

    private func archivableNotificationValue(for value: Any) -> Any? {
        if let managedObject = value as? NSManagedObject {
            return managedObject.objectID.uriRepresentation()
        } else if let objectID = value as? NSManagedObjectID {
            return objectID.uriRepresentation()
        } else if let set = value as? Set<AnyHashable> {
            return Set(set.compactMap { archivableNotificationValue(for: $0) as? AnyHashable })
        } else if let array = value as? [Any] {
            return array.compactMap { archivableNotificationValue(for: $0) }
        } else if value is NSCoding {
            return value
        } else {
            return nil
        }
    }

    private func archivableNotificationUserInfo(for userInfo: [String: Any]) -> [String: Any] {
        var archivableUserInfo = [String: Any](minimumCapacity: userInfo.count)
        for (key, value) in userInfo {
            let archivableValue: Any?
            if let dictionary = value as? [String: Any] {
                archivableValue = archivableNotificationUserInfo(for: dictionary)
            } else {
                archivableValue = archivableNotificationValue(for: value)
            }
            if let archivableValue {
                archivableUserInfo[key] = archivableValue
            }
        }
        return archivableUserInfo
    }
}
