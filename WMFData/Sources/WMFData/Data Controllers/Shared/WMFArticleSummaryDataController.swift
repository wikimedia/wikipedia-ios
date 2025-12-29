import Foundation

// Protocol for article summary data controlling
public protocol WMFArticleSummaryDataControlling {
    func fetchArticleSummary(project: WMFProject, title: String) async throws -> WMFArticleSummary
}

public actor WMFArticleSummaryDataController: WMFArticleSummaryDataControlling {
    private var service: WMFService?
    
    public static var shared = WMFArticleSummaryDataController()
    
    private var cache: [WMFPage: WMFArticleSummary] = [:]
    
    public init() {
        self.service = WMFDataEnvironment.current.basicService
    }
    
    public func fetchArticleSummary(project: WMFProject, title: String, completion: @escaping @Sendable (Result<WMFArticleSummary, Error>) -> Void) {
        
        let wmfPage = WMFPage(namespaceID: 0, projectID: project.id, title: title)
        if let cachedSummary = cache[wmfPage] {
            completion(.success(cachedSummary))
            return
        }
        
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
        service.performDecodableGET(request: request) { [weak self] (result: Result<WMFArticleSummary, Error>) in
            switch result {
            case .success(let summary):
                
                Task { [weak self] in
                    guard let self else { return }
                    await self.updateCache(page: wmfPage, summary: summary)
                }
                
            default:
                break
            }
            
            completion(result)
        }
    }
    
    private func updateCache(page: WMFPage, summary: WMFArticleSummary) {
        cache[page] = summary
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
