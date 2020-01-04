
import Foundation

final class ArticleCacheDBWriter: NSObject, CacheDBWriting {
    
    weak var delegate: CacheDBWritingDelegate?
    private let articleFetcher: ArticleFetcher
    private let cacheBackgroundContext: NSManagedObjectContext
    private let imageController: ImageCacheController

    init(articleFetcher: ArticleFetcher, cacheBackgroundContext: NSManagedObjectContext, delegate: CacheDBWritingDelegate? = nil, imageController: ImageCacheController) {
        
        self.articleFetcher = articleFetcher
        self.cacheBackgroundContext = cacheBackgroundContext
        self.delegate = delegate
        self.imageController = imageController
   }
    
    func cacheMobileHtmlUrlFromMigration(articleURL: URL) { //articleURL should be desktopURL
        guard let groupKey = articleURL.wmf_databaseKey else {
            return
        }
        
        cacheEndpoint(articleURL: articleURL, endpointType: .mobileHTML, groupKey: groupKey, fromMigration: true)
    }
   
    func toggleCache(url: URL) {
        assert(Thread.isMainThread)
        toggleCache(!isCached(url: url), for: url)
    }
   
    func clearURLCache() {
        //maybe settings hook? clear only url cache.
    }

    func clearCoreDataCache() {
        //todo: Settings hook, logout don't sync hook, etc.
        //clear out from core data, leave URL cache as-is.
    }
    
//MARK: Reacting to File Writer Results

    func failureToDeleteCacheItemFile(cacheItem: PersistentCacheItem, error: Error) {
        //tonitodo: not sure what to do in this case. maybe at least some logging?
    }
    
    func deletedCacheItemFile(cacheItem: PersistentCacheItem) {
        cacheBackgroundContext.perform {
            self.cacheBackgroundContext.delete(cacheItem)
            
            if let cacheGroups = cacheItem.cacheGroups,
            cacheGroups.count == 1,
                let cacheGroup = cacheGroups.anyObject() as? PersistentCacheGroup {
                self.cacheBackgroundContext.delete(cacheGroup)
            }
            self.save(moc: self.cacheBackgroundContext) { (result) in
//                switch result {
//                case .success:
//                    if let key = cacheItem.key {
//                        NotificationCenter.default.post(name: ArticleCacheFileWriter.didChangeNotification, object: nil, userInfo: [ArticleCacheFileWriter.didChangeNotificationUserInfoDBKey: key,
//                        ArticleCacheFileWriter.didChangeNotificationUserInfoIsDownloadedKey: false])
//                    }
//                case .failure:
//                    //tonitodo: log
//                    break
//                }
            }
        }
        
        //tonitodo: should we wait for self.save to complete successfully?
        if let key = cacheItem.key {
            NotificationCenter.default.post(name: ArticleCacheFileWriter.didChangeNotification, object: nil, userInfo: [ArticleCacheFileWriter.didChangeNotificationUserInfoDBKey: key,
            ArticleCacheFileWriter.didChangeNotificationUserInfoIsDownloadedKey: false])
        }
    }
    
    func downloadedCacheItemFile(cacheItem: PersistentCacheItem) {
        cacheBackgroundContext.perform {
            cacheItem.isDownloaded = true
            self.save(moc: self.cacheBackgroundContext) { (result) in
                           
            }
        }
    }
    
    func migratedCacheItemFile(cacheItem: PersistentCacheItem) {
        cacheBackgroundContext.perform {
            cacheItem.fromMigration = false
            cacheItem.isDownloaded = true
            self.save(moc: self.cacheBackgroundContext) { (result) in
                                      
            }
        }
    }
}

private extension ArticleCacheDBWriter {
    
    func toggleCache(_ cache: Bool, for articleURL: URL) {
        
        guard let groupKey = articleURL.wmf_databaseKey else {
            return
        }
        
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
            cacheEndpoint(articleURL: articleURL, endpointType: .mobileHTML, groupKey: groupKey)
            cacheEndpoint(articleURL: articleURL, endpointType: .mobileHtmlOfflineResources, groupKey: groupKey)
            cacheEndpoint(articleURL: articleURL, endpointType: .mediaList, groupKey: groupKey)
        } else {
            removeCachedArticle(groupKey: groupKey)
        }
        
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 20) {
            self.fetchAndPrintEachItem()
            self.fetchAndPrintEachGroup()
        }
    }
    
    func fetchAndPrintEachItem() {
        cacheBackgroundContext.perform {
            let fetchRequest = NSFetchRequest<PersistentCacheItem>(entityName: "PersistentCacheItem")
            do {
                let fetchedResults = try self.cacheBackgroundContext.fetch(fetchRequest)
                for item in fetchedResults {
                    print("🌹itemKey: \(item.value(forKey: "key")!)")
                }
            } catch let error as NSError {
                // something went wrong, print the error.
                print(error.description)
            }
        }
    }
    
    func fetchAndPrintEachGroup() {
        cacheBackgroundContext.perform {
            let fetchRequest = NSFetchRequest<PersistentCacheGroup>(entityName: "PersistentCacheGroup")
            do {
                let fetchedResults = try self.cacheBackgroundContext.fetch(fetchRequest)
                for item in fetchedResults {
                    print("🌹groupKey: \(item.value(forKey: "key")!)")
                }
            } catch let error as NSError {
                // something went wrong, print the error.
                print(error.description)
            }
        }
    }
    
    func cacheEndpoint(articleURL: URL, endpointType: ArticleFetcher.EndpointType, groupKey: String, fromMigration: Bool = false) {
        
        switch endpointType {
        case .mobileHTML:
            cacheURL(groupKey: groupKey, itemKey: groupKey, fromMigration: fromMigration)
        case .mobileHtmlOfflineResources, .mediaList:
            
            guard let siteURL = articleURL.wmf_site,
                let articleTitle = articleURL.wmf_title else {
                return
            }
            
            articleFetcher.fetchResourceList(siteURL: siteURL, articleTitle: articleTitle, endpointType: endpointType) { (result) in
                switch result {
                case .success(let urls):
                    for url in urls {
                        
                        if endpointType == .mediaList {
                            self.imageController.cache(url: url, groupKey: groupKey)
                            continue
                        }
                        
                        guard let itemKey = url.wmf_databaseKey else {
                            continue
                        }
                        
                        self.cacheURL(groupKey: groupKey, itemKey: itemKey, fromMigration: fromMigration)
                        
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
    
    func cacheURL(groupKey: String, itemKey: String, fromMigration: Bool = false) {
        
        let context = self.cacheBackgroundContext
        context.perform {

            guard let group = CacheDBWriterHelper.fetchOrCreateCacheGroup(with: groupKey, in: context) else {
                return
            }
            
            guard let item = CacheDBWriterHelper.fetchOrCreateCacheItem(with: itemKey, in: context) else {
                return
            }
            
            item.fromMigration = fromMigration
            group.addToCacheItems(item)
            
            self.save(moc: context) { (result) in
                switch result {
                case .success:
                    self.delegate?.dbWriterDidSave(cacheItem: item)
                case .failure:
                    break
                }
            }
        }
    }
    
    func removeCachedArticle(groupKey: String) {
        
        let context = cacheBackgroundContext
        context.perform {
            //tonitodo: task tracking in ArticleFetcher
            //self.articleFetcher.cancelAllTasks(forGroupWithKey: key)
            guard let group = CacheDBWriterHelper.cacheGroup(with: groupKey, in: context) else {
                assertionFailure("Cache group for \(groupKey) doesn't exist")
                return
            }
            guard let cacheItems = group.cacheItems as? Set<PersistentCacheItem> else {
                assertionFailure("Cache group for \(groupKey) has no cache items")
                return
            }
            
            let cacheItemsToDelete = cacheItems.filter({ (cacheItem) -> Bool in
                return cacheItem.cacheGroups?.count == 1
            })
            
            for cacheItem in cacheItemsToDelete {
                cacheItem.isPendingDelete = true
            }
            
            self.save(moc: context) { (result) in
                switch result {
                case .success:
                    
                    for cacheItem in cacheItemsToDelete {
                        self.delegate?.dbWriterDidDelete(cacheItem: cacheItem)
                    }
                    
                case .failure:
                    break
                }
            }
        }
    }
}
