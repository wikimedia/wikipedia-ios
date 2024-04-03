import Foundation

public final class WKArticleSummaryDataController {
    private var service: WKService?
    
    public init() {
        self.service = WKDataEnvironment.current.basicService
    }
    
    public func fetchArticleSummary(project: WKProject, title: String, completion: @escaping (Result<WKArticleSummary, Error>) -> Void) {
        
        guard let service else {
            completion(.failure(WKDataControllerError.basicServiceUnavailable))
            return
        }

        guard !title.isEmpty,
              let url = URL.wikimediaRestAPIURL(project: project, additionalPathComponents: ["page", "summary", title.spacesToUnderscores]) else {
            completion(.failure(WKDataControllerError.failureCreatingRequestURL))
            return
        }

        let request = WKBasicServiceRequest(url: url, method: .GET, languageVariantCode: project.languageVariantCode, acceptType: .json)
        service.performDecodableGET(request: request) { (result: Result<WKArticleSummary, Error>) in
            completion(result)
        }
    }
}
