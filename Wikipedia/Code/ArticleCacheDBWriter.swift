
import Foundation

public enum ArticleCacheDBWriterError: Error {
    case unableToDetermineDatabaseKey
    case missingListURLInRequest
    case failureFetchingMediaList(Error)
    case failureFetchingOfflineResourceList(Error)
    case failureFetchOrCreateCacheGroup
    case failureFetchOrCreateMustHaveCacheItem
    case unableToDetermineItemKey
    case unableToDetermineBundledOfflineURLs
    case oneOrMoreItemsFailedToMarkDownloaded([Error])
    case failureMakingRequestFromMustHaveResource
}

final class ArticleCacheDBWriter: ArticleCacheResourceDBWriting {
    
    let articleFetcher: ArticleFetcher
    let cacheBackgroundContext: NSManagedObjectContext
    private let imageController: ImageCacheController
    let imageInfoFetcher: MWKImageInfoFetcher
    
    var fetcher: CacheFetching {
        return articleFetcher
    }
    
    var groupedTasks: [String : [IdentifiedTask]] = [:]

    init(articleFetcher: ArticleFetcher, cacheBackgroundContext: NSManagedObjectContext, imageController: ImageCacheController, imageInfoFetcher: MWKImageInfoFetcher) {
        
        self.articleFetcher = articleFetcher
        self.cacheBackgroundContext = cacheBackgroundContext
        self.imageController = imageController
        self.imageInfoFetcher = imageInfoFetcher
   }
    
    func add(urls: [URL], groupKey: String, completion: CacheDBWritingCompletionWithURLRequests) {
        assertionFailure("ArticleCacheDBWriter not setup for batch url inserts.")
    }
    
    //note, this comes in as desktopArticleURL via WMFArticle's key
    func add(url: URL, groupKey: CacheController.GroupKey, completion: @escaping CacheDBWritingCompletionWithURLRequests) {
        
        fetchImageAndResourceURLsForArticleURL(url, groupKey: groupKey) { [weak self] (result) in
            
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(let urls):
                
                var mustHaveURLRequests: [URLRequest] = []
                
                let mobileHTMLRequest: URLRequest
                let mobileHTMLMediaListRequest: URLRequest
                do {
                    mobileHTMLRequest = try self.articleFetcher.mobileHTMLRequest(articleURL: url)
                    mobileHTMLMediaListRequest = try self.articleFetcher.mobileHTMLMediaListRequest(articleURL: url)
                } catch (let error) {
                    completion(.failure(error))
                    return
                }
                
                mustHaveURLRequests.append(mobileHTMLRequest)
                mustHaveURLRequests.append(mobileHTMLMediaListRequest)
                
                //append mobile-html-offline-resource URLRequests
                for url in urls.offlineResourcesURLs {
                    guard let urlRequest = self.articleFetcher.urlRequest(from: url) else {
                        continue
                    }
                    
                    mustHaveURLRequests.append(urlRequest)
                }
                
                //append image info URLRequests
                for url in urls.imageInfoURLs {
                    guard let urlRequest = self.imageInfoFetcher.urlRequestFor(from: url) else {
                        completion(.failure(ArticleCacheDBWriterError.failureMakingRequestFromMustHaveResource))
                        return
                    }
                    
                    mustHaveURLRequests.append(urlRequest)
                }
                
                //send image urls straight to imageController to deal with
                self.imageController.add(urls: urls.mediaListURLs, groupKey: groupKey, individualCompletion: { (result) in
                    
                }) { (result) in
                    
                }
                
                //write URLs to database
                self.cacheURLs(groupKey: groupKey, mustHaveURLRequests: mustHaveURLRequests, niceToHaveURLRequests: []) { (result) in
                    switch result {
                    case .success:
                        let result = CacheDBWritingResultWithURLRequests.success(mustHaveURLRequests)
                        completion(result)
                    case .failure(let error):
                        let result = CacheDBWritingResultWithURLRequests.failure(error)
                        completion(result)
                    }
                }
                
            case .failure(let error):
                completion(.failure(error))
                return
            }
        }
    }
    
    func markDownloaded(urlRequest: URLRequest, response: HTTPURLResponse?, completion: @escaping (CacheDBWritingResult) -> Void) {
        
        guard let context = CacheController.backgroundCacheContext else {
            completion(.failure(CacheDBWritingMarkDownloadedError.missingMOC))
            return
        }
        
        guard let itemKey = fetcher.itemKeyForURLRequest(urlRequest) else {
            completion(.failure(CacheDBWritingMarkDownloadedError.unableToDetermineItemKey))
            return
        }
        
        let variant = fetcher.variantForURLRequest(urlRequest)
    
        context.perform {
            guard let cacheItem = CacheDBWriterHelper.cacheItem(with: itemKey, variant: nil, in: context) else {
                completion(.failure(CacheDBWritingMarkDownloadedError.cannotFindCacheItem))
                return
            }
            cacheItem.isDownloaded = true
                        
            let varyHeaderValue = response?.allHeaderFields[HTTPURLResponse.varyHeaderKey] as? String ?? nil
            let variesOnLanguage = varyHeaderValue?.contains(HTTPURLResponse.acceptLanguageHeaderValue) ?? false
            if variesOnLanguage {
                cacheItem.variant = variant
            }
            
            CacheDBWriterHelper.save(moc: context) { (result) in
                switch result {
                case .success:
                    completion(.success)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    func shouldDownloadVariant(itemKey: CacheController.ItemKey, variant: String?) -> Bool {
        //maybe tonitodo: if we reach a point where we add all language variation keys to db, we should limit this based on their NSLocale language preferences.
        return true
    }
    
    func shouldDownloadVariantForAllVariantItems(variant: String?, _ allVariantItems: [CacheController.ItemKeyAndVariant]) -> Bool {
        return true
    }
}

//Migration

extension ArticleCacheDBWriter {
    
    func addMobileHtmlURLForMigration(desktopArticleURL: URL, success: @escaping (URLRequest) -> Void, failure: @escaping (Error) -> Void) { //articleURL should be desktopURL
        
        guard let groupKey = desktopArticleURL.wmf_databaseKey else {
            failure(ArticleCacheDBWriterError.unableToDetermineDatabaseKey)
            return
        }
        
        let mobileHTMLRequest: URLRequest
        do {
            
            mobileHTMLRequest = try articleFetcher.mobileHTMLRequest(articleURL: desktopArticleURL)
        } catch (let error) {
            failure(error)
            return
        }
        
        cacheURLs(groupKey: groupKey, mustHaveURLRequests: [mobileHTMLRequest], niceToHaveURLRequests: []) { (result) in
            switch result {
            case .success:
                success(mobileHTMLRequest)
            case .failure(let error):
                failure(error)
            }
        }
    }
    
    func addBundledResourcesForMigration(desktopArticleURL: URL, completion: @escaping CacheDBWritingCompletionWithURLRequests) {
        cacheBackgroundContext.perform {
                
            
            guard let offlineResources = self.articleFetcher.bundledOfflineResourceURLs() else {
                completion(.failure(ArticleCacheDBWriterError.unableToDetermineBundledOfflineURLs))
                return
            }
            
            guard let groupKey = desktopArticleURL.wmf_databaseKey else {
                completion(.failure(ArticleCacheDBWriterError.unableToDetermineDatabaseKey))
                return
            }
            
            let baseCSSRequest = self.articleFetcher.urlRequest(from: offlineResources.baseCSS)
            let pcsCSSRequest = self.articleFetcher.urlRequest(from: offlineResources.pcsCSS)
            let pcsJSRequest = self.articleFetcher.urlRequest(from: offlineResources.pcsJS)
            
            let bundledURLRequests = [baseCSSRequest, pcsCSSRequest, pcsJSRequest].compactMap { $0 }
            
            self.cacheURLs(groupKey: groupKey, mustHaveURLRequests: bundledURLRequests, niceToHaveURLRequests: []) { (result) in
                switch result {
                case .success:
                    let result = CacheDBWritingResultWithURLRequests.success(bundledURLRequests)
                    completion(result)
                case .failure(let error):
                    let result = CacheDBWritingResultWithURLRequests.failure(error)
                    completion(result)
                }
            }
        }
    }
    
    func bundledResourcesAreCached() -> Bool {
        
        var result: Bool = false
        cacheBackgroundContext.performAndWait {
            
            var bundledOfflineResourceKeys: [String] = []
            guard let offlineResources = articleFetcher.bundledOfflineResourceURLs() else {
                result = false
                return
            }
            
            if let baseCSSKey = offlineResources.baseCSS.wmf_databaseKey {
                bundledOfflineResourceKeys.append(baseCSSKey)
            }

            if let pcsCSSKey = offlineResources.pcsCSS.wmf_databaseKey {
                bundledOfflineResourceKeys.append(pcsCSSKey)
            }

            if let pcsJSKey = offlineResources.pcsJS.wmf_databaseKey {
                bundledOfflineResourceKeys.append(pcsJSKey)
            }
            
            guard bundledOfflineResourceKeys.count == articleFetcher.expectedNumberOfBundledOfflineResources else {
                result = false
                return
            }
            
            let fetchRequest: NSFetchRequest<CacheItem> = CacheItem.fetchRequest()
            
            fetchRequest.predicate = NSPredicate(format: "key IN %@", bundledOfflineResourceKeys)
            do {
                let items = try cacheBackgroundContext.fetch(fetchRequest)
                
                guard items.count == articleFetcher.expectedNumberOfBundledOfflineResources else {
                    result = false
                    return
                }
                
                for item in items {
                    if item.isDownloaded == false {
                        result = false
                    }
                }
                
                result = true
                
            } catch {
                result = false
            }
        }
        
        return result
    }
    
    struct BulkMarkDownloadRequest {
        let urlRequest: URLRequest
        let response: HTTPURLResponse?
    }
    
    func markDownloaded(requests: [BulkMarkDownloadRequest], completion: @escaping (CacheDBWritingResult) -> Void) {
        
        var markDownloadedErrors: [Error] = []
        
        let group = DispatchGroup()
        
        for request in requests {
            group.enter()
            markDownloaded(urlRequest: request.urlRequest, response: request.response) { (result) in
                
                defer {
                    group.leave()
                }
                
                switch result {
                case .success:
                    break
                case .failure(let error):
                    markDownloadedErrors.append(error)
                }
            }
        }
        
        group.notify(queue: DispatchQueue.global(qos: .userInitiated)) {
            if markDownloadedErrors.count > 0 {
                completion(.failure(ArticleCacheDBWriterError.oneOrMoreItemsFailedToMarkDownloaded(markDownloadedErrors)))
            } else {
                completion(.success)
            }
        }
    }
}
