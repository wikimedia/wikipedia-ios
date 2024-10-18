import Foundation
import CoreData

public class WMFYearInReviewDataController {

    private let userDefaultsStore: WMFKeyValueStore?
    private let developerSettingsDataController: WMFDeveloperSettingsDataControlling

    public let coreDataStore: WMFCoreDataStore

    struct FeatureAnnouncementStatus: Codable {
        var hasPresentedYiRFeatureAnnouncementModal: Bool
        static var `default`: FeatureAnnouncementStatus {
            return FeatureAnnouncementStatus(hasPresentedYiRFeatureAnnouncementModal: false)
        }
    }

    public init(coreDataStore: WMFCoreDataStore? = WMFDataEnvironment.current.coreDataStore, userDefaultsStore: WMFKeyValueStore? = WMFDataEnvironment.current.userDefaultsStore, developerSettingsDataController: WMFDeveloperSettingsDataControlling = WMFDeveloperSettingsDataController.shared) throws {
        guard let coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }
        self.coreDataStore = coreDataStore
        self.userDefaultsStore = userDefaultsStore
        self.developerSettingsDataController = developerSettingsDataController
    }

    // MARK: - Feature Announcement

    private var featureAnnouncementStatus: FeatureAnnouncementStatus {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.yearInReviewFeatureAnnouncement.rawValue)) ?? FeatureAnnouncementStatus.default
    }

    public var hasPresentedYiRFeatureAnnouncementModel: Bool {
        get {
            return featureAnnouncementStatus.hasPresentedYiRFeatureAnnouncementModal
        } set {
            var currentAnnouncementStatus = featureAnnouncementStatus
            currentAnnouncementStatus.hasPresentedYiRFeatureAnnouncementModal = newValue
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.yearInReviewFeatureAnnouncement.rawValue, value: currentAnnouncementStatus)
        }
    }

    func shouldPopulateYearInReviewReportData(countryCode: String?, primaryAppLanguageProject: WMFProject?) -> Bool {
        
        // Check local developer settings feature flag
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

        return true
    }
    
    public func shouldShowYearInReviewEntryPoint(countryCode: String?, primaryAppLanguageProject: WMFProject?) -> Bool {
        assert(Thread.isMainThread, "This method must be called from the main thread in order to keep it synchronous")
        
        // Check local developer settings feature flag
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
        
        // Check persisted year in review report. Year in Review entry point should display if one or more personalized slides are set to display and slide is not disabled in remote config
        guard let yirReport = try? fetchYearInReviewReport(forYear: 2024) else {
            return false
        }
        
        var personalizedSlideCount = 0
        
        for slide in yirReport.slides {
            switch slide.id {
            case .readCount:
                if iosFeatureConfig.yir.personalizedSlides.readCount.isEnabled,
                   slide.display == true {
                    personalizedSlideCount += 1
                }
            case .editCount:
                if iosFeatureConfig.yir.personalizedSlides.editCount.isEnabled,
                   slide.display == true {
                    personalizedSlideCount += 1
                }
            }
        }
        
        return personalizedSlideCount >= 1
    }

    @discardableResult
    public func populateYearInReviewReportData(for year: Int, countryCode: String, primaryAppLanguageProject: WMFProject?) async throws -> WMFYearInReviewReport? {

        guard shouldPopulateYearInReviewReportData(countryCode: countryCode, primaryAppLanguageProject: primaryAppLanguageProject) else {
            return nil
        }

        let backgroundContext = try coreDataStore.newBackgroundContext
        
        let result: WMFYearInReviewReport? = try await backgroundContext.perform { [weak self] in
            
            guard let self else { return nil }
            return try populateYearInReviewReportData(year: year, backgroundContext: backgroundContext)
        }
        
        return result
    }
    
    private func populateYearInReviewReportData(year: Int, backgroundContext: NSManagedObjectContext) throws -> WMFYearInReviewReport? {
        let predicate = NSPredicate(format: "year == %d", year)
        let cdReport = try self.coreDataStore.fetchOrCreate(entityType: CDYearInReviewReport.self, predicate: predicate, in: backgroundContext)
        
        guard let cdReport else {
            return nil
        }
        
        cdReport.year = Int32(year)
        if (cdReport.slides?.count ?? 0) == 0 {
            cdReport.slides = try self.initialSlides(year: year, moc: backgroundContext) as NSSet
        }
        
        try self.coreDataStore.saveIfNeeded(moc: backgroundContext)
        
        // Then for each personalized slide, check slide enabled flag from remote config. Then populate and save associated data.
        guard let iosFeatureConfig = developerSettingsDataController.loadFeatureConfig()?.ios.first else {
            return nil
        }
        
        guard let dataPopulationStartDate = iosFeatureConfig.yir.dataPopulationStartDate,
              let dataPopulationEndDate = iosFeatureConfig.yir.dataPopulationEndDate else {
            return nil
        }
        
        guard let cdSlides = cdReport.slides as? Set<CDYearInReviewSlide> else {
            return nil
        }
        
        for slide in cdSlides {
            switch slide.id {
                
            case WMFYearInReviewPersonalizedSlideID.readCount.rawValue:
                if slide.evaluated == false && iosFeatureConfig.yir.personalizedSlides.readCount.isEnabled {
                    
                    let pageViewsDataController = try WMFPageViewsDataController(coreDataStore: coreDataStore)
                    let pageViewCounts = try pageViewsDataController.fetchPageViewCounts(startDate: dataPopulationStartDate, endDate: dataPopulationEndDate, moc: backgroundContext)
                    
                    let encoder = JSONEncoder()
                    slide.data = try encoder.encode(pageViewCounts.count)
                    
                    if pageViewCounts.count > 5 {
                        slide.display = true
                    }
                    
                    slide.evaluated = true
                }
                
            case WMFYearInReviewPersonalizedSlideID.editCount.rawValue:
                
                if slide.evaluated == false && iosFeatureConfig.yir.personalizedSlides.editCount.isEnabled {
                    
                    // TODO: Fetch edit count, save in slide data, set evaluated = true and display = true (if needed)
                    
                }
            default:
                debugPrint("Unrecognized Slide ID")
            }
        
        }
        
        try coreDataStore.saveIfNeeded(moc: backgroundContext)
        
        return WMFYearInReviewReport(cdReport: cdReport)
    }

    func initialSlides(year: Int, moc: NSManagedObjectContext) throws -> Set<CDYearInReviewSlide> {
        var results = Set<CDYearInReviewSlide>()
        if year == 2024 {
            
            let readCountSlide = try coreDataStore.create(entityType: CDYearInReviewSlide.self, in: moc)
            readCountSlide.year = 2024
            readCountSlide.id = WMFYearInReviewPersonalizedSlideID.readCount.rawValue
            readCountSlide.evaluated = false
            readCountSlide.display = false
            readCountSlide.data = nil
            results.insert(readCountSlide)
            
            let editCountSlide = try coreDataStore.create(entityType: CDYearInReviewSlide.self, in: moc)
            editCountSlide.year = 2024
            editCountSlide.id = WMFYearInReviewPersonalizedSlideID.editCount.rawValue
            editCountSlide.evaluated = false
            editCountSlide.display = false
            editCountSlide.data = nil
            results.insert(editCountSlide)
        }
        
        return results
    }
    
    public func saveYearInReviewReport(_ report: WMFYearInReviewReport) async throws {
        let backgroundContext = try coreDataStore.newBackgroundContext

        try await backgroundContext.perform { [weak self] in
            guard let self else { return }

            let reportPredicate = NSPredicate(format: "year == %d", report.year)
            let cdReport = try self.coreDataStore.fetchOrCreate(
                entityType: CDYearInReviewReport.self,
                predicate: reportPredicate,
                in: backgroundContext
            )

            cdReport?.year = Int32(report.year)

            var cdSlidesSet = Set<CDYearInReviewSlide>()
            for slide in report.slides {
                let slidePredicate = NSPredicate(format: "id == %@", slide.id.rawValue)
                let cdSlide = try self.coreDataStore.fetchOrCreate(
                    entityType: CDYearInReviewSlide.self,
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

    public func fetchYearInReviewReport(forYear year: Int) throws -> WMFYearInReviewReport? {
        assert(Thread.isMainThread, "This report must be called from the main thread in order to keep it synchronous")
        
        let viewContext = try coreDataStore.viewContext
        
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
                    display: cdSlide.display,
                    data: cdSlide.data
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
}
