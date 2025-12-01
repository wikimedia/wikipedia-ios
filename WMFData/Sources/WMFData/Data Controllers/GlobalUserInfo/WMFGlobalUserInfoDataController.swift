import Foundation

actor WMFGlobalUserInfoDataController {
    private var service = WMFDataEnvironment.current.mediaWikiService
    let project: WMFProject

    init(project: WMFProject) {
        self.project = project
    }

    func fetchGlobalUserInfo() async throws -> GlobalUserInfo {

        guard let service else {
            throw WMFDataControllerError.mediaWikiServiceUnavailable
        }

        let parameters: [String: Any] = [
            "action": "query",
            "meta": "globaluserinfo",
            "guiprop": "editcount",
            "format": "json",
            "formatversion": "2"
        ]

        guard let url = URL.mediaWikiAPIURL(project: project) else {
            throw WMFDataControllerError.failureCreatingRequestURL
        }

        let request = WMFMediaWikiServiceRequest(url: url, method: .GET, backend: .mediaWiki, parameters: parameters)
        let response = try await fetchResponse(request: request, service: service)

        return response.query.globaluserinfo

    }

    func fetchResponse(request: WMFServiceRequest, service: WMFService) async throws -> GlobalUserInfoResponse {
        try await withCheckedThrowingContinuation { continuation in
            service.performDecodableGET(request: request) { (result: Result<GlobalUserInfoResponse, Error>) in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

}
