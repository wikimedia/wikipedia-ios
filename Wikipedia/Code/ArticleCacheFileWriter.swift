
import Foundation

//Responsible for listening to new PersistentCacheItems added to the db, fetching those urls from the network and saving the response in FileManager.

@objc public protocol ArticleCacheFileWriterDBDelegate: class {
    func downloadedCacheItemFile(cacheItem: PersistentCacheItem)
    func migratedCacheItemFile(cacheItem: PersistentCacheItem)
    func deletedCacheItemFile(cacheItem: PersistentCacheItem)
    func failureToDeleteCacheItemFile(cacheItem: PersistentCacheItem, error: Error)
}

@objc(WMFArticleCacheFileWriter)
final public class ArticleCacheFileWriter: NSObject {
    
    private let moc: NSManagedObjectContext
    private let articleFetcher: ArticleFetcher
    private let cacheURL: URL
    private let fileManager: FileManager
    private weak var dbDelegate: ArticleCacheFileWriterDBDelegate?
    
    public static let didChangeNotification = NSNotification.Name("ArticleCacheFileWriterDidChangeNotification")
    public static let didChangeNotificationUserInfoDBKey = ["dbKey"]
    public static let didChangeNotificationUserInfoIsDownloadedKey = ["isDownloaded"]
    
    @objc public init?(moc: NSManagedObjectContext, articleFetcher: ArticleFetcher, cacheURL: URL, fileManager: FileManager, dbDelegate: ArticleCacheFileWriterDBDelegate?) {
        self.moc = moc
        self.articleFetcher = articleFetcher
        self.cacheURL = cacheURL
        self.fileManager = fileManager
        self.dbDelegate = dbDelegate
        
        do {
            try fileManager.createDirectory(at: cacheURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            assertionFailure("Failure to create article cache directory")
            return nil
        }
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
                if let cacheItem = item as? PersistentCacheItem {
                    
                    if cacheItem.fromMigration == true {
                        migrate(cacheItem: cacheItem)
                    } else if cacheItem.isDownloaded == false &&
                        cacheItem.isPendingDelete == false {
                        download(cacheItem: cacheItem)
                    }
                }
            }
        }
        
        if let changedObjects = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>,
            !changedObjects.isEmpty {
            for item in changedObjects {
                if let cacheItem = item as? PersistentCacheItem,
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

private extension ArticleCacheFileWriter {
    
    func migrate(cacheItem: PersistentCacheItem) {
        
        guard cacheItem.fromMigration else {
            return
        }
        
        guard let key = cacheItem.key else {
            return
        }
        
        /*
        //key will be desktop articleURL.wmf_databaseKey format.
        //Monte: if your local mobile-html is in some sort of temporary file location, you can try calling this here:
        moveFile(from fileURL: URL, toNewFileWithKey key: key, mimeType: nil, { (result) in
            switch result {
            case .success:
                self.dbDelegate?.migratedCacheItemFile(cacheItem: cacheItem)
                NotificationCenter.default.post(name: ArticleCacheFileWriter.didChangeNotification, object: nil, userInfo: [ArticleCacheFileWriter.didChangeNotificationUserInfoDBKey: key,
                ArticleCacheFileWriter.didChangeNotificationUserInfoIsDownloadedKey: true])
            default:
                break
            }
        }
        */
    }
    
    func download(cacheItem: PersistentCacheItem) {
        
        guard let key = cacheItem.key,
            let url = URL(string: key) else {
                return
        }
        
        let urlToDownload = ArticleURLConverter.mobileHTMLURL(desktopURL: url, endpointType: .mobileHTML, scheme: Configuration.Scheme.https) ?? url
        
        articleFetcher.downloadData(url: urlToDownload) { (error, _, temporaryFileURL, mimeType) in
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
                    NotificationCenter.default.post(name: ArticleCacheFileWriter.didChangeNotification, object: nil, userInfo: [ArticleCacheFileWriter.didChangeNotificationUserInfoDBKey: key,
                    ArticleCacheFileWriter.didChangeNotificationUserInfoIsDownloadedKey: true])
                default:
                    //tonitodo: better error handling
                    break
                }
            }
        }
    }
    
    func delete(cacheItem: PersistentCacheItem) {

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
