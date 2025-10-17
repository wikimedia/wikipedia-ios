import CoreData

final class YearInReviewViewCountSlideDataController: YearInReviewSlideDataControllerProtocol {
    let id = WMFYearInReviewPersonalizedSlideID.viewCount.rawValue
    let year: Int
    var isEvaluated: Bool = false
    static var containsPersonalizedNetworkData = true
    static var shouldFreeze = false
    
    private var viewCount: Int?
    
    private let userID: String?
    private let languageCode: String?
    private let project: WMFProject?
    
    private let service = WMFDataEnvironment.current.mediaWikiService
    
    init(year: Int, yirConfig: WMFFeatureConfigResponse.Common.YearInReview, dependencies: YearInReviewSlideDataControllerDependencies) {
        self.year = year
        self.userID = dependencies.userID
        self.languageCode = dependencies.languageCode
        self.project = dependencies.project
    }

    func populateSlideData(in context: NSManagedObjectContext) async throws {
        guard let userID, let languageCode else { return }
        viewCount = try await self.fetchEditViews(project: project, userId: userID, language: languageCode)
        isEvaluated = true
    }

    func makeCDSlide(in context: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let slide = CDYearInReviewSlide(context: context)
        slide.id = id
        slide.year = Int32(year)
        slide.data = try viewCount.map { try JSONEncoder().encode($0) }
        return slide
    }

    static func shouldPopulate(from config: WMFFeatureConfigResponse.Common.YearInReview, userInfo: YearInReviewUserInfo) -> Bool {
        return config.isActive(for: Date()) && userInfo.userID != nil
    }
    
    private func fetchEditViews(project: WMFProject?, userId: String, language: String) async throws -> (Int) {
        return try await withCheckedThrowingContinuation { continuation in
            fetchEditViews(project: project, userId: userId, language: language) { result in
                switch result {
                case .success(let views):
                    continuation.resume(returning: views)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func fetchEditViews(project: WMFProject?, userId: String, language: String, completion: @escaping (Result<Int, Error>) -> Void) {

        guard let service else {
            completion(.failure(WMFDataControllerError.mediaWikiServiceUnavailable))
            return
        }
        
        guard let project = project else {
            completion(.failure(WMFDataControllerError.mediaWikiServiceUnavailable))
            return
        }
        
        let prefixedUserID = "#" + userId
        
        guard let baseUrl = URL.mediaWikiRestAPIURL(project: project, additionalPathComponents: ["growthexperiments", "v0", "user-impact", prefixedUserID]) else {
            completion(.failure(WMFDataControllerError.failureCreatingRequestURL))
            return
        }

        var urlComponents = URLComponents(url: baseUrl, resolvingAgainstBaseURL: false)
        urlComponents?.queryItems = [URLQueryItem(name: "lang", value: language)]
        
        guard let url = urlComponents?.url else {
            completion(.failure(WMFDataControllerError.failureCreatingRequestURL))
            return
        }

        let request = WMFMediaWikiServiceRequest(url: url, method: .GET, backend: .mediaWikiREST, tokenType: .none, parameters: nil)

        let completionHandler: (Result<[String: Any]?, Error>) -> Void = { result in
            switch result {
            case .success(let data):
                guard let jsonData = data else {
                    completion(.failure(WMFDataControllerError.unexpectedResponse))
                    return
                }

                if let totalPageviews = jsonData["totalPageviewsCount"] as? Int {
                    let totalViews = totalPageviews
                    completion(.success(totalViews))
                } else {
                    // If for any reason we don't get anything
                    completion(.success(0))
                }

            case .failure(let error):
                completion(.failure(WMFDataControllerError.serviceError(error)))
            }
        }
        service.perform(request: request, completion: completionHandler)
    }
}
