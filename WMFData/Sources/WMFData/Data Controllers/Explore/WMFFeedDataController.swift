import Foundation

public final class WMFFeedDataController {

    private var basicService: WMFService?

    public static let shared = WMFFeedDataController()

    public init(basicService: WMFService? = WMFDataEnvironment.current.basicService) {
        self.basicService = basicService
    }

    // MARK: - Fetch

    public func fetchFeed(project: WMFProject, date: Date, completion: @escaping (Result<WMFFeedAPIResponse, Error>) -> Void) {
        guard let basicService else {
            completion(.failure(WMFDataControllerError.basicServiceUnavailable))
            return
        }

        guard let url = feedURL(project: project, date: date) else {
            completion(.failure(WMFDataControllerError.failureCreatingRequestURL))
            return
        }

        let request = WMFBasicServiceRequest(url: url, method: .GET, parameters: [:], acceptType: .json)
        basicService.performDecodableGET(request: request) { (result: Result<WMFFeedAPIResponse, Error>) in
            completion(result)
        }
    }

    // MARK: - Private

    private func feedURL(project: WMFProject, date: Date) -> URL? {
        guard case .wikipedia(let language) = project else {
            return nil
        }

        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        guard let year = components.year,
              let month = components.month,
              let day = components.day else {
            return nil
        }

        let monthString = String(format: "%02d", month)
        let dayString = String(format: "%02d", day)

        return URL(string: "https://\(language.languageCode).wikipedia.org/api/rest_v1/feed/featured/\(year)/\(monthString)/\(dayString)")
    }
}
