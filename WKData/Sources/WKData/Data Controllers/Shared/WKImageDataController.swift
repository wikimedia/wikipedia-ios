import Foundation

public final class WKImageDataController {
    private var service: WKService?
    
    public init() {
        self.service = WKDataEnvironment.current.basicService
    }
    
    public func fetchImageData(url: URL, completion: @escaping (Result<Data, Error>) -> Void) {
        
        guard let service else {
            completion(.failure(WKDataControllerError.basicServiceUnavailable))
            return
        }

        let request = WKBasicServiceRequest(url: url, method: .GET, acceptType: .none)
        service.perform(request: request, completion: completion)
    }
}
