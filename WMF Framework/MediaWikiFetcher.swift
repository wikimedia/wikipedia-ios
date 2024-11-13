import Foundation
import WMFData

private extension WMFMediaWikiServiceRequest.TokenType {
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

public final class MediaWikiFetcher: Fetcher, WMFService {

    public enum MediaWikiFetcherError: LocalizedError {
        case invalidRequest
        case missingSelf
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
    
    public func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<Data, any Error>) -> Void) where R : WMFData.WMFServiceRequest {
        assertionFailure("Not implemented")
        completion(.failure(MediaWikiFetcherError.invalidRequest))
    }
    
    public func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<[String: Any]?, Error>) -> Void) {
        guard let mediaWikiRequest = request as? WMFMediaWikiServiceRequest,
              let url = request.url else {
            completion(.failure(MediaWikiFetcherError.invalidRequest))
            return
        }
        
        switch (mediaWikiRequest.method, mediaWikiRequest.backend) {
        case (.GET, .mediaWiki):
            performMediaWikiAPIGET(for: url, with: request.parameters, cancellationKey: nil, completionHandler: { result, response, error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(result))
                }
            })
        case (.POST, .mediaWiki):
            guard let tokenType = mediaWikiRequest.tokenType,
                  let stringParameters = request.parameters as? [String: String] else {
                completion(.failure(MediaWikiFetcherError.invalidRequest))
                return
            }
            
            performTokenizedMediaWikiAPIPOST(tokenType: tokenType.wmfTokenType, to: url, with: stringParameters) { [weak self] result, response, error in
                
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
        case (.PUT, .mediaWikiREST):
            if let tokenType = mediaWikiRequest.tokenType {
                requestMediaWikiAPIAuthToken(for: url, type: tokenType.wmfTokenType) { [weak self] result in
                    
                    guard let self else {
                        completion(.failure(MediaWikiFetcherError.missingSelf))
                        return
                    }
                    
                    switch result {
                    case .success(let token):
                        
                        var tokenizedParams = request.parameters ?? [:]
                        tokenizedParams["token"] = token.value
                        
                        self.performPut(url: url, parameters: tokenizedParams, completion: completion)

                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            } else {
                performPut(url: url, parameters: request.parameters, completion: completion)
            }
            
        default:
            assertionFailure("Unhandled request method")
            completion(.failure(MediaWikiFetcherError.invalidRequest))
        }
    }
    
    private func performPut(url: URL, parameters: [String: Any?]?, completion: @escaping (Result<[String: Any]?, Error>) -> Void) {
        let task = session.jsonDictionaryTask(with: url, method: .put, bodyParameters: parameters) { dict, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let response else {
                completion(.failure(RequestError.unexpectedResponse))
                return
            }
            
            guard HTTPStatusCode.isSuccessful(response.statusCode) else {
                completion(.failure(RequestError.http(response.statusCode)))
                return
            }
            
            completion(.success(dict))
        }
        task?.resume()
    }
    
    public func performDecodableGET<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        
        guard let url = request.url,
              request.method == .GET else {
            completion(.failure(MediaWikiFetcherError.invalidRequest))
            return
        }

        performDecodableMediaWikiAPIGET(for: url, with: request.parameters, completionHandler: completion)
    }
    
    public func performDecodablePOST<R, T>(request: R, completion: @escaping (Result<T, Error>) -> Void) where R : WMFData.WMFServiceRequest, T : Decodable {
        assertionFailure("Not implemented")
        completion(.failure(MediaWikiFetcherError.invalidRequest))
    }
}
