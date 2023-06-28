import Foundation
import WKData

private extension WKNetworkRequest.TokenType {
    var wmfTokenType: TokenType {
        switch self {
        case .watch:
            return .watch
        case .rollback:
            return .rollback
        }
    }
}

public final class MediaWikiNetworkService: Fetcher, WKNetworkService {

    enum ServiceError: Error {
        case invalidRequest
    }

    public func perform(request: WKNetworkRequest, tokenType: WKNetworkRequest.TokenType?, completion: @escaping (Result<[String: Any]?, Error>) -> Void) {
        guard let url = request.url else {
            completion(.failure(ServiceError.invalidRequest))
            return
        }
        
        switch request.method {
        case .GET:
            performMediaWikiAPIGET(for: url, with: request.parameters, cancellationKey: nil, completionHandler: { result, response, error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(result))
                }
            })
        case .POST:
            guard let tokenType,
                  let stringParamters = request.parameters as? [String: String] else {
                completion(.failure(ServiceError.invalidRequest))
                return
            }
            
            performTokenizedMediaWikiAPIPOST(tokenType: tokenType.wmfTokenType, to: url, with: stringParamters) { result, response, error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(result))
                }
            }
        default:
            assertionFailure("Unhandled request method")
        }
    }
    
    public func performDecodableGET<T>(request: WKData.WKNetworkRequest, completion: @escaping (Result<T, Error>) -> Void) where T : Decodable {
        
        guard let url = request.url,
              request.method == .GET else {
            completion(.failure(ServiceError.invalidRequest))
            return
        }

        performDecodableMediaWikiAPIGET(for: url, with: request.parameters, completionHandler: completion)
    }
}
