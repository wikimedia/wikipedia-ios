
import Foundation
import WMF

class SignificantEventsController {
    
    enum Errors: Error {
        case viewModelInstantiationFailure
    }
    
    private let fetcher = SignificantEventsFetcher()
    
    func fetchSignificantEvents(rvStartId: UInt? = nil, title: String, siteURL: URL, completion: @escaping ((Result<SignificantEventsViewModel, Error>) -> Void)) {
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
}
