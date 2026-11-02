import Foundation

/// Fetches the views on the pages a user edited, across all Wikimedia projects, from the metrics API.
final class WMFGlobalEditedPageViewsDataController {

    private let globalUserID: Int

    private let service: WMFService?

    init(globalUserID: Int, service: WMFService? = WMFDataEnvironment.current.basicService) {
        self.globalUserID = globalUserID
        self.service = service
    }

    /// The total views in the period. The API counts whole months, so the end date is the first month not counted.
    func fetchViewCount(startDate: Date, endDate: Date) async throws -> Int {
        guard let service = service else {
            throw WMFDataControllerError.basicServiceUnavailable
        }

        guard let baseURL = URL.metricsAPIURL() else {
            throw WMFDataControllerError.failureCreatingRequestURL
        }

        let dateFormatter = DateFormatter.metricsAPIDateFormatter

        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)

        let finalURL = baseURL.appending(path: "pageviews/v3/per_editor/\(globalUserID)/monthly/\(startDateString)/\(endDateString)", directoryHint: .inferFromPath)

        let request = WMFBasicServiceRequest(url: finalURL, method: .GET, contentType: .json, acceptType: .json)

        let response: MetricsEditedPageViewsAPIResponse = try await withCheckedThrowingContinuation { continuation in
            service.performDecodableGET(request: request) { (result: Result<MetricsEditedPageViewsAPIResponse, Error>) in
                continuation.resume(with: result)
            }
        }
        return response.items.reduce(0) { $0 + $1.viewCount }
    }
}
