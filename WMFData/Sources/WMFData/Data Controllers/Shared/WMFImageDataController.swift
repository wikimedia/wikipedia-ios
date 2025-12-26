import Foundation

// MARK: - Pure Swift Actor (Clean Implementation)

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
        
        let data: Data = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
            basicService.perform(request: request) { result in
                continuation.resume(with: result)
            }
        }
        
        // Cache after receiving the data
        imageCache.setObject(data as NSData, forKey: url as NSURL)
        
        return data
    }
    
    public func fetchImageInfo(title: String, thumbnailWidth: UInt, project: WMFProject) async throws -> WMFImageInfo {
        guard let mediaWikiService else {
            throw WMFDataControllerError.mediaWikiServiceUnavailable
        }
        
        guard !title.isEmpty,
              let url = URL.mediaWikiAPIURL(project: project) else {
            throw WMFDataControllerError.failureCreatingRequestURL
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
        
        let response: ImageInfoResponse = try await withCheckedThrowingContinuation { continuation in
            mediaWikiService.performDecodableGET(request: request) { (result: Result<ImageInfoResponse, Error>) in
                continuation.resume(with: result)
            }
        }
        
        guard let firstPage = response.query.pages.values.first,
              let firstImageInfo = firstPage.imageInfo.first else {
            throw WMFDataControllerError.unexpectedResponse
        }
        
        return WMFImageInfo(title: firstPage.title, url: firstImageInfo.url, thumbURL: firstImageInfo.thumbURL)
    }
}

// MARK: - Response Types

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

// MARK: - Objective-C Bridge

@objc public final class WMFImageDataControllerObjCBridge: NSObject, @unchecked Sendable {
    
    @objc public static let shared = WMFImageDataControllerObjCBridge(controller: .shared)
    
    private let controller: WMFImageDataController
    
    public init(controller: WMFImageDataController) {
        self.controller = controller
        super.init()
    }
    
    @objc public func fetchImageData(url: URL, completion: @escaping @Sendable (Data?, Error?) -> Void) {
        let controller = self.controller
        Task {
            do {
                let data = try await controller.fetchImageData(url: url)
                completion(data, nil)
            } catch {
                completion(nil, error)
            }
        }
    }
}
