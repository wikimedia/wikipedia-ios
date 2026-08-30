import Foundation

public actor WMFImageDataController {
    public static let shared = WMFImageDataController()
    // `var` (not `let`) so the @_spi(Testing) reset() below can reassign them.
    // Safe: they are actor-isolated state.
    private var basicService: WMFService?
    private var mediaWikiService: WMFService?
    private let imageCache = NSCache<NSURL, NSData>()

    /// The callers that wait for a download that is already in flight. The first caller for a URL
    /// puts an empty array here. Each later caller for the same URL adds its continuation. The
    /// first caller resumes them all when the download ends.
    private var waitersForInFlightURLs: [URL: [CheckedContinuation<Data, Error>]] = [:]

    public init(basicService: WMFService? = WMFDataEnvironment.current.basicService, mediaWikiService: WMFService? = WMFDataEnvironment.current.mediaWikiService) {
        self.basicService = basicService
        self.mediaWikiService = mediaWikiService
        imageCache.totalCostLimit = 50_000_000
    }

    public func fetchImageData(url: URL) async throws -> Data {

        if let cachedData = imageCache.object(forKey: url as NSURL) {
            return cachedData as Data
        }

        // Merge concurrent requests for the same URL. A prefetch and an on-screen request
        // must share one download.
        if waitersForInFlightURLs[url] != nil {
            return try await withCheckedThrowingContinuation { continuation in
                waitersForInFlightURLs[url]?.append(continuation)
            }
        }

        guard let basicService else {
            throw WMFDataControllerError.basicServiceUnavailable
        }

        waitersForInFlightURLs[url] = []
        let request = WMFBasicServiceRequest(url: url, method: .GET, acceptType: .none)

        // The service is still completion-based; bridge it to async via a continuation.
        do {
            let data: Data = try await withCheckedThrowingContinuation { continuation in
                basicService.perform(request: request) { result in
                    continuation.resume(with: result)
                }
            }

            // The cache write happens after the await, back on the actor, so `imageCache`
            // stays actor-isolated and no nonisolated/Sendable workaround is needed.
            imageCache.setObject(data as NSData, forKey: url as NSURL, cost: data.count)
            resumeWaiters(for: url, with: .success(data))
            return data
        } catch {
            resumeWaiters(for: url, with: .failure(error))
            throw error
        }
    }

    private func resumeWaiters(for url: URL, with result: Result<Data, Error>) {
        let waiters = waitersForInFlightURLs[url] ?? []
        waitersForInFlightURLs[url] = nil
        for waiter in waiters {
            waiter.resume(with: result)
        }
    }

    public func fetchImageInfo(title: String, thumbnailWidth: UInt, project: WMFProject, completion: @escaping @Sendable (Result<WMFImageInfo, Error>) -> Void) {
        guard let mediaWikiService else {
            completion(.failure(WMFDataControllerError.mediaWikiServiceUnavailable))
            return
        }
        
        guard !title.isEmpty,
              let url = URL.mediaWikiAPIURL(project: project) else {
            completion(.failure(WMFDataControllerError.failureCreatingRequestURL))
            return
        }
        
        let parameters: [String: Any] = [
            "action": "query",
            "titles": title,
            "prop": "imageinfo",
            "iiprop": "url",
            "iiurlwidth": thumbnailWidth,
            "format": "json"
        ]
        
        let request = WMFMediaWikiServiceRequest(url: url, method: .GET, backend: .mediaWiki, parameters: parameters)
        mediaWikiService.performDecodableGET(request: request) { (result: Result<ImageInfoResponse, Error>) in
            switch result {
            case .success(let response):
                
                guard let firstPage = response.query.pages.values.first,
                      let firstImageInfo = firstPage.imageInfo.first else {
                    completion(.failure(WMFDataControllerError.unexpectedResponse))
                    return
                }
                
                completion(.success(WMFImageInfo(title: firstPage.title, url: firstImageInfo.url, thumbURL: firstImageInfo.thumbURL)))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    @_spi(Testing) public func reset() {
        basicService = WMFDataEnvironment.current.basicService
        mediaWikiService = WMFDataEnvironment.current.mediaWikiService
        imageCache.removeAllObjects()
        // A continuation must always resume. Fail the waiters instead of a silent drop.
        for url in waitersForInFlightURLs.keys {
            resumeWaiters(for: url, with: .failure(WMFDataControllerError.basicServiceUnavailable))
        }
    }
}

private extension WMFImageDataController {
    struct ImageInfoResponse: Codable {
        
        public struct Query: Codable {
            
            public struct Page: Codable {
                
                public struct ImageInfo: Codable {
                    let url: URL
                    let thumbURL: URL
                    
                    enum CodingKeys: String, CodingKey {
                        case url = "url"
                        case thumbURL = "thumburl"
                    }
                }
                let title: String
                let imageInfo: [ImageInfo]
                
                enum CodingKeys: String, CodingKey {
                    case title = "title"
                    case imageInfo = "imageinfo"
                }
            }
            
            let pages: [String: Page]
        }
        
        let query: Query
    }
}
