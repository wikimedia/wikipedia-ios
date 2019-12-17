
import Foundation

//Responsible for writing mobile-html & shared resource urls to Core Data as NewCacheGroup & NewCacheItem.

@objc(WMFArticleCacheDBWriter)
final public class ArticleCacheDBWriter: NSObject {
    
    private let articleFetcher: ArticleFetcher
    private let fileManager: FileManager
    public let cacheBackgroundContext: NSManagedObjectContext
    public let cacheURL: URL

    init?(articleFetcher: ArticleFetcher, fileManager: FileManager) {
        
        self.articleFetcher = articleFetcher
        self.fileManager = fileManager
        
        //create cacheURL and directory
        guard let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last else {
            assertionFailure("Failure to pull documents directory")
            return nil
        }
        
        let documentsURL = URL(fileURLWithPath: documentsPath)
        cacheURL = documentsURL.appendingPathComponent("NewArticleCache", isDirectory: true)
        do {
            try fileManager.createDirectory(at: cacheURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            assertionFailure("Failure to create article cache directory")
            return nil
        }

        //create ManagedObjectModel based on Cache.momd
        guard let modelURL = Bundle.wmf.url(forResource: "NewCache", withExtension: "momd"),
            let model = NSManagedObjectModel(contentsOf: modelURL) else {
                assertionFailure("Failure to create managed object model")
                return nil
        }
        
        //create persistent store coordinator / persistent store
        let dbURL = cacheURL.deletingLastPathComponent().appendingPathComponent("NewCache.sqlite", isDirectory: false)
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        
        let options = [
            NSMigratePersistentStoresAutomaticallyOption: NSNumber(booleanLiteral: true),
            NSInferMappingModelAutomaticallyOption: NSNumber(booleanLiteral: true)
        ]
        
        do {
            try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: dbURL, options: options)
        } catch {
            do {
                try FileManager.default.removeItem(at: dbURL)
            } catch {
                assertionFailure("Failure to remove old db file")
                return nil
            }

            do {
                try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: dbURL, options: options)
            } catch {
                assertionFailure("Failure to add persistent store to coordinator")
                return nil
            }
        }

        cacheBackgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        cacheBackgroundContext.persistentStoreCoordinator = persistentStoreCoordinator
   }
    
    public func isCached(_ articleURL: URL) -> Bool {
        
        guard let groupKey = articleURL.wmf_databaseKey else {
            return false
        }
        
        assert(Thread.isMainThread)
        let context = cacheBackgroundContext
        return context.performWaitAndReturn {
            cacheGroup(with: groupKey, in: context) != nil
        } ?? false
    }
   
    public func toggleCache(for articleURL: URL) {
        assert(Thread.isMainThread)
        toggleCache(!isCached(articleURL), for: articleURL)
    }
   
    func clearURLCache() {
        //maybe settings hook? clear only url cache.
    }

    func clearCoreDataCache() {
        //todo: Settings hook, logout don't sync hook, etc.
        //clear out from core data, leave URL cache as-is.
    }

}

private extension ArticleCacheDBWriter {
    
    func toggleCache(_ cache: Bool, for articleURL: URL) {
        
        //todo: if not already cached...
            //1. add mobile-html key to DB, isDownloaded = false and isSaved = true, SavedArticlesSyncHandler will pick it up later.
            //2. fetch offline resources, loop through results and add key to DB, isDownloaded = false and isSaved = true, SavedArticlesSyncHandler will pick it up later. group key should be mobilehtml key
            //3. fetch media resources, loop through results and add key to DB, isDownloaded = false and isSaved = true, SavedArticlesSyncHandler will pick it up later. group key should be mobilehtml key
            //4. toc?
            //5. references?
            //6. summary?
        //if cached
            //go through items with that group key, delete the files, delete the records in CD.
        
        if cache {
            cacheEndpoint(endpointType: .mobileHTML, mobileHTMLURL: articleURL)
            cacheEndpoint(endpointType: .mobileHtmlOfflineResources, mobileHTMLURL: articleURL)
        } else {
            removeCachedArticle(with: articleURL)
        }
    }
    
    func cacheEndpoint(endpointType: ArticleFetcher.EndpointType, mobileHTMLURL: URL) {
        
        switch endpointType {
        case .mobileHTML:
            cacheURL(mobileHTMLURL: mobileHTMLURL, itemURL: mobileHTMLURL)
        case .mobileHtmlOfflineResources, .mediaList:
            
//            guard let siteURL = mobileHTMLURL.wmf_site else {
//                return
//            }
            
            guard let siteURL = URL(string: "https://en.wikipedia.org") else {
                return
            }
            
            let articleTitle = mobileHTMLTitle(from: mobileHTMLURL)
            articleFetcher.fetchResourceList(siteURL: siteURL, articleTitle: articleTitle, endpointType: endpointType) { (result) in
                switch result {
                case .success(let urls):
                    for url in urls {
                        self.cacheURL(mobileHTMLURL: mobileHTMLURL, itemURL: url)
                    }
                case .failure:
                    break
                }
            }
        default:
            break
            
        }
    }
    
    func mobileHTMLTitle(from mobileHTMLURL: URL) -> String {
        return (mobileHTMLURL.lastPathComponent as NSString).wmf_normalizedPageTitle()
    }
    
    func cacheURL(mobileHTMLURL: URL, itemURL: URL) {
        
        guard let groupKey = mobileHTMLURL.wmf_databaseKey,
            let itemKey = itemURL.wmf_databaseKey else {
                return
        }
        
        let context = self.cacheBackgroundContext
        context.perform {

            guard let group = self.fetchOrCreateCacheGroup(with: groupKey, in: context) else {
                return
            }

            guard let item = self.fetchOrCreateCacheItem(with: itemKey, in: context) else {
                return
            }
            group.addToCacheItems(item)
            self.save(moc: context)
        }
    }
    
    func fetchOrCreateCacheGroup(with groupKey: String, in moc: NSManagedObjectContext) -> NewCacheGroup? {
        return cacheGroup(with: groupKey, in: moc) ?? createCacheGroup(with: groupKey, in: moc)
    }

    func fetchOrCreateCacheItem(with itemKey: String, in moc: NSManagedObjectContext) -> NewCacheItem? {
        return cacheItem(with: itemKey, in: moc) ?? createCacheItem(with: itemKey, in: moc)
    }

    func cacheGroup(with key: String, in moc: NSManagedObjectContext) -> NewCacheGroup? {
        let fetchRequest: NSFetchRequest<NewCacheGroup> = NewCacheGroup.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "key == %@", key)
        fetchRequest.fetchLimit = 1
        do {
            guard let group = try moc.fetch(fetchRequest).first else {
                return nil
            }
            return group
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }
    
    func createCacheGroup(with groupKey: String, in moc: NSManagedObjectContext) -> NewCacheGroup? {
        
        guard let entity = NSEntityDescription.entity(forEntityName: "NewCacheGroup", in: moc) else {
            return nil
        }
        let group = NewCacheGroup(entity: entity, insertInto: moc)
        group.key = groupKey
        return group
    }
    
    func cacheItem(with itemKey: String, in moc: NSManagedObjectContext) -> NewCacheItem? {
        let fetchRequest: NSFetchRequest<NewCacheItem> = NewCacheItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "key == %@", itemKey)
        fetchRequest.fetchLimit = 1
        do {
            guard let item = try moc.fetch(fetchRequest).first else {
                return nil
            }
            return item
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }

    func createCacheItem(with itemKey: String, in moc: NSManagedObjectContext) -> NewCacheItem? {
        guard let entity = NSEntityDescription.entity(forEntityName: "NewCacheItem", in: moc) else {
            return nil
        }
        let item = NewCacheItem(entity: entity, insertInto: moc)
        item.key = itemKey
        item.date = Date()
        return item
    }
    
    func removeCachedArticle(with articleURL: URL) {
        
        guard let groupKey = articleURL.wmf_databaseKey else {
            return
        }
        
        let context = cacheBackgroundContext
        context.perform {
            //tonitodo: task tracking in ArticleFetcher
            //self.articleFetcher.cancelAllTasks(forGroupWithKey: key)
            guard let group = self.cacheGroup(with: groupKey, in: context) else {
                assertionFailure("Cache group for \(articleURL) doesn't exist")
                return
            }
            guard let cacheItems = group.cacheItems as? Set<NewCacheItem> else {
                assertionFailure("Cache group for \(articleURL) has no cache items")
                return
            }
            for cacheItem in cacheItems where cacheItem.cacheGroups?.count == 1 {
                let key = cacheItem.key
                guard let pathComponent = key?.sha256 ?? key else {
                    assertionFailure("cacheItem has no key")
                    continue
                }
                //tonitodo: instead of this filemanager piece, flag isDeleted or something and have syncer delete?
                let cachedFileURL = self.cacheURL.appendingPathComponent(pathComponent, isDirectory: false)
                do {
                    try self.fileManager.removeItem(at: cachedFileURL)
                    context.delete(cacheItem)
                } catch let error as NSError {
                    if error.code == NSURLErrorFileDoesNotExist || error.code == NSFileNoSuchFileError {
                        context.delete(cacheItem)
                    } else {
                        fatalError(error.localizedDescription)
                    }
                }
            }
            context.delete(group)
            self.save(moc: context)
        }
    }
    
    func save(moc: NSManagedObjectContext) {
        guard moc.hasChanges else {
            return
        }
        do {
            try moc.save()
        } catch let error {
            assertionFailure("Error saving cache moc: \(error)")
        }
    }
}
