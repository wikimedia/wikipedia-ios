import CoreData

final class YearInReviewDonateCountSlideDataController: YearInReviewSlideDataControllerProtocol {
    
    let id = WMFYearInReviewPersonalizedSlideID.donateCount.rawValue
    let year: Int
    var isEvaluated: Bool = false
    static var containsPersonalizedNetworkData = false
    static var shouldFreeze = false
    
    private let username: String?
    private let project: WMFProject?
    
    private let service = WMFDataEnvironment.current.mediaWikiService
    
    private var donateCount: Int?
    private var editCount: Int?
    
    private let yirConfig: WMFFeatureConfigResponse.Common.YearInReview
    
    init(year: Int, yirConfig: WMFFeatureConfigResponse.Common.YearInReview, dependencies: YearInReviewSlideDataControllerDependencies) {
        self.year = year
        self.yirConfig = yirConfig
        self.username = dependencies.username
        self.project = dependencies.project
    }

    func populateSlideData(in context: NSManagedObjectContext) async throws {
        guard let startDate = yirConfig.dataStartDate,
              let endDate = yirConfig.dataEndDate else {
            return
        }
        donateCount = getDonateCount(startDate: startDate, endDate: endDate)
        
        if let username, let project {
            do {
                let startDateString = yirConfig.dataStartDateString
                let endDateString = yirConfig.dataEndDateString
                editCount = try await getEditCount(startDate: startDateString, endDate: endDateString, username: username, project: project)
                isEvaluated = true
            } catch {
                isEvaluated = false
            }
        }
    }
    
    func getDonateCount(startDate: Date, endDate: Date) -> Int? {
        return WMFDonateDataController.shared.loadLocalDonationHistory(startDate: startDate, endDate: endDate)?.count
    }
    
    func getEditCount(startDate: String, endDate: String, username: String, project: WMFProject) async throws -> Int? {
        
        let (edits, _) = try await fetchUserContributionsCount(username: username, project: project, startDate: startDate, endDate: endDate)
        
        return edits
    }
    
    func fetchUserContributionsCount(username: String, project: WMFProject?, startDate: String, endDate: String) async throws -> (Int, Bool) {
        return try await withCheckedThrowingContinuation { continuation in
            fetchUserContributionsCount(username: username, project: project, startDate: startDate, endDate: endDate) { result in
                switch result {
                case .success(let successResult):
                    continuation.resume(returning: successResult)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func fetchUserContributionsCount(username: String, project: WMFProject?, startDate: String, endDate: String, completion: @escaping (Result<(Int, Bool), Error>) -> Void) {
        guard let service = service else {
            completion(.failure(WMFDataControllerError.mediaWikiServiceUnavailable))
            return
        }

        guard let project = project else {
            completion(.failure(WMFDataControllerError.mediaWikiServiceUnavailable))
            return
        }

        // We have to switch the dates here before sending into the API.
        // It is expected that this method's startDate parameter is chronologically earlier than endDate. This is how the remote feature config is set up.
        // The User Contributions API expects ucend to be chronologically earlier than ucstart, because it pages backwards so that the most recent edits appear on the first page.
        let ucStartDate = endDate
        let ucEndDate = startDate

        let parameters: [String: Any] = [
            "action": "query",
            "format": "json",
            "list": "usercontribs",
            "formatversion": "2",
            "uclimit": "500",
            "ucstart": ucStartDate,
            "ucend": ucEndDate,
            "ucuser": username,
            "ucnamespace": "0",
            "ucprop": "ids|title|timestamp|tags|flags"
        ]

        guard let url = URL.mediaWikiAPIURL(project: project) else {
            completion(.failure(WMFDataControllerError.failureCreatingRequestURL))
            return
        }

        let request = WMFMediaWikiServiceRequest(url: url, method: .GET, backend: .mediaWiki, parameters: parameters)

        service.performDecodableGET(request: request) { (result: Result<UserContributionsAPIResponse, Error>) in
            switch result {
            case .success(let response):
                guard let query = response.query else {
                    completion(.failure(WMFDataControllerError.unexpectedResponse))
                    return
                }

                let editCount = query.usercontribs.count

                let hasMoreEdits = response.continue?.uccontinue != nil

                completion(.success((editCount, hasMoreEdits)))

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func makeCDSlide(in context: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let slide = CDYearInReviewSlide(context: context)
        slide.id = id
        slide.year = Int32(year)
        
        let payload = DonateAndEditCounts(donateCount: donateCount, editCount: editCount)
        slide.data = try JSONEncoder().encode(payload)
        
        return slide
    }

    static func shouldPopulate(from config: WMFFeatureConfigResponse.Common.YearInReview, userInfo: YearInReviewUserInfo) -> Bool {
        return config.isActive(for: Date())
    }
}
