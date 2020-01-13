
import Foundation

enum ArticleCacheDBWriterError: Error {
    case unableToDetermineDatabaseKey
    case unableToDetermineSiteURLOrArticleTitle
    case failureFetchingMobileHtmlResources
}

final class ArticleCacheDBWriter: NSObject, CacheDBWriting {
    
    weak var delegate: CacheDBWritingDelegate?
    private let articleFetcher: ArticleFetcher
    private let cacheBackgroundContext: NSManagedObjectContext
    private let imageController: ImageCacheController
    
    var groupedTasks: [String : [IdentifiedTask]] = [:]

    init(articleFetcher: ArticleFetcher, cacheBackgroundContext: NSManagedObjectContext, delegate: CacheDBWritingDelegate? = nil, imageController: ImageCacheController) {
        
        self.articleFetcher = articleFetcher
        self.cacheBackgroundContext = cacheBackgroundContext
        self.delegate = delegate
        self.imageController = imageController
   }
    
    func add(url: URL, groupKey: String, itemKey: String) {
        
        guard let siteURL = url.wmf_site,
            let articleTitle = url.wmf_title else {
                delegate?.dbWriterDidOutrightFailAdd(groupKey: groupKey)
                return
        }
        
        cacheMobileHtmlOfflineResources(siteURL: siteURL, articleTitle: articleTitle, groupKey: groupKey) { [weak self] (result) in
            
            guard let self = self else {
                return
            }
            
            switch result {
            case .success:
                self.cacheURLs(groupKey: groupKey, itemKeys: [groupKey], mustHaveForComplete: true) //mobile-html endpoint
                self.cacheMediaListResourceList(siteURL: siteURL, articleTitle: articleTitle, groupKey: groupKey)
            case .failure:
                self.delegate?.dbWriterDidOutrightFailAdd(groupKey: groupKey)
            }
        }
        
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 10) {
            self.fetchAndPrintEachItem()
            self.fetchAndPrintEachGroup()
        }
    }
    
    func allDownloaded(groupKey: String) -> Bool {
        
        guard let context = CacheController.backgroundCacheContext else {
            return false
        }
        
        guard let group = CacheDBWriterHelper.cacheGroup(with: groupKey, in: context) else {
            return false
        }
        guard let cacheItems = group.cacheItems as? Set<PersistentCacheItem> else {
            return false
        }
        
        return context.performWaitAndReturn {
            for item in cacheItems {
                if !item.isDownloaded && group.mustHaveCacheItems?.contains(item) ?? false {
                    return false
                }
            }
            
            return true
        } ?? false
    }
}

//Migration

extension ArticleCacheDBWriter {
    
    func cacheMobileHtmlFromMigration(desktopArticleURL: URL, itemKey: String? = nil, success: @escaping (PersistentCacheItem) -> Void, failure: @escaping (Error) -> Void) { //articleURL should be desktopURL
        guard let groupKey = desktopArticleURL.wmf_databaseKey else {
            failure(ArticleCacheDBWriterError.unableToDetermineDatabaseKey)
            return
        }
        
        let finalItemKey = itemKey ?? groupKey
        
        cacheURLs(groupKey: groupKey, itemKeys: [finalItemKey]) { (item) in
            self.cacheBackgroundContext.perform {
                item.fromMigration = true
                CacheDBWriterHelper.save(moc: self.cacheBackgroundContext) { (result) in
                    switch result {
                    case .success:
                        success(item)
                    case .failure(let error):
                        failure(error)
                    }
                }
            }
        }
    }
    
    func migratedCacheItemFile(cacheItem: PersistentCacheItem, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        cacheBackgroundContext.perform {
            cacheItem.fromMigration = false
            cacheItem.isDownloaded = true
            CacheDBWriterHelper.save(moc: self.cacheBackgroundContext) { (result) in
                switch result {
                case .success:
                    success()
                case .failure(let error):
                    failure(error)
                }
            }
        }
        
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 10) {
            self.fetchAndPrintEachItem()
            self.fetchAndPrintEachGroup()
        }
    }
}

private extension ArticleCacheDBWriter {
    
    func cacheMobileHtmlOfflineResources(siteURL: URL, articleTitle: String, groupKey: String, completion: @escaping (Result<String, ArticleCacheDBWriterError>) -> Void) {
        
        let untrackKey = UUID().uuidString
        let task = articleFetcher.fetchResourceList(siteURL: siteURL, articleTitle: articleTitle, endpointType: .mobileHtmlOfflineResources) { [weak self] (result) in
            
            defer {
                self?.untrackTask(untrackKey: untrackKey, from: groupKey)
            }
            
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(let urls):
                
                let urlItemKeys = urls.compactMap { $0.wmf_databaseKey }
                self.cacheURLs(groupKey: groupKey, itemKeys: urlItemKeys, mustHaveForComplete: true)
                
                completion(.success(groupKey))
            case .failure:
                completion(.failure(.failureFetchingMobileHtmlResources))
            }
        }
        
        if let task = task {
            trackTask(untrackKey: untrackKey, task: task, to: groupKey)
        }
    }
    
    func cacheMediaListResourceList(siteURL: URL, articleTitle: String, groupKey: String) {
        let untrackKey = UUID().uuidString
        let task = articleFetcher.fetchResourceList(siteURL: siteURL, articleTitle: articleTitle, endpointType: .mediaList) { [weak self] (result) in
            
            defer {
                self?.untrackTask(untrackKey: untrackKey, from: groupKey)
            }
            
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(let urls):
                for url in urls {
                    
                    guard let itemKey = url.wmf_databaseKey else {
                        continue
                    }
                    
                    self.imageController.add(url: url, groupKey: groupKey, itemKey: itemKey)
                }
            case .failure:
                //tonitodo: should this be handled?
                break
            }
        }
        
        if let task = task {
            trackTask(untrackKey: untrackKey, task: task, to: groupKey)
        }
    }
    
    func mobileHTMLTitle(from mobileHTMLURL: URL) -> String {
        return (mobileHTMLURL.lastPathComponent as NSString).wmf_normalizedPageTitle()
    }
    
    func cacheURLs(groupKey: String, itemKeys: [String], mustHaveForComplete: Bool = false, successCompletion: ((PersistentCacheItem) -> Void)? = nil) {
        
        //if itemKeys are already being fetched, queue via delegate
        itemKeys.filter {
            self.delegate?.shouldQueue(groupKey: groupKey, itemKey: $0) ?? false }
        .forEach { (itemKey) in
            self.delegate?.queue(groupKey: groupKey, itemKey: itemKey)
        }
        
        let itemKeysToAdd = itemKeys.filter { !(self.delegate?.shouldQueue(groupKey: groupKey, itemKey: $0) ?? false) }
        
        let context = self.cacheBackgroundContext
        context.perform {

            guard let group = CacheDBWriterHelper.fetchOrCreateCacheGroup(with: groupKey, in: context) else {
                
                if mustHaveForComplete {
                    self.delegate?.dbWriterDidOutrightFailAdd(groupKey: groupKey)
                } else {
                    itemKeysToAdd.forEach { (itemKey) in
                        self.delegate?.dbWriterDidFailAdd(groupKey: groupKey, itemKey: itemKey)
                    }
                }
                
                return
            }
            
            var addedCacheItems: [PersistentCacheItem] = []
            itemKeysToAdd.forEach { (itemKey) in
                
                guard let item = CacheDBWriterHelper.fetchOrCreateCacheItem(with: itemKey, in: context) else {
                    
                    if mustHaveForComplete {
                        self.delegate?.dbWriterDidOutrightFailAdd(groupKey: groupKey)
                    } else {
                        itemKeysToAdd.forEach { (itemKey) in
                            self.delegate?.dbWriterDidFailAdd(groupKey: groupKey, itemKey: itemKey)
                        }
                    }
                    
                    return
                }
                
                group.addToCacheItems(item)
                if mustHaveForComplete {
                     group.addToMustHaveCacheItems(item)
                }
                addedCacheItems.append(item)
            }
            
            CacheDBWriterHelper.save(moc: context) { (result) in
                switch result {
                    
                case .success:
                    addedCacheItems.forEach { (item) in
                        if let itemKey = item.key {
                            self.delegate?.dbWriterDidAdd(groupKey: groupKey, itemKey: itemKey)
                            successCompletion?(item)
                        }
                    }
                    
                case .failure:
                    
                    if mustHaveForComplete && addedCacheItems.count > 1 {
                        self.delegate?.dbWriterDidOutrightFailAdd(groupKey: groupKey)
                    } else {
                        addedCacheItems.forEach { (item) in
                            if let itemKey = item.key {
                                self.delegate?.dbWriterDidFailAdd(groupKey: groupKey, itemKey: itemKey)
                            }
                        }
                    }
                }
            }
            
        }
    }
}
