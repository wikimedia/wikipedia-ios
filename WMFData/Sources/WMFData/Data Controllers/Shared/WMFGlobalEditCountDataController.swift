import Foundation

actor WMFGlobalEditCountDataController {
    
    private let globalUserID: Int
    
    private let service: WMFService?
    
    init(globalUserID: Int, service: WMFService? = WMFDataEnvironment.current.basicService) {
        self.globalUserID = globalUserID
        self.service = service
    }
    
    func fetchEditCount(globalUserID: Int, startDate: Date, endDate: Date) async throws -> Int {
        guard let service = service else {
            throw WMFDataControllerError.basicServiceUnavailable
        }
        
        guard let baseURL = URL.metricsAPIURL() else {
            throw WMFDataControllerError.failureCreatingRequestURL
        }
        
        let dateFormatter = DateFormatter.metricsAPIDateFormatter
        
        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)
        
        let finalURL = baseURL.appending(path: "edits/v3/per_editor/\(globalUserID)/all_page_types/monthly/\(startDateString)/\(endDateString)", directoryHint: .inferFromPath)
        
        let request = WMFBasicServiceRequest(url: finalURL, method: .GET, contentType: .json, acceptType: .json)
        
        let response: MetricsEditCountAPIRResponse = try await withCheckedThrowingContinuation { continuation in
            service.performDecodableGET(request: request) { (result: Result<MetricsEditCountAPIRResponse, Error>) in
                continuation.resume(with: result)
            }
        }
        
        return response.items.reduce(0) { $0 + $1.editCount }
    }
}

// MARK: - Sync Bridge Extension

extension WMFGlobalEditCountDataController {
    
    nonisolated func fetchEditCountSyncBridge(globalUserID: Int, startDate: Date, endDate: Date, completion: @escaping @Sendable (Result<Int, Error>) -> Void) {
        Task {
            do {
                let count = try await self.fetchEditCount(globalUserID: globalUserID, startDate: startDate, endDate: endDate)
                completion(.success(count))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
