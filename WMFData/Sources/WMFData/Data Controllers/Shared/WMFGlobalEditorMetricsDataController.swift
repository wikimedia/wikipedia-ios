import Foundation

/// Fetches the monthly per-editor metrics of a global user, across all Wikimedia projects, from the metrics API.
/// The API counts whole months, so the end date is the first month not counted.
final class WMFGlobalEditorMetricsDataController {
    
    private let globalUserID: Int
    
    private let service: WMFService?
    
    init(globalUserID: Int, service: WMFService? = WMFDataEnvironment.current.basicService) {
        self.globalUserID = globalUserID
        self.service = service
    }
    
    /// The edits the user made in the period.
    func fetchEditCount(startDate: Date, endDate: Date) async throws -> Int {
        let response: MetricsEditCountAPIRResponse = try await fetch(pathPrefix: "edits/v3/per_editor/\(globalUserID)/all_page_types/monthly", startDate: startDate, endDate: endDate)
        return response.items.reduce(0) { $0 + $1.editCount }
    }
    
    /// The views in the period on the pages the user edited.
    func fetchEditedPageViewCount(startDate: Date, endDate: Date) async throws -> Int {
        let response: MetricsEditedPageViewsAPIResponse = try await fetch(pathPrefix: "pageviews/v3/per_editor/\(globalUserID)/monthly", startDate: startDate, endDate: endDate)
        return response.items.reduce(0) { $0 + $1.viewCount }
    }
    
    private func fetch<Response: Decodable & Sendable>(pathPrefix: String, startDate: Date, endDate: Date) async throws -> Response {
        guard let service = service else {
            throw WMFDataControllerError.basicServiceUnavailable
        }
        
        guard let baseURL = URL.metricsAPIURL() else {
            throw WMFDataControllerError.failureCreatingRequestURL
        }
        
        let dateFormatter = DateFormatter.metricsAPIDateFormatter
        
        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)
        
        let finalURL = baseURL.appending(path: "\(pathPrefix)/\(startDateString)/\(endDateString)", directoryHint: .inferFromPath)
        
        let request = WMFBasicServiceRequest(url: finalURL, method: .GET, contentType: .json, acceptType: .json)
        
        return try await withCheckedThrowingContinuation { continuation in
            service.performDecodableGET(request: request) { (result: Result<Response, Error>) in
                continuation.resume(with: result)
            }
        }
    }
}
