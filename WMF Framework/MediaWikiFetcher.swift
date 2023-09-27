import Foundation
import WKData

private extension WKMediaWikiServiceRequest.TokenType {
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

public final class MediaWikiFetcher: Fetcher, WKService {

    public enum MediaWikiFetcherError: LocalizedError {
        case invalidRequest
        case mediaWikiAPIResponseError(MediaWikiAPIDisplayError)
        
        public var errorDescription: String? {
            switch self {
            case .mediaWikiAPIResponseError(let displayError):
                return displayError.messageHtml
            default:
                return CommonStrings.genericErrorDescription
            }
        }
        
        public var mediaWikiDisplayError: MediaWikiAPIDisplayError? {
            switch self {
            case .mediaWikiAPIResponseError(let displayError):
                return displayError
            default:
                return nil
            }
        }
    }
    
    public func perform<R: WKServiceRequest>(request: R, completion: @escaping (Result<[String: Any]?, Error>) -> Void) {
        guard let mediaWikiRequest = request as? WKMediaWikiServiceRequest,
              let url = request.url,
            let tokenType = mediaWikiRequest.tokenType else {
            completion(.failure(MediaWikiFetcherError.invalidRequest))
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
            guard let stringParamters = request.parameters as? [String: String] else {
                completion(.failure(MediaWikiFetcherError.invalidRequest))
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
                        completion(.failure(MediaWikiFetcherError.mediaWikiAPIResponseError(displayError)))
                    } else {
                        completion(.success(result))
                    }
                }
            }
        default:
            assertionFailure("Unhandled request method")
        }
    }
    
    public func performDecodableGET<R: WKServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        
        guard let url = request.url,
              request.method == .GET else {
            completion(.failure(MediaWikiFetcherError.invalidRequest))
            return
        }

        performDecodableMediaWikiAPIGET(for: url, with: request.parameters, completionHandler: completion)
    }
    
    public func performDecodablePOST<R, T>(request: R, completion: @escaping (Result<T, Error>) -> Void) where R : WKData.WKServiceRequest, T : Decodable {
        assertionFailure("Not implemented")
        completion(.failure(RequestError.unknown))
    }
}
