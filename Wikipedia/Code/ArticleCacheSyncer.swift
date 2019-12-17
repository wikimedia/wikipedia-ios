
import Foundation

//Responsible for listening to new NewCacheItems added to the db, fetching those urls from the network and saving the response in FileManager.

@objc public protocol ArticleCacheSyncerDBDelegate: class {
    func downloadedCacheItemFile(cacheItem: NewCacheItem)
    func deletedCacheItemFile(cacheItem: NewCacheItem)
    func failureToDeleteCacheItemFile(cacheItem: NewCacheItem, error: Error)
}

@objc(WMFArticleCacheSyncer)
final public class ArticleCacheSyncer: NSObject {
    
    private let moc: NSManagedObjectContext
    private let articleFetcher: ArticleFetcher
    private let cacheURL: URL
    private let fileManager: FileManager
    private weak var dbDelegate: ArticleCacheSyncerDBDelegate?
    
    public static let didChangeNotification = NSNotification.Name("ArticleCacheSyncerDidChangeNotification")
    public static let didChangeNotificationUserInfoDBKey = ["dbKey"]
    public static let didChangeNotificationUserInfoIsDownloadedKey = ["isDownloaded"]
    
    @objc public init(moc: NSManagedObjectContext, articleFetcher: ArticleFetcher, cacheURL: URL, fileManager: FileManager, dbDelegate: ArticleCacheSyncerDBDelegate?) {
        self.moc = moc
        self.articleFetcher = articleFetcher
        self.cacheURL = cacheURL
        self.fileManager = fileManager
        self.dbDelegate = dbDelegate
    }
    
    @objc public func setup() {
        NotificationCenter.default.addObserver(self, selector: #selector(managedObjectContextDidSave(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: moc)
    }
    
    @objc private func managedObjectContextDidSave(_ note: Notification) {
        guard let userInfo = note.userInfo else {
            assertionFailure("Expected note with userInfo dictionary")
            return
        }
        if let insertedObjects = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, !insertedObjects.isEmpty {
            
            for item in insertedObjects {
                if let cacheItem = item as? NewCacheItem,
                cacheItem.isDownloaded == false &&
                cacheItem.isPendingDelete == false {
                    download(cacheItem: cacheItem)
                }
            }
        }
        
        if let changedObjects = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>,
            !changedObjects.isEmpty {
            for item in changedObjects {
                if let cacheItem = item as? NewCacheItem,
                    cacheItem.isPendingDelete == true {
                    delete(cacheItem: cacheItem)
                }
            }
        }
        
        //tonitodo: handle changed objects and deleted objects
    }
    
    func fileURL(for key: String) -> URL {
        let pathComponent = key.sha256 ?? key
        return cacheURL.appendingPathComponent(pathComponent, isDirectory: false)
    }
}

private extension ArticleCacheSyncer {
    func download(cacheItem: NewCacheItem) {
        
        guard let key = cacheItem.key,
            let url = URL(string: key) else {
                return
        }
        
        articleFetcher.downloadData(url: url) { (error, _, temporaryFileURL, mimeType) in
            if let _ = error {
                //tonitodo: better error handling here
                return
            }
            guard let temporaryFileURL = temporaryFileURL else {
                return
            }
            
            self.moveFile(from: temporaryFileURL, toNewFileWithKey: key, mimeType: mimeType) { (result) in
                switch result {
                case .success:
                    self.dbDelegate?.downloadedCacheItemFile(cacheItem: cacheItem)
                    NotificationCenter.default.post(name: ArticleCacheSyncer.didChangeNotification, object: nil, userInfo: [ArticleCacheSyncer.didChangeNotificationUserInfoDBKey: key,
                    ArticleCacheSyncer.didChangeNotificationUserInfoIsDownloadedKey: true])
                default:
                    //tonitodo: better error handling
                    break
                }
            }
        }
    }
    
    func delete(cacheItem: NewCacheItem) {

        guard let key = cacheItem.key else {
            assertionFailure("cacheItem has no key")
            return
        }
        
        let pathComponent = key.sha256 ?? key
        
        let cachedFileURL = self.cacheURL.appendingPathComponent(pathComponent, isDirectory: false)
        do {
            try self.fileManager.removeItem(at: cachedFileURL)
            dbDelegate?.deletedCacheItemFile(cacheItem: cacheItem)
        } catch let error as NSError {
            if error.code == NSURLErrorFileDoesNotExist || error.code == NSFileNoSuchFileError {
                dbDelegate?.deletedCacheItemFile(cacheItem: cacheItem)
               NotificationCenter.default.post(name: ArticleCacheSyncer.didChangeNotification, object: nil, userInfo: [ArticleCacheSyncer.didChangeNotificationUserInfoDBKey: key,
                ArticleCacheSyncer.didChangeNotificationUserInfoIsDownloadedKey: false])
            } else {
                dbDelegate?.failureToDeleteCacheItemFile(cacheItem: cacheItem, error: error)
            }
        }
    }
    
    enum FileMoveResult {
        case exists
        case success
        case error(Error)
    }

    func moveFile(from fileURL: URL, toNewFileWithKey key: String, mimeType: String?, completion: @escaping (FileMoveResult) -> Void) {
        do {
            let newFileURL = self.fileURL(for: key)
            try self.fileManager.moveItem(at: fileURL, to: newFileURL)
            if let mimeType = mimeType {
                fileManager.setValue(mimeType, forExtendedFileAttributeNamed: WMFExtendedFileAttributeNameMIMEType, forFileAtPath: newFileURL.path)
            }
            completion(.success)
        } catch let error as NSError {
            if error.domain == NSCocoaErrorDomain, error.code == NSFileWriteFileExistsError {
                completion(.exists)
            } else {
                completion(.error(error))
            }
        } catch let error {
            completion(.error(error))
        }
    }

    func save(moc: NSManagedObjectContext) {
        guard moc.hasChanges else {
            return
        }
        do {
            try moc.save()
        } catch let error {
            fatalError("Error saving cache moc: \(error)")
        }
    }
}

private extension FileManager {
    func setValue(_ value: String, forExtendedFileAttributeNamed attributeName: String, forFileAtPath path: String) {
        let attributeNamePointer = (attributeName as NSString).utf8String
        let pathPointer = (path as NSString).fileSystemRepresentation
        guard let valuePointer = (value as NSString).utf8String else {
            assert(false, "unable to get value pointer from \(value)")
            return
        }

        let result = setxattr(pathPointer, attributeNamePointer, valuePointer, strlen(valuePointer), 0, 0)
        assert(result != -1)
    }
}
