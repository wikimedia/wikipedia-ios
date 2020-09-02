
import Foundation

enum SignificantEventsFetcherError: Error {
    case failureToGenerateURL
    case missingSignificantEvents
}

public class SignificantEventsFetcher: Fetcher {
    
    public func fetchSignificantEvents(rvStartId: UInt? = nil, title: String, siteURL: URL, completion: @escaping ((Result<SignificantEvents, Error>) -> Void)) {
       
        guard let url = significantEventsURL(rvStartId: rvStartId, title: title, siteURL: siteURL) else {
            completion(.failure(SignificantEventsFetcherError.failureToGenerateURL))
            return
        }
        
        session.jsonDecodableTask(with: url) { (significantEvents: SignificantEvents?, response: URLResponse?, error: Error?) in
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let statusCode = (response as? HTTPURLResponse)?.statusCode,
                statusCode != 200 {
                completion(.failure(RequestError.unexpectedResponse))
                return
            }
            
            guard let significantEvents = significantEvents else {
                completion(.failure(SignificantEventsFetcherError.missingSignificantEvents))
                return
            }
            
            completion(.success(significantEvents))
        }
        
    }
    
    private func significantEventsURL(rvStartId: UInt? = nil, title: String, siteURL: URL) -> URL? {
        let labsHost = "mobileapps-ios-experiments.wmflabs.org"
        guard let siteHost = siteURL.host else {
            return nil
        }

        let pathComponents = [siteHost, "v1", "page", "significant-events", title]
        var components = URLComponents()
        components.host = labsHost
        components.scheme = "https"
        components.replacePercentEncodedPathWithPathComponents(pathComponents)
        if let rvStartId = rvStartId {
            let queryParameters = ["rvStartId": rvStartId]
            components.replacePercentEncodedQueryWithQueryParameters(queryParameters)
        }
        
        return components.url
    }
}
