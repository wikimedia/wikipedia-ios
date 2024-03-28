import Foundation

public final class WKImageDataController {
    private var service: WKService?
    private let imageCache = NSCache<NSURL, NSData>()
    
    public init() {
        self.service = WKDataEnvironment.current.basicService
    }
    
    public func fetchImageData(url: URL, completion: @escaping (Result<Data, Error>) -> Void) {
        
        guard let service else {
            completion(.failure(WKDataControllerError.basicServiceUnavailable))
            return
        }
        
        if let cachedData = imageCache.object(forKey: url as NSURL) {
            completion(.success(cachedData as Data))
            return
        }

        let request = WKBasicServiceRequest(url: url, method: .GET, acceptType: .none)

        service.perform(request: request) { [weak self] result in
            switch result {
            case .success(let data):
                self?.imageCache.setObject(data as NSData, forKey: url as NSURL)
            default:
                break
            }
            
            completion(result)
        }
    }
}
