
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
        
        let request = URLRequest(url: url)
        
        let _ = session.jsonDecodableTask(with: request) { (significantEvents: SignificantEvents?, response, error) in
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
        guard let siteHost = siteURL.host,
              let percentEncodedTitle = title.percentEncodedPageTitleForPathComponents else {
            return nil
        }

        let pathComponents = [siteHost, "v1", "page", "significant-events", percentEncodedTitle]
        var components = URLComponents()
        components.host = labsHost
        components.scheme = "https"
        components.replacePercentEncodedPathWithPathComponents(pathComponents)
        if let rvStartId = rvStartId {
            let queryParameters = ["rvstartid": rvStartId]
            components.replacePercentEncodedQueryWithQueryParameters(queryParameters)
        }
        
        return components.url
    }
    
    private struct EditMetrics: Decodable {
        let items: [Item]?

        struct Item: Decodable {
            let results: [Result]?

            struct Result: Decodable {
                let edits: Int?
            }
        }
    }
    
    public func fetchEditMetrics(for pageTitle: String, pageURL: URL, completion: @escaping (Result<[NSNumber], Error>) -> Void ) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard
                let title = pageTitle.percentEncodedPageTitleForPathComponents,
                let project = pageURL.wmf_site?.host,
                let daysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()),
                let from = DateFormatter.wmf_englishUTCNonDelimitedYearMonthDay()?.string(from: daysAgo),
                let to = DateFormatter.wmf_englishUTCNonDelimitedYearMonthDay()?.string(from: Date())
            else {
                completion(.failure(RequestError.invalidParameters))
                return
            }
            let pathComponents = ["edits", "per-page", project, title, "all-editor-types", "daily", from, to]
            let components =  self.configuration.metricsAPIURLComponents(appending: pathComponents)
            guard let url = components.url else {
                completion(.failure(RequestError.invalidParameters))
                return
            }
            self.session.jsonDecodableTask(with: url) { (editMetrics: EditMetrics?, response: URLResponse?, error: Error?) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    completion(.failure(RequestError.unexpectedResponse))
                    return
                }
                var allEdits = [NSNumber]()
                guard
                    let items = editMetrics?.items,
                    let firstItem = items.first,
                    let results = firstItem.results
                else {
                    completion(.failure(RequestError.noNewData))
                    return
                }
                for case let result in results {
                    guard let edits = result.edits else {
                        continue
                    }
                    allEdits.append(NSNumber(value: edits))
                }
                completion(.success(allEdits))
            }
        }
    }
}
