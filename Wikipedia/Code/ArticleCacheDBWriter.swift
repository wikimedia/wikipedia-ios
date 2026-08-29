import Foundation
import CocoaLumberjackSwift

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
    let context: NSManagedObjectContext
    let imageController: ImageCacheController
    let imageInfoFetcher: MWKImageInfoFetcher
    
    
    var fetcher: CacheFetching {
        return articleFetcher
    }
    
    var groupedTasks: [String : [IdentifiedTask]] = [:]

    init(articleFetcher: ArticleFetcher, cacheBackgroundContext: NSManagedObjectContext, imageController: ImageCacheController, imageInfoFetcher: MWKImageInfoFetcher) {
        
        self.articleFetcher = articleFetcher
        self.context = cacheBackgroundContext
        self.imageController = imageController
        self.imageInfoFetcher = imageInfoFetcher
   }
    
    func add(urls: [URL], groupKey: String, completion: CacheDBWritingCompletionWithURLRequests) {
        assertionFailure("ArticleCacheDBWriter not setup for batch url inserts.")
    }
    
    // note, this comes in as desktopArticleURL via WMFArticle's key
    func add(url: URL, groupKey: CacheController.GroupKey, completion: @escaping CacheDBWritingCompletionWithURLRequests) {
        
        fetchImageAndResourceURLsForArticleURL(url, groupKey: groupKey) { [weak self] (result) in
            
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(let urls):
                let languageVariantCode = url.wmf_languageVariantCode
                var mustHaveURLRequests: [URLRequest] = []
                
                let mobileHTMLRequest: URLRequest
                let mobileHTMLMediaListRequest: URLRequest
                do {
                    mobileHTMLRequest = try self.articleFetcher.mobileHTMLRequest(articleURL: url)
                    mobileHTMLMediaListRequest = try self.articleFetcher.mobileHTMLMediaListRequest(articleURL: url)
                } catch let error {
                    completion(.failure(error))
                    return
                }
                
                mustHaveURLRequests.append(mobileHTMLRequest)
                mustHaveURLRequests.append(mobileHTMLMediaListRequest)
                
                // append mobile-html-offline-resource URLRequests
                for var url in urls.offlineResourcesURLs {
                    // We're OK with any Content-Type here because we don't use them directly, they're the related files that mobile-html might request
                    let acceptAnyContentType = ["Accept": "*/*"]
                    
                    // Temporary shim until ArticleCache is completely variant-aware
                    url.wmf_languageVariantCode = languageVariantCode
                    guard let urlRequest = self.articleFetcher.urlRequest(from: url, headers: acceptAnyContentType) else {
                        continue
                    }
                    
                    mustHaveURLRequests.append(urlRequest)
                }
                
                // append image info URLRequests
                //
                // These are registered as cache items like everything else, but they are
                // NOT returned to the cache controller to download one by one — an
                // image-heavy article would issue one api.php call per image. They are
                // fetched in batches below and stored per title instead.
                var imageInfoRequestsByTitle: [(title: String, urlRequest: URLRequest)] = []
                for imageInfo in urls.imageInfo {
                    guard let urlRequest = self.imageInfoFetcher.urlRequestFor(from: imageInfo.url) else {
                        completion(.failure(ArticleCacheDBWriterError.failureMakingRequestFromMustHaveResource))
                        return
                    }

                    mustHaveURLRequests.append(urlRequest)
                    imageInfoRequestsByTitle.append((imageInfo.title, urlRequest))
                }

                // send image urls straight to imageController to deal with
                self.imageController.add(urls: urls.mediaListURLs, groupKey: groupKey, individualCompletion: { (result) in
                    
                }) { (result) in
                    
                }
                
                // write URLs to database
                self.cacheURLs(groupKey: groupKey, mustHaveURLRequests: mustHaveURLRequests, niceToHaveURLRequests: []) { (result) in
                    switch result {
                    case .success:
                        // Everything except the image info, which the batched fetch below
                        // downloads and stores itself.
                        let imageInfoRequestURLs = Set(imageInfoRequestsByTitle.compactMap { $0.urlRequest.url })
                        let remainingRequests = mustHaveURLRequests.filter { request in
                            guard let url = request.url else {
                                return true
                            }
                            return !imageInfoRequestURLs.contains(url)
                        }

                        self.cacheImageInfoInBatches(titledRequests: imageInfoRequestsByTitle, siteURL: url) { error in
                            if let error = error {
                                completion(.failure(error))
                                return
                            }
                            completion(.success(remainingRequests))
                        }
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
    
    /// Titles per `action=query&prop=imageinfo` call.
    ///
    /// The API allows 50; a smaller batch keeps any single failure from costing a whole
    /// article's metadata and keeps each response small enough to split cheaply.
    static let imageInfoBatchSize = 10

    /// Fetches image metadata in batches and stores one cache entry per title.
    ///
    /// Batches run one at a time rather than all at once. Firing every chunk together
    /// would put one concurrent api.php call per ten images in flight, which undercuts
    /// the point of batching for an image-heavy article; these are also outside the
    /// per-article throttle, since the throttle lives on the cache controller.
    ///
    /// Calls back with the first error encountered, or nil if every batch stored.
    private func cacheImageInfoInBatches(titledRequests: [(title: String, urlRequest: URLRequest)], siteURL: URL, completion: @escaping (Error?) -> Void) {

        guard !titledRequests.isEmpty else {
            completion(nil)
            return
        }

        var requestsByTitle: [String: URLRequest] = [:]
        for titledRequest in titledRequests {
            requestsByTitle[titledRequest.title] = titledRequest.urlRequest
        }

        let batches = titledRequests.map { $0.title }.chunked(into: Self.imageInfoBatchSize)
        fetchImageInfoBatches(batches, index: 0, siteURL: siteURL, requestsByTitle: requestsByTitle, completion: completion)
    }

    private func fetchImageInfoBatches(_ batches: [[String]], index: Int, siteURL: URL, requestsByTitle: [String: URLRequest], completion: @escaping (Error?) -> Void) {

        guard index < batches.count else {
            completion(nil)
            return
        }

        let batch = batches[index]
        imageInfoFetcher.fetchBatchedGalleryInfoJSON(forImageTitles: batch, fromSiteURL: siteURL, success: { [weak self] (result, response) in
            guard let self = self else {
                completion(nil)
                return
            }
            self.storeImageInfo(from: result, response: response, requestedTitles: batch, requestsByTitle: requestsByTitle) { error in
                if let error = error {
                    completion(error)
                    return
                }
                self.fetchImageInfoBatches(batches, index: index + 1, siteURL: siteURL, requestsByTitle: requestsByTitle, completion: completion)
            }
        }, failure: { error in
            completion(error)
        })
    }

    /// Splits one batched response and writes a cache entry per requested title,
    /// keyed by the single-title URL the gallery will later ask for.
    private func storeImageInfo(from result: [String: Any], response: HTTPURLResponse?, requestedTitles: [String], requestsByTitle: [String: URLRequest], completion: @escaping (Error?) -> Void) {

        let split: ImageInfoResponseSplitter.SplitResult
        do {
            split = try ImageInfoResponseSplitter.split(response: result, requestedTitles: requestedTitles)
        } catch let error {
            completion(error)
            return
        }

        if !split.missingTitles.isEmpty {
            // The API answering "no such page" is a legitimate answer, not a download
            // failure — a deleted or renamed file. Those entries simply stay uncached,
            // and the gallery falls back to fetching them online.
            DDLogDebug("No image info returned for: \(split.missingTitles)")
        }

        let headerFields = ImageInfoResponseSplitter.perTitleHeaderFields(from: response)
        let statusCode = response?.statusCode ?? 200

        let group = DispatchGroup()
        let errorQueue = DispatchQueue(label: "org.wikimedia.cache.imageInfoStore")
        var firstError: Error?

        for (title, body) in split.bodiesByRequestedTitle {
            guard let urlRequest = requestsByTitle[title],
                  let url = urlRequest.url,
                  let perTitleResponse = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: headerFields) else {
                continue
            }

            group.enter()
            articleFetcher.cacheResponse(httpUrlResponse: perTitleResponse, content: .data(body), urlRequest: urlRequest, success: { [weak self] in
                guard let self = self else {
                    group.leave()
                    return
                }
                self.markDownloaded(urlRequest: urlRequest, response: perTitleResponse) { markResult in
                    if case .failure(let error) = markResult {
                        errorQueue.sync { firstError = firstError ?? error }
                    }
                    group.leave()
                }
            }, failure: { error in
                errorQueue.sync { firstError = firstError ?? error }
                group.leave()
            })
        }

        group.notify(queue: DispatchQueue.global(qos: .userInitiated)) {
            completion(errorQueue.sync { firstError })
        }
    }

    func markDownloaded(urlRequest: URLRequest, response: HTTPURLResponse?, completion: @escaping (CacheDBWritingResult) -> Void) {
        
        guard let itemKey = fetcher.itemKeyForURLRequest(urlRequest) else {
            completion(.failure(CacheDBWritingMarkDownloadedError.unableToDetermineItemKey))
            return
        }
        
        let variant = fetcher.variantForURLRequest(urlRequest)
    
        context.perform {
            guard let cacheItem = CacheDBWriterHelper.cacheItem(with: itemKey, variant: nil, in: self.context) else {
                completion(.failure(CacheDBWritingMarkDownloadedError.cannotFindCacheItem))
                return
            }
            cacheItem.isDownloaded = true
                        
            let varyHeaderValue = response?.allHeaderFields[HTTPURLResponse.varyHeaderKey] as? String ?? nil
            let variesOnLanguage = varyHeaderValue?.contains(HTTPURLResponse.acceptLanguageHeaderValue) ?? false
            if variesOnLanguage {
                cacheItem.variant = variant
            }
            
            CacheDBWriterHelper.save(moc: self.context) { (result) in
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
        // maybe tonitodo: if we reach a point where we add all language variation keys to db, we should limit this based on their NSLocale language preferences.
        return true
    }
    
    func shouldDownloadVariantForAllVariantItems(variant: String?, _ allVariantItems: [CacheController.ItemKeyAndVariant]) -> Bool {
        return true
    }
}
