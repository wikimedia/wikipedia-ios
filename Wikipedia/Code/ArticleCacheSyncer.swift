
import Foundation

@objc(WMFArticleCacheSyncer)
final public class ArticleCacheSyncer: NSObject {
    
    private let moc: NSManagedObjectContext
    private let articleFetcher: ArticleFetcher
    private let cacheURL: URL
    private let fileManager: FileManager
    
    public static let didDownloadNotification = NSNotification.Name("ArticleCacheSyncerDidDownloadNotification")
    public static let didDownloadNotificationUserInfoKey = ["dbKey"]
    
    @objc public init(moc: NSManagedObjectContext, articleFetcher: ArticleFetcher = ArticleFetcher(), cacheURL: URL, fileManager: FileManager) {
        self.moc = moc
        self.articleFetcher = articleFetcher
        self.cacheURL = cacheURL
        self.fileManager = fileManager
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
                cacheItem.isDownloaded == false {
                    download(cacheItem: cacheItem)
                }
            }
        }
        
        //tonitodo: handle changed objects and deleted objects
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
                    self.moc.perform {
                        cacheItem.isDownloaded = true
                        NotificationCenter.default.post(name: ArticleCacheSyncer.didDownloadNotification, object: nil, userInfo: [ArticleCacheSyncer.didDownloadNotificationUserInfoKey: key])
                        self.save(moc: self.moc)
                    }
                default:
                    //tonitodo: better error handling
                    break
                }
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
            let pathComponent = key.sha256 ?? key
            let newFileURL = cacheURL.appendingPathComponent(pathComponent, isDirectory: false)
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
