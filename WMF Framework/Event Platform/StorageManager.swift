import Foundation
import CocoaLumberjackSwift

@objc (WMFEPCStorageManager)
public class StorageManager: NSObject {

    private let managedObjectContext: NSManagedObjectContext
    private let pruningAge: TimeInterval = 60*60*24*30 // 30 days

    @objc(sharedInstance) public static let shared: StorageManager? = {
        let fileManager = FileManager.default
        var storageDirectory = fileManager.wmf_containerURL().appendingPathComponent("Event Platform", isDirectory: true)

        do {
            try fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true, attributes: nil)
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try storageDirectory.setResourceValues(values)
        } catch let error {
            DDLogError("EPCStorageManager: Error creating Event Platform Client directory: \(error)")
        }

        let storageURL = storageDirectory.appendingPathComponent("EventPlatformEvents.sqlite")
        DDLogDebug("EPC StorageManager: Events persistent store: \(storageURL)")
        return StorageManager(storageURL: storageURL)
    }()

    private init?(storageURL: URL) {
        guard let modelURL = Bundle.wmf.url(forResource: "EventPlatformEvents", withExtension: "momd"), let model = NSManagedObjectModel(contentsOf: modelURL) else {
            return nil
        }

        let psc = NSPersistentStoreCoordinator(managedObjectModel: model)
        let options = [NSMigratePersistentStoresAutomaticallyOption: NSNumber(booleanLiteral: true), NSInferMappingModelAutomaticallyOption: NSNumber(booleanLiteral: true)]

        do {
            try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storageURL, options: options)
        } catch {
            do {
                try FileManager.default.removeItem(at: storageURL)
            } catch {

            }
            do {
                try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storageURL, options: options)
            } catch {
                DDLogError("EPC: Event Platform StorageManager: adding persistent store to coordinator: \(error)")
                return nil
            }
        }

        let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = psc
        self.managedObjectContext = managedObjectContext
    }

    func push(data: Data, stream: EventPlatformClient.Stream) {
        let now = Date()
        perform { moc in
            if let record = NSEntityDescription.insertNewObject(forEntityName: "WMFEPEventRecord", into: moc) as? EPEventRecord {
                record.data = data
                record.stream = stream.rawValue
                record.recorded = now

                DDLogDebug("EPC StorageManager: \(record.objectID) recorded!")

                self.save(moc)
            }
        }
    }

    func popAll() -> [PersistedEvent] {
        var events: [PersistedEvent] = []
        performAndWait { moc in
            let fetch: NSFetchRequest<EPEventRecord> = EPEventRecord.fetchRequest()
            fetch.sortDescriptors = [NSSortDescriptor(keyPath: \EPEventRecord.recorded, ascending: true)]
            fetch.predicate = NSPredicate(format: "(purgeable == FALSE)")

            do {
                var count = 0
                let records = try moc.fetch(fetch)
                for record in records {
                    guard let stream = EventPlatformClient.Stream(rawValue: record.stream) else {
                        continue
                    }
                    events.append(PersistedEvent(data: record.data, stream: stream, managedObjectURI: record.objectID.uriRepresentation()))
                    count += 1
                }
                if count > 0 {
                    DDLogDebug("EPC: Found \(count) events awaiting submission")
                }
            } catch let error {
                DDLogError(error.localizedDescription)
            }
        }
        return events
    }

    func markPurgeable(event: PersistedEvent) {
        perform { moc in
            do {
                guard let psc = moc.persistentStoreCoordinator else {
                    DDLogWarn("EPC: Error getting persistent store coordinator")
                    return
                }
                guard let moid = psc.managedObjectID(forURIRepresentation: event.managedObjectURI) else {
                    DDLogWarn("EPC: Error getting managed object ID for URI \(event.managedObjectURI)")
                    return
                }
                guard let record = try moc.existingObject(with: moid) as? EPEventRecord else {
                    DDLogWarn("EPC: Tried to mark managed object \(moid) as purgeable, but it was not found")
                    return
                }
                record.purgeable = true
                self.save(moc)
            } catch let error {
                DDLogError(error.localizedDescription)
            }

        }
    }

    func pruneStaleEvents(completion: @escaping (() -> Void)) {
        perform { moc in
            defer {
                completion()
            }

            let pruneFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "WMFEPEventRecord")
            pruneFetch.returnsObjectsAsFaults = false

            let pruneDate = Date().addingTimeInterval(-(self.pruningAge)) as NSDate
            pruneFetch.predicate = NSPredicate(format: "(recorded < %@) OR (purgeable == TRUE)", pruneDate)

            let delete = NSBatchDeleteRequest(fetchRequest: pruneFetch)
            delete.resultType = .resultTypeCount

            do {
                let result = try moc.execute(delete)
                guard let deleteResult = result as? NSBatchDeleteResult else {
                    DDLogError("EPC StorageManager: Could not read NSBatchDeleteResult")
                    return
                }

                guard let count = deleteResult.result as? Int else {
                    DDLogError("EPC StorageManager: Could not read NSBatchDeleteResult count")
                    return
                }

                if count > 0 {
                    DDLogInfo("EPC StorageManager: Pruned \(count) events")
                }

            } catch let error {
                DDLogError("EPC StorageManager: Error pruning events: \(error.localizedDescription)")
            }
        }
    }

    private func save(_ moc: NSManagedObjectContext) {
        guard moc.hasChanges else {
            return
        }
        do {
            try moc.save()
        } catch let error {
            DDLogError("EPC: Error saving StorageManager managedObjectContext: \(error)")
        }
    }

    private func performAndWait(_ block: (_ moc: NSManagedObjectContext) -> Void) {
        let moc = self.managedObjectContext
        moc.performAndWait {
            block(moc)
        }
    }

    private func perform(_ block: @escaping (_ moc: NSManagedObjectContext) -> Void) {
        let moc = self.managedObjectContext
        moc.perform {
            block(moc)
        }
    }
}

struct PersistedEvent: Codable {
    let data: Data
    let stream: EventPlatformClient.Stream
    let managedObjectURI: URL
}

#if TEST

extension StorageManager {
    var managedObjectContextToTest: NSManagedObjectContext { return managedObjectContext }
    func testSave(_ moc: NSManagedObjectContext) {
        save(moc)
    }
}

#endif
