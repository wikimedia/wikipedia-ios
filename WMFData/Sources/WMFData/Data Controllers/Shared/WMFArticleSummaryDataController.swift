import Foundation

// Protocol for article summary data controlling
public protocol WMFArticleSummaryDataControlling {
    func fetchArticleSummary(project: WMFProject, title: String) async throws -> WMFArticleSummary
}

public actor WMFArticleSummaryDataController: WMFArticleSummaryDataControlling {
    private var service: WMFService?
    
    public static var shared = WMFArticleSummaryDataController()
    
    private var cache: [WMFPage: WMFArticleSummary] = [:]
    private var inFlightRequests: [WMFPage: [(Result<WMFArticleSummary, Error>) -> Void]] = [:]
    
    private init() {
        self.service = WMFDataEnvironment.current.basicService
    }
    
    public func fetchArticleSummary(project: WMFProject, title: String, completion: @escaping (Result<WMFArticleSummary, Error>) -> Void) {
        
        let wmfPage = WMFPage(namespaceID: 0, projectID: project.id, title: title)
        if let cachedSummary = cache[wmfPage] {
            completion(.success(cachedSummary))
            return
        }
        
        // Check if there's already an in-flight request for this page
        if inFlightRequests[wmfPage] != nil {
            // Queue this completion to be called when the in-flight request completes
            inFlightRequests[wmfPage]?.append(completion)
            return
        }
        
        // Initialize the in-flight request tracking with the first completion
        inFlightRequests[wmfPage] = [completion]
        
        guard let service else {
            let error = WMFDataControllerError.basicServiceUnavailable
            resolveInFlightRequests(for: wmfPage, with: .failure(error))
            return
        }

        guard !title.isEmpty,
              let url = URL.wikimediaRestAPIURL(project: project, additionalPathComponents: ["page", "summary", title.spacesToUnderscores]) else {
            let error = WMFDataControllerError.failureCreatingRequestURL
            resolveInFlightRequests(for: wmfPage, with: .failure(error))
            return
        }

        let request = WMFBasicServiceRequest(url: url, method: .GET, languageVariantCode: project.languageVariantCode, acceptType: .json)
        service.performDecodableGET(request: request) { [weak self] (result: Result<WMFArticleSummary, Error>) in
            switch result {
            case .success(let summary):
                
                Task { [weak self] in
                    guard let self else { return }
                    await self.updateCache(page: wmfPage, summary: summary)
                    await self.resolveInFlightRequests(for: wmfPage, with: result)
                }
                
            case .failure:
                Task { [weak self] in
                    guard let self else { return }
                    await self.resolveInFlightRequests(for: wmfPage, with: result)
                }
            }
        }
    }
    
    private func updateCache(page: WMFPage, summary: WMFArticleSummary) {
        cache[page] = summary
    }
    
    private func resolveInFlightRequests(for page: WMFPage, with result: Result<WMFArticleSummary, Error>) {
        guard let completions = inFlightRequests[page] else { return }
        inFlightRequests.removeValue(forKey: page)
        
        // Call all waiting completions with the result
        for completion in completions {
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
