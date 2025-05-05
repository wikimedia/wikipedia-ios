import Foundation

// Protocol for article summary data controlling
public protocol WMFArticleSummaryDataControlling {
    func fetchArticleSummary(project: WMFProject, title: String) async throws -> WMFArticleSummary
}

public final class WMFArticleSummaryDataController: WMFArticleSummaryDataControlling {
    private var service: WMFService?
    
    public init() {
        self.service = WMFDataEnvironment.current.basicService
    }
    
    public func fetchArticleSummary(project: WMFProject, title: String, completion: @escaping (Result<WMFArticleSummary, Error>) -> Void) {
        
        guard let service else {
            completion(.failure(WMFDataControllerError.basicServiceUnavailable))
            return
        }

        guard !title.isEmpty,
              let url = URL.wikimediaRestAPIURL(project: project, additionalPathComponents: ["page", "summary", title.spacesToUnderscores]) else {
            completion(.failure(WMFDataControllerError.failureCreatingRequestURL))
            return
        }

        let request = WMFBasicServiceRequest(url: url, method: .GET, languageVariantCode: project.languageVariantCode, acceptType: .json)
        service.performDecodableGET(request: request) { (result: Result<WMFArticleSummary, Error>) in
            completion(result)
        }
    }
    
    public func fetchArticleSummary(project: WMFProject, title: String) async throws -> WMFArticleSummary {
        return try await withCheckedThrowingContinuation { continuation in
            fetchArticleSummary(project: project, title: title) { result in
                switch result {
                case .success(let successResult):
                    continuation.resume(returning: successResult)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
