
import Foundation

public class ArticleAsLivingDocController {
    
    public enum Errors: Error {
        case viewModelInstantiationFailure
    }
    
    public init() {
        
    }
    
    private let fetcher = SignificantEventsFetcher()
    
    public func fetchArticleAsLivingDocViewModel(rvStartId: UInt? = nil, title: String, siteURL: URL, completion: @escaping ((Result<ArticleAsLivingDocViewModel, Error>) -> Void)) {
        fetcher.fetchSignificantEvents(rvStartId: rvStartId, title: title, siteURL: siteURL) { (result) in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            case .success(let significantEvents):
                if let viewModel = ArticleAsLivingDocViewModel(significantEvents: significantEvents) {
                    DispatchQueue.main.async {
                        completion(.success(viewModel))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(ArticleAsLivingDocController.Errors.viewModelInstantiationFailure))
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
