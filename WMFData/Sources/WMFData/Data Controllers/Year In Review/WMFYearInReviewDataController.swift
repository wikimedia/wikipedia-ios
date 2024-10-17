import Foundation
import CoreData

public class WMFYearInReviewDataController {

    private let coreDataStore: WMFCoreDataStore
    private let developerSettingsDataController: WMFDeveloperSettingsDataControlling
    private let service = WMFDataEnvironment.current.mediaWikiService

    public init(coreDataStore: WMFCoreDataStore? = WMFDataEnvironment.current.coreDataStore, developerSettingsDataController: WMFDeveloperSettingsDataControlling = WMFDeveloperSettingsDataController.shared) throws {
        guard let coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }
        self.coreDataStore = coreDataStore
        self.developerSettingsDataController = developerSettingsDataController

    }

    public func shouldCreateOrRetrieveYearInReview(countryCode: String?, primaryAppLanguageProject: WMFProject?) -> Bool {
        guard developerSettingsDataController.enableYearInReview else {
            return false
        }

        guard let iosFeatureConfig = developerSettingsDataController.loadFeatureConfig()?.ios.first else {
            return false
        }

        guard let countryCode,
              let primaryAppLanguageProject else {
            return false
        }

        let uppercaseConfigCountryCodes = iosFeatureConfig.yir.countryCodes.map { $0.uppercased() }
        guard uppercaseConfigCountryCodes.contains(countryCode.uppercased()) else {
            return false
        }

        let uppercaseConfigPrimaryAppLanguageCodes = iosFeatureConfig.yir.primaryAppLanguageCodes.map { $0.uppercased() }
        guard let languageCode = primaryAppLanguageProject.languageCode,
              uppercaseConfigPrimaryAppLanguageCodes.contains(languageCode.uppercased()) else {
            return false
        }

        return true
    }

    @discardableResult
    public func createOrRetrieveYearInReview(for year: Int, countryCode: String, primaryAppLanguageProject: WMFProject?) async -> WMFYearInReviewReport? {

        guard shouldCreateOrRetrieveYearInReview(countryCode: countryCode, primaryAppLanguageProject: primaryAppLanguageProject) else {
            return nil
        }

        var report = try? await fetchYearInReviewReport(forYear: year)

        if report == nil {
            // TODO: Replace with actual slide creation logic
            let slides = getSlides()
            try? await createNewYearInReviewReport(year: year, slides: slides)
            report = try? await fetchYearInReviewReport(forYear: year)
        }

        return report
    }

    func getSlides() -> [WMFYearInReviewSlide] {
        let mockSlide = WMFYearInReviewSlide(year: 2024, id: .editCount,  evaluated: true, display: true, data: nil)
        return [mockSlide]
    }

    public func saveYearInReviewReport(_ report: WMFYearInReviewReport) async throws {
        let backgroundContext = try coreDataStore.newBackgroundContext

        try await backgroundContext.perform { [weak self] in
            guard let self else { return }

            let reportPredicate = NSPredicate(format: "year == %d", report.year)
            let cdReport = try self.coreDataStore.fetchOrCreate(
                entityType: CDYearInReviewReport.self,
                entityName: "CDYearInReviewReport",
                predicate: reportPredicate,
                in: backgroundContext
            )

            cdReport?.year = Int32(report.year)

            var cdSlidesSet = Set<CDYearInReviewSlide>()
            for slide in report.slides {
                let slidePredicate = NSPredicate(format: "id == %@", slide.id.rawValue)
                let cdSlide = try self.coreDataStore.fetchOrCreate(
                    entityType: CDYearInReviewSlide.self,
                    entityName: "CDYearInReviewSlide",
                    predicate: slidePredicate,
                    in: backgroundContext
                )

                cdSlide?.year = Int32(slide.year)
                cdSlide?.id = slide.id.rawValue
                cdSlide?.evaluated = slide.evaluated
                cdSlide?.display = slide.display
                cdSlide?.data = slide.data

                if let cdSlide {
                    cdSlidesSet.insert(cdSlide)
                }
            }
            cdReport?.slides = cdSlidesSet as NSSet

            try self.coreDataStore.saveIfNeeded(moc: backgroundContext)
        }
    }

    public func createNewYearInReviewReport(year: Int, slides: [WMFYearInReviewSlide]) async throws {
        let newReport = WMFYearInReviewReport(year: year, slides: slides)

        try await saveYearInReviewReport(newReport)
    }

    public func fetchYearInReviewReport(forYear year: Int) async throws -> WMFYearInReviewReport? {
        let viewContext = try coreDataStore.viewContext
        let report: WMFYearInReviewReport? = try await viewContext.perform { () -> WMFYearInReviewReport? in
            let fetchRequest = NSFetchRequest<CDYearInReviewReport>(entityName: "CDYearInReviewReport")

            fetchRequest.predicate = NSPredicate(format: "year == %d", year)

            let cdReports = try viewContext.fetch(fetchRequest)

            guard let cdReport = cdReports.first else {
                return nil
            }

            guard let cdSlides = cdReport.slides as? Set<CDYearInReviewSlide> else {
                return nil
            }

            var slides: [WMFYearInReviewSlide] = []
            for cdSlide in cdSlides {
                if let id = self.getSlideId(cdSlide.id) {
                    let slide = WMFYearInReviewSlide(
                        year: Int(cdSlide.year),
                        id: id,
                        evaluated: cdSlide.evaluated,
                        display: cdSlide.display
                    )
                    slides.append(slide)
                }
            }

            let report = WMFYearInReviewReport(
                year: Int(cdReport.year),
                slides: slides
            )
            return report
        }
        return report
    }


    public func fetchYearInReviewReports() async throws -> [WMFYearInReviewReport] {
        let viewContext = try coreDataStore.viewContext
        let reports: [WMFYearInReviewReport] = try await viewContext.perform {
            let fetchRequest = NSFetchRequest<CDYearInReviewReport>(entityName: "CDYearInReviewReport")
            let cdReports = try viewContext.fetch(fetchRequest)

            var results: [WMFYearInReviewReport] = []
            for cdReport in cdReports {
                guard let cdSlides = cdReport.slides as? Set<CDYearInReviewSlide> else {
                    continue
                }

                var slides: [WMFYearInReviewSlide] = []
                for cdSlide in cdSlides {
                    if let id = self.getSlideId(cdSlide.id) {
                        let slide = WMFYearInReviewSlide(year: Int(cdSlide.year), id: id, evaluated: cdSlide.evaluated, display: cdSlide.display)
                        slides.append(slide)
                    }
                }

                let report = WMFYearInReviewReport(
                    year: Int(cdReport.year),
                    slides: slides
                )
                results.append(report)
            }
            return results
        }
        return reports
    }

    private func getSlideId(_ idString: String?) -> WMFYearInReviewPersonalizedSlideID? {
        switch idString {
        case "readCount":
            return .readCount
        case "editCount":
            return .editCount
        default:
            return nil
        }

    }

    public func deleteYearInReviewReport(year: Int) async throws {
        let backgroundContext = try coreDataStore.newBackgroundContext

        try await backgroundContext.perform { [weak self] in
            guard let self else { return }

            let reportPredicate = NSPredicate(format: "year == %d", year)
            if let cdReport = try self.coreDataStore.fetch(
                entityType: CDYearInReviewReport.self,
                entityName: "CDYearInReviewReport",
                predicate: reportPredicate,
                fetchLimit: 1,
                in: backgroundContext
            )?.first {
                backgroundContext.delete(cdReport)
                try self.coreDataStore.saveIfNeeded(moc: backgroundContext)
            }
        }
    }

    public func deleteAllYearInReviewReports() async throws {
        let backgroundContext = try coreDataStore.newBackgroundContext

        try await backgroundContext.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CDYearInReviewReport")
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            batchDeleteRequest.resultType = .resultTypeObjectIDs
            let result = try backgroundContext.execute(batchDeleteRequest) as? NSBatchDeleteResult

            if let objectIDArray = result?.result as? [NSManagedObjectID], !objectIDArray.isEmpty {
                let changes = [NSDeletedObjectsKey: objectIDArray]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [backgroundContext])
            }
            try self.coreDataStore.saveIfNeeded(moc: backgroundContext)
        }
    }
    
    public func shouldShowYearInReviewEntryPoint(countryCode: String?, primaryAppLanguageProject: WMFProject?) -> Bool {
        
        guard developerSettingsDataController.enableYearInReview else {
            return false
        }
        
        guard let countryCode,
              let primaryAppLanguageProject else {
            return false
        }
        
        guard let iosFeatureConfig = developerSettingsDataController.loadFeatureConfig()?.ios.first else {
            return false
        }
        
        // Check remote feature disable switch
        guard iosFeatureConfig.yir.isEnabled else {
            return false
        }
        
        
        // Check remote valid country codes
        let uppercaseConfigCountryCodes = iosFeatureConfig.yir.countryCodes.map { $0.uppercased() }
        guard uppercaseConfigCountryCodes.contains(countryCode.uppercased()) else {
            return false
        }
        
        // Check remote valid primary app language wikis
        let uppercaseConfigPrimaryAppLanguageCodes = iosFeatureConfig.yir.primaryAppLanguageCodes.map { $0.uppercased() }
        guard let languageCode = primaryAppLanguageProject.languageCode,
              uppercaseConfigPrimaryAppLanguageCodes.contains(languageCode.uppercased()) else {
            return false
        }
        
        var personalizedSlideCount = 0
        
        // TODO: Check persisted slide item here https://phabricator.wikimedia.org/T376041
        // if {read_count persisted slide item}.display == yes {
            if iosFeatureConfig.yir.personalizedSlides.readCount.isEnabled {
                personalizedSlideCount += 1
            }
        // }
        
        // TODO: Check persisted slide item here https://phabricator.wikimedia.org/T376041
        // if {edit_count persisted slide item}.display == yes {
            if iosFeatureConfig.yir.personalizedSlides.editCount.isEnabled {
                personalizedSlideCount += 1
            }
        // }
        
        // TODO: Uncomment once at least one personalized slide is in: T376066 or T376320
//        guard personalizedSlideCount >= 1 else {
//            return false
//        }
        
        return true
    }
    
    public func fetchUserContributionsCount(username: String, languageCode: String, completion: @escaping (Result<(Int, Bool), Error>) -> Void) {
        guard let service = service else {
            completion(.failure(WMFDataControllerError.mediaWikiServiceUnavailable))
            return
        }
        
        let ucStartDate = "2024-11-01T22:20:13.000Z"
        let ucEndDate = "2024-01-01T22:20:13.000Z"
        
        let parameters: [String: Any] = [
            "action": "query",
            "format": "json",
            "list": "usercontribs",
            "formatversion": "2",
            "uclimit": "500",  // Above 500, just display 500+
            "ucstart": ucStartDate,
            "ucend": ucEndDate,
            "ucuser": username,
            "ucnamespace": "0",
            "ucprop": "ids|title|timestamp|tags|flags"
        ]

        guard let url = URL(string: "https://\(languageCode).wikipedia.org/w/api.php") else {
            completion(.failure(WMFDataControllerError.failureCreatingRequestURL))
            return
        }
        
        let request = WMFMediaWikiServiceRequest(url: url, method: .GET, backend: .mediaWiki, parameters: parameters)
        
        service.performDecodableGET(request: request) { (result: Result<UserContributionsAPIResponse, Error>) in
            switch result {
            case .success(let response):
                let editCount = response.query?.usercontribs.count
                
                let hasMoreEdits = response.continue?.uccontinue != nil
                
                completion(.success((editCount ?? 0, hasMoreEdits)))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    struct UserContributionsAPIResponse: Codable {
        let batchcomplete: Bool?
        let `continue`: ContinueData?
        let query: UserContributionsQuery?
        
        struct ContinueData: Codable {
            let uccontinue: String?
        }
        
        struct UserContributionsQuery: Codable {
            let usercontribs: [UserContribution]
        }
    }

    struct UserContribution: Codable {
        let userid: Int
        let user: String
        let pageid: Int
        let revid: Int
        let parentid: Int
        let ns: Int
        let title: String
        let timestamp: String
        let isNew: Bool
        let isMinor: Bool
        let isTop: Bool
        let tags: [String]
        
        enum CodingKeys: String, CodingKey {
            case userid, user, pageid, revid, parentid, ns, title, timestamp, tags
            case isNew = "new"
            case isMinor = "minor"
            case isTop = "top"
        }
    }
}
