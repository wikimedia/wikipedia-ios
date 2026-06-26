import Foundation

public actor WMFImageDataController {
    public static let shared = WMFImageDataController()
    private let basicService: WMFService?
    private let mediaWikiService: WMFService?
    private let imageCache = NSCache<NSURL, NSData>()
    
    public init(basicService: WMFService? = WMFDataEnvironment.current.basicService, mediaWikiService: WMFService? = WMFDataEnvironment.current.mediaWikiService) {
        self.basicService = basicService
        self.mediaWikiService = mediaWikiService
    }
    
    public func fetchImageData(url: URL) async throws -> Data {

        if let cachedData = imageCache.object(forKey: url as NSURL) {
            return cachedData as Data
        }

        guard let basicService else {
            throw WMFDataControllerError.basicServiceUnavailable
        }

        let request = WMFBasicServiceRequest(url: url, method: .GET, acceptType: .none)

        // The service is still completion-based; bridge it to async via a continuation.
        // The cache write happens after the await, back on the actor, so `imageCache`
        // stays actor-isolated and no nonisolated/Sendable workaround is needed.
        let data: Data = try await withCheckedThrowingContinuation { continuation in
            basicService.perform(request: request) { result in
                continuation.resume(with: result)
            }
        }

        imageCache.setObject(data as NSData, forKey: url as NSURL)
        return data
    }

    public func fetchImageInfo(title: String, thumbnailWidth: UInt, project: WMFProject, completion: @escaping (Result<WMFImageInfo, Error>) -> Void) {
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
