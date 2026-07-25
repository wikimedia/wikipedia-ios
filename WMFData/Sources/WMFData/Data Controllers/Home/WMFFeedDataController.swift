import Foundation

public protocol WMFFeedDataControlling: Sendable {
    func fetchFeed(project: WMFProject, date: Date) async throws -> WMFFeedAPIResponse
}

public final actor WMFFeedDataController: WMFFeedDataControlling {

    private let basicService: WMFService?

    public static let shared = WMFFeedDataController()

    public init(basicService: WMFService? = WMFDataEnvironment.current.basicService) {
        self.basicService = basicService
    }

    // MARK: - Fetch

    public func fetchFeed(project: WMFProject, date: Date, completion: @escaping @Sendable (Result<WMFFeedAPIResponse, Error>) -> Void) {
        guard let basicService else {
            completion(.failure(WMFDataControllerError.basicServiceUnavailable))
            return
        }

        guard case .wikipedia = project else {
            completion(.failure(WMFDataControllerError.unsupportedProject))
            return
        }

        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        guard let year = components.year,
              let month = components.month,
              let day = components.day,
              let url = URL.wikimediaRestAPIURL(
                project: project,
                additionalPathComponents: [
                    "feed", "featured",
                    String(year),
                    String(format: "%02d", month),
                    String(format: "%02d", day)
                ]
              ) else {
            completion(.failure(WMFDataControllerError.failureCreatingRequestURL))
            return
        }

        let request = WMFBasicServiceRequest(url: url, method: .GET, languageVariantCode: project.languageVariantCode, parameters: [:], acceptType: .json)
        basicService.performDecodableGET(request: request) { (result: Result<WMFFeedAPIResponse, Error>) in
            completion(result)
        }
    }
    
    // Add async throws option
    public func fetchFeed(project: WMFProject, date: Date) async throws -> WMFFeedAPIResponse {
        try await withCheckedThrowingContinuation { continuation in
            fetchFeed(project: project, date: date) { result in
                continuation.resume(with: result)
            }
        }
    }
}
