import Foundation
import UIKit
import CoreData

@preconcurrency
@objc public class WMFYearInReviewDataController: NSObject {

    public let coreDataStore: WMFCoreDataStore
    private let userDefaultsStore: WMFKeyValueStore?
    private let developerSettingsDataController: WMFDeveloperSettingsDataControlling

    public let targetConfigYearID = "2024.2"
    @objc public static let targetYear = 2024
    public static let appShareLink = "https://apps.apple.com/app/apple-store/id324715238?pt=208305&ct=yir_2024_share&mt=8"

    private let service = WMFDataEnvironment.current.mediaWikiService
    private var dataPopulationBackgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    struct FeatureAnnouncementStatus: Codable {
        var hasPresentedYiRFeatureAnnouncementModal: Bool
        static var `default`: FeatureAnnouncementStatus {
            return FeatureAnnouncementStatus(hasPresentedYiRFeatureAnnouncementModal: false)
        }
    }

    struct YiRNotificationAnnouncementStatus: Codable {
        var hasSeenYiRIntroSlide: Bool
        static var `default`: YiRNotificationAnnouncementStatus {
            return YiRNotificationAnnouncementStatus(hasSeenYiRIntroSlide: false)
        }
    }

    @objc public static func dataControllerForObjectiveC() -> WMFYearInReviewDataController? {
        return try? WMFYearInReviewDataController()
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
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.seenYearInReviewFeatureAnnouncement.rawValue)) ?? FeatureAnnouncementStatus.default
    }

    private var seenIntroSlideStatus: YiRNotificationAnnouncementStatus {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.seenYearInReviewIntroSlide.rawValue)) ?? YiRNotificationAnnouncementStatus.default
    }
    
    public func shouldShowYiRNotification(primaryAppLanguageProject: WMFProject?, isLoggedOut: Bool, isTemporaryAccount: Bool) -> Bool {
        
        #if DEBUG
        if isTemporaryAccount {
            return false
        }

        if isLoggedOut {
            return !hasTappedProfileItem && !hasSeenYiRIntroSlide && shouldShowYearInReviewEntryPoint(countryCode: Locale.current.region?.identifier, primaryAppLanguageProject: primaryAppLanguageProject)
        }
        return !hasSeenYiRIntroSlide && shouldShowYearInReviewEntryPoint(countryCode: Locale.current.region?.identifier, primaryAppLanguageProject: primaryAppLanguageProject)
        #else
        return false
        #endif
    }
    
    public var hasTappedProfileItem: Bool {
        get {
            return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.tappedYIR.rawValue)) ?? false
        } set {
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.tappedYIR.rawValue, value: newValue)
        }
    }

    public var hasSeenYiRIntroSlide: Bool {
        get {
            return seenIntroSlideStatus.hasSeenYiRIntroSlide
        } set {
            var currentSeenIntroSlideStatus = seenIntroSlideStatus
            currentSeenIntroSlideStatus.hasSeenYiRIntroSlide = newValue
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.seenYearInReviewIntroSlide.rawValue, value: currentSeenIntroSlideStatus)
        }
    }

    public var hasPresentedYiRFeatureAnnouncementModel: Bool {
        get {
            return featureAnnouncementStatus.hasPresentedYiRFeatureAnnouncementModal
        } set {
            var currentAnnouncementStatus = featureAnnouncementStatus
            currentAnnouncementStatus.hasPresentedYiRFeatureAnnouncementModal = newValue
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.seenYearInReviewFeatureAnnouncement.rawValue, value: currentAnnouncementStatus)
        }
    }

    func isAnnouncementActive() -> Bool {
        let expiryDate: Date? = {
            var expiryDateComponents = DateComponents()
            expiryDateComponents.year = 2025
            expiryDateComponents.month = 3
            expiryDateComponents.day = 1
            return Calendar.current.date(from: expiryDateComponents)
        }()

        guard let expiryDate else {
            return false
        }
        let currentDate = Date()
        return currentDate <= expiryDate
    }

    public func shouldShowYearInReviewFeatureAnnouncement(primaryAppLanguageProject: WMFProject?) -> Bool {
        #if DEBUG
        guard isAnnouncementActive() else {
            return false
        }

        guard yearInReviewSettingsIsEnabled else {
            return false
        }

        guard shouldShowYearInReviewEntryPoint(countryCode: Locale.current.region?.identifier, primaryAppLanguageProject: primaryAppLanguageProject) else {
            return false
        }

        guard !hasPresentedYiRFeatureAnnouncementModel else {
            return false
        }

        guard !hasSeenYiRIntroSlide else {
            return false
        }

        return true
        #else
        return false
        #endif
    }

    // MARK: Entry Point

    public func shouldShowYearInReviewEntryPoint(countryCode: String?, primaryAppLanguageProject: WMFProject?) -> Bool {
        assert(Thread.isMainThread, "This method must be called from the main thread in order to keep it synchronous")

        guard yearInReviewSettingsIsEnabled else {
            return false
        }

        guard let countryCode,
              let primaryAppLanguageProject else {
            return false
        }
        
        let yirConfig: WMFFeatureConfigResponse.IOS.YearInReview?

        #if DEBUG
        if let iosFeatureConfig = developerSettingsDataController.loadFeatureConfig()?.ios.first,
           let config = iosFeatureConfig.yir(yearID: targetConfigYearID) {
            yirConfig = config
        } else {
            return false
        }
        #else
        return false
        #endif

        guard let yirConfig = yirConfig, yirConfig.isEnabled else {
            return false
        }


        // Check remote valid country codes
        let uppercaseConfigCountryCodes = yirConfig.countryCodes.map { $0.uppercased() }
        guard uppercaseConfigCountryCodes.contains(countryCode.uppercased()) else {
            return false
        }

        // Check remote valid primary app language wikis
        let uppercaseConfigPrimaryAppLanguageCodes = yirConfig.primaryAppLanguageCodes.map { $0.uppercased() }
        guard let languageCode = primaryAppLanguageProject.languageCode,
              uppercaseConfigPrimaryAppLanguageCodes.contains(languageCode.uppercased()) else {
            return false
        }

        // Check persisted year in review report exists.
        let yirReport = try? fetchYearInReviewReport(forYear: Self.targetYear)
        guard yirReport != nil else {
            return false
        }

        return true
    }

    // MARK: - Survey

    public var hasPresentedYiRSurvey: Bool {
        get {
            return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.yearInReviewSurveyPresented.rawValue)) ?? false
        } set {
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.yearInReviewSurveyPresented.rawValue, value: newValue)
        }
    }

    // MARK: - Hide Year in Review

    @objc public func shouldShowYearInReviewSettingsItem(countryCode: String?, primaryAppLanguageCode: String?) -> Bool {

        guard let countryCode,
              let primaryAppLanguageCode else {
            return false
        }

        guard let iosFeatureConfig = developerSettingsDataController.loadFeatureConfig()?.ios.first,
              let yirConfig = iosFeatureConfig.yir(yearID: targetConfigYearID) else {
            return false
        }

        // Note: Purposefully not checking config's yir.isEnabled here. We want to continue showing the Settings item after we have disabled the feature remotely.


        // Check remote valid country codes
        let uppercaseConfigCountryCodes = yirConfig.countryCodes.map { $0.uppercased() }
        guard uppercaseConfigCountryCodes.contains(countryCode.uppercased()) else {
            return false
        }

        // Check remote valid primary app language wikis
        let uppercaseConfigPrimaryAppLanguageCodes = yirConfig.primaryAppLanguageCodes.map { $0.uppercased() }
        guard uppercaseConfigPrimaryAppLanguageCodes.contains(primaryAppLanguageCode.uppercased()) else {
            return false
        }

        return true
    }

    @objc public var yearInReviewSettingsIsEnabled: Bool {
        get {
            return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.yearInReviewSettingsIsEnabled.rawValue)) ?? true
        } set {
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.yearInReviewSettingsIsEnabled.rawValue, value: newValue)
        }
    }

    // MARK: Report Data Population

    func shouldPopulateYearInReviewReportData(countryCode: String?, primaryAppLanguageProject: WMFProject?) -> Bool {
        guard yearInReviewSettingsIsEnabled else {
            return false
        }

        let yirConfig: WMFFeatureConfigResponse.IOS.YearInReview?

        #if DEBUG
        if let iosFeatureConfig = developerSettingsDataController.loadFeatureConfig()?.ios.first,
           let config = iosFeatureConfig.yir(yearID: targetConfigYearID) {
            yirConfig = config
        } else {
            return false
        }
        #else
        return false
        #endif

        guard let countryCode,
              let primaryAppLanguageProject else {
            return false
        }

        guard let yirConfig = yirConfig, yirConfig.isEnabled else {
            return false
        }

        // Check remote valid country codes
        let uppercaseConfigCountryCodes = yirConfig.countryCodes.map { $0.uppercased() }
        guard uppercaseConfigCountryCodes.contains(countryCode.uppercased()) else {
            return false
        }

        // Check remote valid primary app language wikis
        let uppercaseConfigPrimaryAppLanguageCodes = yirConfig.primaryAppLanguageCodes.map { $0.uppercased() }

        guard let languageCode = primaryAppLanguageProject.languageCode,
              uppercaseConfigPrimaryAppLanguageCodes.contains(languageCode.uppercased()) else {
            return false
        }

        return true
    }

    private func beginDataPopulationBackgroundTask() async {
        
        guard dataPopulationBackgroundTaskID == .invalid else {
            return
        }
        
        dataPopulationBackgroundTaskID = await UIApplication.shared.beginBackgroundTask(withName: WMFBackgroundTasksNameKey.yearInReviewPopulateReportData.rawValue, expirationHandler: {
            UIApplication.shared.endBackgroundTask(self.dataPopulationBackgroundTaskID)
            self.dataPopulationBackgroundTaskID = .invalid
        })
    }
    
    private func endDataPopulationBackgroundTask() {
        
        guard dataPopulationBackgroundTaskID != .invalid else {
            return
        }
        
        UIApplication.shared.endBackgroundTask(self.dataPopulationBackgroundTaskID)
        dataPopulationBackgroundTaskID = UIBackgroundTaskIdentifier.invalid
    }
    
    @discardableResult
    public func populateYearInReviewReportData(for year: Int, countryCode: String, primaryAppLanguageProject: WMFProject?, username: String?, userID: String?, savedSlideDataDelegate: SavedArticleSlideDataDelegate, legacyPageViewsDataDelegate: LegacyPageViewsDataDelegate) async throws -> WMFYearInReviewReport? {

        guard shouldPopulateYearInReviewReportData(countryCode: countryCode, primaryAppLanguageProject: primaryAppLanguageProject) else {
            return nil
        }

        await beginDataPopulationBackgroundTask()
        
        defer {
            endDataPopulationBackgroundTask()
        }

        let backgroundContext = try coreDataStore.newBackgroundContext
        
        var yirConfig: WMFFeatureConfigResponse.IOS.YearInReview? = nil
        #if DEBUG
        yirConfig = developerSettingsDataController.loadFeatureConfig()?.ios.first?.yir(yearID: targetConfigYearID)
        #else
        return nil
        #endif

        guard let yirConfig else {
            return nil
        }

        let slideConfig = SlideConfig(
            readCountIsEnabled: .init(yirConfig.personalizedSlides.readCount.isEnabled),
            editCountIsEnabled: .init(yirConfig.personalizedSlides.editCount.isEnabled),
            donateCountIsEnabled: .init(yirConfig.personalizedSlides.donateCount.isEnabled),
            saveCountIsEnabled: .init(yirConfig.personalizedSlides.saveCount.isEnabled),
            mostReadDayIsEnabled: .init(yirConfig.personalizedSlides.mostReadDay.isEnabled),
            viewCountIsEnabled: .init(yirConfig.personalizedSlides.viewCount.isEnabled)
        )

        let featureConfig = YearInReviewFeatureConfig(
            isEnabled: yirConfig.isEnabled,
            slideConfig: slideConfig,
            dataPopulationStartDateString: yirConfig.dataPopulationStartDateString,
            dataPopulationEndDateString: yirConfig.dataPopulationEndDateString,
            dataPopulationStartDate: yirConfig.dataPopulationStartDate,
            dataPopulationEndDate: yirConfig.dataPopulationEndDate
        )

        let slideFactory = YearInReviewSlideDataControllerFactory(
            year: year,
            config: featureConfig,
            username: username,
            userID: userID,
            project: primaryAppLanguageProject,
            savedSlideDataDelegate: savedSlideDataDelegate,
            legacyPageViewsDataDelegate: legacyPageViewsDataDelegate
        )

        // First pull existing report slide IDs from Core Data
        let existingIDs = try await backgroundContext.perform {
            let predicate = NSPredicate(format: "year == %d", year)
            let cdReport = try self.coreDataStore.fetch(
                entityType: CDYearInReviewReport.self,
                predicate: predicate,
                fetchLimit: 1,
                in: backgroundContext
            )?.first
            return Set((cdReport?.slides as? Set<CDYearInReviewSlide>)?.compactMap { $0.id } ?? [])
        }

        // For any slide IDs missing, create associated slide data controllers and populate their data. Set evaluated flag if population succeeds
        var slideDataControllers = try await slideFactory.makeSlideDataControllers(missingFrom: existingIDs)
        for index in slideDataControllers.indices {
            do {
                try await slideDataControllers[index].populateSlideData(in: backgroundContext)
                slideDataControllers[index].isEvaluated = true
            } catch {
                slideDataControllers[index].isEvaluated = false
            }
        }

        // Create new core data slides from evaluated data controllers, save to core data report and return generic report struct
        let report = try await backgroundContext.perform {
            let predicate = NSPredicate(format: "year == %d", year)
            let cdReport = try self.coreDataStore.fetchOrCreate(
                entityType: CDYearInReviewReport.self,
                predicate: predicate,
                in: backgroundContext
            )!

            cdReport.year = Int32(year)

            var finalCDSlides = cdReport.slides as? Set<CDYearInReviewSlide> ?? []

            for slideDataController in slideDataControllers where slideDataController.isEvaluated {
                if let cdSlide = try? slideDataController.makeCDSlide(in: backgroundContext) {
                    finalCDSlides.insert(cdSlide)
                }
            }

            cdReport.slides = Set(finalCDSlides) as NSSet
            
            try self.coreDataStore.saveIfNeeded(moc: backgroundContext)
            
            // Convert core data report to plain struct before returning
            
            let slides = finalCDSlides.compactMap(self.makeSlide(from:))
            return WMFYearInReviewReport(year: year, slides: slides)
        }

        return report
    }

    public func fetchYearInReviewReport(forYear year: Int) throws -> WMFYearInReviewReport? {
        assert(Thread.isMainThread, "This report must be called from the main thread in order to keep it synchronous")

        let viewContext = try coreDataStore.viewContext

        let fetchRequest = NSFetchRequest<CDYearInReviewReport>(entityName: "CDYearInReviewReport")
        fetchRequest.predicate = NSPredicate(format: "year == %d", year)

        let cdReports = try viewContext.fetch(fetchRequest)
        guard let cdReport = cdReports.first else { return nil }

        let slides = (cdReport.slides as? Set<CDYearInReviewSlide>)?.compactMap(makeSlide(from:)) ?? []
        return WMFYearInReviewReport(year: Int(cdReport.year), slides: slides)
    }

    private func makeSlide(from cdSlide: CDYearInReviewSlide) -> WMFYearInReviewSlide? {
        guard let id = self.getSlideId(cdSlide.id) else { return nil }
        return WMFYearInReviewSlide(
            year: Int(cdSlide.year),
            id: id,
            data: cdSlide.data
        )
    }

    private func getSlideId(_ idString: String?) -> WMFYearInReviewPersonalizedSlideID? {
        guard let raw = idString else { return nil }
        return WMFYearInReviewPersonalizedSlideID(rawValue: raw)
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

    public func deleteAllPersonalizedNetworkData() async throws {
        
        let backgroundContext = try coreDataStore.newBackgroundContext

        try await backgroundContext.perform { [weak self] in
            guard let self else { return }

            let cdReports = try self.coreDataStore.fetch(
                entityType: CDYearInReviewReport.self,
                predicate: nil,
                fetchLimit: nil,
                in: backgroundContext
            )

            guard let cdReports else {
                return
            }

            for report in cdReports {
                guard let slides = report.slides as? Set<CDYearInReviewSlide> else {
                    continue
                }

                for slide in slides {
                    guard let slideID = slide.id,
                          let dataController = WMFYearInReviewPersonalizedSlideID(rawValue: slideID)?.dataController() else {
                        continue
                    }
                    
                    guard dataController.containsPersonalizedNetworkData else { continue }

                    backgroundContext.delete(slide)
                }
            }

            try self.coreDataStore.saveIfNeeded(moc: backgroundContext)
        }
    }

    public func shouldHideDonateButton() -> Bool {
        let yirConfig: WMFFeatureConfigResponse.IOS.YearInReview?

        #if DEBUG
        guard let iosFeatureConfig = developerSettingsDataController.loadFeatureConfig()?.ios.first,
              let config = iosFeatureConfig.yir(yearID: targetConfigYearID) else {
            return false
        }
        yirConfig = config
        #else
        return false
        #endif

        guard let locale = Locale.current.region?.identifier else {
            return false
        }

        guard let yirConfig = yirConfig, yirConfig.hideDonateCountryCodes.contains(locale) else {
            return false
        }

        return true
    }
    
    // MARK: So far these are only called from unit tests
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
    
    public func fetchYearInReviewReports() async throws -> [WMFYearInReviewReport] {
        let viewContext = try coreDataStore.viewContext
        let reports: [WMFYearInReviewReport] = try await viewContext.perform {
            let fetchRequest = NSFetchRequest<CDYearInReviewReport>(entityName: "CDYearInReviewReport")
            let cdReports = try viewContext.fetch(fetchRequest)

            return cdReports.compactMap { cdReport in
                guard let cdSlides = cdReport.slides as? Set<CDYearInReviewSlide> else { return nil }
                let slides = cdSlides.compactMap(self.makeSlide(from:))
                return WMFYearInReviewReport(year: Int(cdReport.year), slides: slides)
            }
        }
        return reports
    }
    
    public func createNewYearInReviewReport(year: Int, slides: [WMFYearInReviewSlide]) async throws {
        let newReport = WMFYearInReviewReport(year: year, slides: slides)

        try await saveYearInReviewReport(newReport)
    }
    
    public func saveYearInReviewReport(_ report: WMFYearInReviewReport) async throws {
        guard let backgroundContext = try? coreDataStore.newBackgroundContext else { return }

        try? await backgroundContext.perform { [weak self] in
            guard let self else { return }

            let reportPredicate = NSPredicate(format: "year == %d", report.year)
            let cdReport = try self.coreDataStore.fetchOrCreate(
                entityType: CDYearInReviewReport.self,
                predicate: reportPredicate,
                in: backgroundContext
            )

            cdReport?.year = Int32(report.year)
            cdReport?.slides = Set(report.slides.compactMap { self.makeCDSlide(from: $0, in: backgroundContext) }) as NSSet

            try self.coreDataStore.saveIfNeeded(moc: backgroundContext)
        }
    }
    
    private func makeCDSlide(from slide: WMFYearInReviewSlide, in context: NSManagedObjectContext) -> CDYearInReviewSlide? {
        do {
            let predicate = NSPredicate(format: "id == %@", slide.id.rawValue)
            let cdSlide = try self.coreDataStore.fetchOrCreate(
                entityType: CDYearInReviewSlide.self,
                predicate: predicate,
                in: context
            )

            cdSlide?.year = Int32(slide.year)
            cdSlide?.id = slide.id.rawValue
            cdSlide?.data = slide.data

            return cdSlide
        } catch {
            return nil
        }
    }
}

public class SavedArticleSlideData: NSObject, Codable {
    public let savedArticlesCount: Int
    public let articleTitles: [String]

    public init(savedArticlesCount: Int, articleTitles: [String]) {
        self.savedArticlesCount = savedArticlesCount
        self.articleTitles = articleTitles
    }
}

public protocol SavedArticleSlideDataDelegate: AnyObject {
    func getSavedArticleSlideData(from startDate: Date, to endEnd: Date) async -> SavedArticleSlideData
}

public protocol LegacyPageViewsDataDelegate: AnyObject {
    func getLegacyPageViews(from startDate: Date, to endDate: Date) async throws -> [WMFLegacyPageView]
}
