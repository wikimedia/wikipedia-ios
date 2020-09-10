
import Foundation

public class SignificantEventsController {
    
    public enum Errors: Error {
        case viewModelInstantiationFailure
    }
    
    public init() {
        
    }
    
    private let fetcher = SignificantEventsFetcher()
    
    public func fetchSignificantEvents(rvStartId: UInt? = nil, title: String, siteURL: URL, completion: @escaping ((Result<SignificantEventsViewModel, Error>) -> Void)) {
        fetcher.fetchSignificantEvents(rvStartId: rvStartId, title: title, siteURL: siteURL) { (result) in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            case .success(let significantEvents):
                if let viewModel = SignificantEventsViewModel(significantEvents: significantEvents) {
                    DispatchQueue.main.async {
                        completion(.success(viewModel))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(SignificantEventsController.Errors.viewModelInstantiationFailure))
                    }
                }
            }
        }
    }
    
    public func fetchEditMetrics(for pageTitle: String, pageURL: URL, completion: @escaping (Result<[NSNumber], Error>) -> Void ) {
        fetcher.fetchEditMetrics(for: pageTitle, pageURL: pageURL) { (result) in
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
}
