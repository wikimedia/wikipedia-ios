import Foundation

final class WMFGlobalEditCountDataController {
    
    private let globalUserID: Int
    
    private let service: WMFService?
    
    init(globalUserID: Int, service: WMFService? = WMFDataEnvironment.current.basicService) {
        self.globalUserID = globalUserID
        self.service = service
    }
    
    func fetchEditCount(startDate: Date, endDate: Date) async throws -> Int {
        return try await withCheckedThrowingContinuation { continuation in
            fetchEditCount(startDate: startDate, endDate: endDate) { result in
                switch result {
                case .success(let successResult):
                    continuation.resume(returning: successResult)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func fetchEditCount(startDate: Date, endDate: Date, completion: @escaping (Result<Int, Error>) -> Void) {
        guard let service = service else {
            completion(.failure(WMFDataControllerError.basicServiceUnavailable))
            return
        }
        
        guard let baseURL = URL.metricsAPIURL() else {
            completion(.failure(WMFDataControllerError.failureCreatingRequestURL))
            return
        }
        
        let dateFormatter = DateFormatter.metricsAPIDateFormatter
        
        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)
        
        let finalURL = baseURL.appending(path: "edits/v3/per_editor/\(globalUserID)/all_page_types/monthly/\(startDateString)/\(endDateString)", directoryHint: .inferFromPath)
        
        let request = WMFBasicServiceRequest(url: finalURL, method: .GET, contentType: .json, acceptType: .json)
        
        service.performDecodableGET(request: request) { (result: Result<MetricsEditCountAPIRResponse, Error>) in
            switch result {
            case .success(let response):
                let count = response.items.reduce(0) { $0 + $1.editCount }
                completion(.success(count))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
