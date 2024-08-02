import Foundation

public final class WMFImageDataController {
    private var service: WMFService?
    private let imageCache = NSCache<NSURL, NSData>()
    
    public init(service: WMFService? = WMFDataEnvironment.current.basicService) {
        self.service = service
    }
    
    public func fetchImageData(url: URL, completion: @escaping (Result<Data, Error>) -> Void) {
        
        if let cachedData = imageCache.object(forKey: url as NSURL) {
            completion(.success(cachedData as Data))
            return
        }
        
        guard let service else {
            completion(.failure(WMFDataControllerError.basicServiceUnavailable))
            return
        }

        let request = WMFBasicServiceRequest(url: url, method: .GET, acceptType: .none)

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
