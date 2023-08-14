import Foundation
import WKData

private extension WKNetworkRequest.TokenType {
    var wmfTokenType: TokenType {
        switch self {
        case .csrf:
            return .csrf
        case .watch:
            return .watch
        case .rollback:
            return .rollback
        }
    }
}

public final class MediaWikiNetworkService: Fetcher, WKNetworkService {

    public enum ServiceError: LocalizedError {
        case invalidRequest
        case mediaWikiError(MediaWikiAPIDisplayError)
        
        public var errorDescription: String? {
            switch self {
            case .mediaWikiError(let displayError):
                return displayError.messageHtml
            default:
                return CommonStrings.genericErrorDescription
            }
        }
        
        public var mediaWikiDisplayError: MediaWikiAPIDisplayError? {
            switch self {
            case .mediaWikiError(let displayError):
                return displayError
            default:
                return nil
            }
        }
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
            
            performTokenizedMediaWikiAPIPOST(tokenType: tokenType.wmfTokenType, to: url, with: stringParamters) { [weak self] result, response, error in
                
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let result,
                let self else {
                    completion(.success(result))
                    return
                }
                
                self.resolveMediaWikiApiErrorFromResult(result, siteURL: url) { displayError in
                    if let displayError {
                        completion(.failure(ServiceError.mediaWikiError(displayError)))
                    } else {
                        completion(.success(result))
                    }
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
