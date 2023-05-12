import Foundation
import WMF
import WKData

final class MediawikiNetworkService: Fetcher, WKNetworkService {

    enum ServiceError: Error {
        case failed
    }

    func perform(request: WKNetworkRequest, completion: @escaping (Result<[String: Any]?, Error>) -> Void) {
        guard let url = request.url else {
            completion(.failure(ServiceError.failed))
            return
        }

        performMediaWikiAPIGET(for: url, with: request.parameters, cancellationKey: nil, completionHandler: { result, response, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(result))
            }
        })
    }

}
