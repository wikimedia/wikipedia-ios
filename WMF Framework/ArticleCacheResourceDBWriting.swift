import Foundation

struct ImageAndResourceURLs {
    let offlineResourcesURLs: [URL]
    let mediaListURLs: [URL]
    let imageInfoURLs: [URL]
}

enum ImageAndResourceResult {
    case success(ImageAndResourceURLs)
    case failure(Error)
}

typealias ImageAndResourceCompletion = (ImageAndResourceResult) -> Void

protocol ArticleCacheResourceDBWriting: CacheDBWriting {
    func fetchMediaListURLs(request: URLRequest, groupKey: String, completion: @escaping (Result<[ArticleFetcher.MediaListItem], ArticleCacheDBWriterError>) -> Void)
    func fetchOfflineResourceURLs(request: URLRequest, groupKey: String, completion: @escaping (Result<[URL], ArticleCacheDBWriterError>) -> Void)
    func cacheURLs(groupKey: String, mustHaveURLRequests: [URLRequest], niceToHaveURLRequests: [URLRequest], completion: @escaping ((SaveResult) -> Void))
    var articleFetcher: ArticleFetcher { get }
    var imageInfoFetcher: MWKImageInfoFetcher { get }
    var context: NSManagedObjectContext { get }
}

extension ArticleCacheResourceDBWriting {
    
    func fetchMediaListURLs(request: URLRequest, groupKey: String, completion: @escaping (Result<[ArticleFetcher.MediaListItem], ArticleCacheDBWriterError>) -> Void) {
        
        guard request.url != nil else {
            completion(.failure(.missingListURLInRequest))
            return
        }
        
        let untrackKey = UUID().uuidString
        let task = articleFetcher.fetchMediaListURLs(with: request) { [weak self] (result) in
            
            defer {
                self?.untrackTask(untrackKey: untrackKey, from: groupKey)
            }
            
            switch result {
            case .success(let items):
                completion(.success(items))
            case .failure(let error):
                completion(.failure(.failureFetchingMediaList(error)))
            }
        }
        
        if let task = task {
            trackTask(untrackKey: untrackKey, task: task, to: groupKey)
        }
    }
    
    func fetchOfflineResourceURLs(request: URLRequest, groupKey: String, completion: @escaping (Result<[URL], ArticleCacheDBWriterError>) -> Void) {
        
        guard request.url != nil else {
            completion(.failure(.missingListURLInRequest))
            return
        }
        
        let untrackKey = UUID().uuidString
        let task = articleFetcher.fetchOfflineResourceURLs(with: request) { [weak self] (result) in
            
            defer {
                self?.untrackTask(untrackKey: untrackKey, from: groupKey)
            }
            
            switch result {
            case .success(let urls):
                completion(.success(urls))
            case .failure(let error):
                completion(.failure(.failureFetchingOfflineResourceList(error)))
            }
        }
        
        if let task = task {
            trackTask(untrackKey: untrackKey, task: task, to: groupKey)
        }
    }
    
    func cacheURLs(groupKey: String, mustHaveURLRequests: [URLRequest], niceToHaveURLRequests: [URLRequest], completion: @escaping ((SaveResult) -> Void)) {
        context.perform {

            guard let group = CacheDBWriterHelper.fetchOrCreateCacheGroup(with: groupKey, in: self.context) else {
                completion(.failure(ArticleCacheDBWriterError.failureFetchOrCreateCacheGroup))
                return
            }
            
            for urlRequest in mustHaveURLRequests {
                
                guard let url = urlRequest.url,
                    let itemKey = self.fetcher.itemKeyForURLRequest(urlRequest) else {
                        completion(.failure(ArticleCacheDBWriterError.unableToDetermineItemKey))
                        return
                }
                
                // note, we purposefully do not set variant here. We need to wait until CacheFileWriter determines if the response varies on language, then set it when we call markDownloaded
                guard let item = CacheDBWriterHelper.fetchOrCreateCacheItem(with: url, itemKey: itemKey, variant: nil, in: self.context) else {
                    completion(.failure(ArticleCacheDBWriterError.failureFetchOrCreateMustHaveCacheItem))
                    return
                }
                
                group.addToCacheItems(item)
                group.addToMustHaveCacheItems(item)
            }
            
            for urlRequest in niceToHaveURLRequests {
                
                guard let url = urlRequest.url,
                        let itemKey = self.fetcher.itemKeyForURLRequest(urlRequest) else {
                        continue
                }
                
                guard let item = CacheDBWriterHelper.fetchOrCreateCacheItem(with: url, itemKey: itemKey, variant: nil, in: self.context) else {
                    continue
                }
                
                group.addToCacheItems(item)
            }
            
            CacheDBWriterHelper.save(moc: self.context, completion: completion)
        }
    }
    
    func fetchImageAndResourceURLsForArticleURL(_ articleURL: URL, groupKey: CacheController.GroupKey, completion: @escaping ImageAndResourceCompletion) {
        var mobileHTMLOfflineResourcesRequest: URLRequest
        var mobileHTMLMediaListRequest: URLRequest
        do {
            mobileHTMLOfflineResourcesRequest = try articleFetcher.mobileHTMLOfflineResourcesRequest(articleURL: articleURL)
            mobileHTMLMediaListRequest = try articleFetcher.mobileHTMLMediaListRequest(articleURL: articleURL)
        } catch let error {
            completion(.failure(error))
            return
        }
        
        var mobileHtmlOfflineResourceURLs: [URL] = []
        var mediaListURLs: [URL] = []
        var imageInfoURLs: [URL] = []
        
        var mediaListError: Error?
        var mobileHtmlOfflineResourceError: Error?
        
        let group = DispatchGroup()
        
        group.enter()
        fetchOfflineResourceURLs(request: mobileHTMLOfflineResourcesRequest, groupKey: groupKey) { (result) in
            defer {
                group.leave()
            }
            
            switch result {
            case .success(let urls):
                
                mobileHtmlOfflineResourceURLs = urls
                
            case .failure(let error):
                mobileHtmlOfflineResourceError = error
            }
        }
        
        group.enter()
        fetchMediaListURLs(request: mobileHTMLMediaListRequest, groupKey: groupKey) { (result) in
            
            defer {
                group.leave()
            }
            
            switch result {
            case .success(let items):
                
                mediaListURLs = items.map { $0.imageURL }
                
                let imageTitles = items.map { $0.imageTitle }
                let dedupedTitles = Set(imageTitles)
                
                // add imageInfoFetcher's urls for deduped titles (for captions/licensing info in gallery)
                for title in dedupedTitles {
                    if let imageInfoURL = self.imageInfoFetcher.galleryInfoURL(forImageTitles: [title], fromSiteURL: articleURL) {
                        imageInfoURLs.append(imageInfoURL)
                    }
                }
                
            case .failure(let error):
                mediaListError = error
            }
        }
        
        group.notify(queue: DispatchQueue.global(qos: .default)) {
            
            if let mediaListError = mediaListError {
                let result = ImageAndResourceResult.failure(mediaListError)
                completion(result)
                return
            }
            
            if let mobileHtmlOfflineResourceError = mobileHtmlOfflineResourceError {
                let result = ImageAndResourceResult.failure(mobileHtmlOfflineResourceError)
                completion(result)
                return
            }
            
            let result = ImageAndResourceURLs(offlineResourcesURLs: mobileHtmlOfflineResourceURLs, mediaListURLs: mediaListURLs, imageInfoURLs: imageInfoURLs)
            completion(.success(result))
        }
    }
}
