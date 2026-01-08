import Foundation
import UIKit
import CoreData

@preconcurrency
@objc public class WMFYearInReviewDataController: NSObject {
    
    public enum CustomError: Error {
        case missingExperimentsDataController
        case unexpectedAssignment
        case alreadyAssignedExperiment
        case notQualifiedForExperiment
        case missingPrimaryAppLanguage
    }
    
    public let coreDataStore: WMFCoreDataStore
    private let userDefaultsStore: WMFKeyValueStore?
    private let developerSettingsDataController: WMFDeveloperSettingsDataControlling
    private let experimentsDataController: WMFExperimentsDataController?

    @objc public static let targetYear = 2025
    public static let appShareLink = "https://apps.apple.com/app/apple-store/id324715238?pt=208305&ct=yir_2025_share&mt=8"

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
    
    public var config: WMFFeatureConfigResponse.Common.YearInReview? {
        if let featureConfig = developerSettingsDataController.loadFeatureConfig(),
           let config = featureConfig.common.yir(year: Self.targetYear) {
            return config
        }
        
        return nil
    }

    public init(coreDataStore: WMFCoreDataStore? = WMFDataEnvironment.current.coreDataStore, userDefaultsStore: WMFKeyValueStore? = WMFDataEnvironment.current.userDefaultsStore, developerSettingsDataController: WMFDeveloperSettingsDataControlling = WMFDeveloperSettingsDataController.shared, experimentStore: WMFKeyValueStore? = WMFDataEnvironment.current.sharedCacheStore) throws {

        guard let coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }
        self.coreDataStore = coreDataStore
        self.userDefaultsStore = userDefaultsStore
        self.developerSettingsDataController = developerSettingsDataController
        if let experimentStore {
            self.experimentsDataController = WMFExperimentsDataController(store: experimentStore)
        } else {
            self.experimentsDataController = nil
        }
    }

    // MARK: - Feature Announcement

    private var featureAnnouncementStatus: FeatureAnnouncementStatus {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.seenYearInReviewFeatureAnnouncement.rawValue)) ?? FeatureAnnouncementStatus.default
    }

    private var seenIntroSlideStatus: YiRNotificationAnnouncementStatus {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.seenYearInReviewIntroSlide.rawValue)) ?? YiRNotificationAnnouncementStatus.default
    }
    
    public func shouldShowYiRNotification(isLoggedOut: Bool, isTemporaryAccount: Bool) -> Bool {
        
        if isTemporaryAccount {
            return false
        }

        if isLoggedOut {
            return !hasTappedProfileItem && !hasSeenYiRIntroSlide && shouldShowYearInReviewEntryPoint(countryCode: Locale.current.region?.identifier)
        }
        return !hasSeenYiRIntroSlide && shouldShowYearInReviewEntryPoint(countryCode: Locale.current.region?.identifier)
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
            (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.seenYearInReviewFeatureAnnouncement.rawValue)) ?? false
        }
        set {
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.seenYearInReviewFeatureAnnouncement.rawValue, value: newValue)
        }
    }

    public func shouldShowYearInReviewFeatureAnnouncement() -> Bool {
        
        guard let config = self.config else {
            return false
        }

        guard config.isActive(for: Date()) else {
            return false
        }

        guard yearInReviewSettingsIsEnabled else {
            return false
        }

        guard shouldShowYearInReviewEntryPoint(countryCode: Locale.current.region?.identifier) else {
            return false
        }

        guard !hasPresentedYiRFeatureAnnouncementModel else {
            return false
        }

        guard !hasSeenYiRIntroSlide else {
            return false
        }

        return true
    }

    // MARK: Entry Point

    public func shouldShowYearInReviewEntryPoint(countryCode: String?, currentDate: Date? = Date()) -> Bool {
        assert(Thread.isMainThread, "This method must be called from the main thread in order to keep it synchronous")
        
        let currentDate = currentDate ?? Date()

        guard yearInReviewSettingsIsEnabled else {
            return false
        }

        guard let countryCode else {
            return false
        }
        
        guard let config = self.config else {
            return false
        }

        guard config.isActive(for: currentDate) else {
            return false
        }

        // Check remote valid country codes
        let uppercaseConfigHideCountryCodes = config.hideCountryCodes.map { $0.uppercased() }
        guard !uppercaseConfigHideCountryCodes.contains(countryCode.uppercased()) else {
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

    @objc public func shouldShowYearInReviewSettingsItem(countryCode: String?) -> Bool {

        guard let countryCode else {
            return false
        }
        
        guard let config = self.config else {
            return false
        }

        // Note: Purposefully not checking config's yirConfig.isActive here. We want to continue showing the Settings item after we have disabled the feature remotely.

        // Check remote valid country codes
        let uppercaseConfigHideCountryCodes = config.hideCountryCodes.map { $0.uppercased() }
        guard !uppercaseConfigHideCountryCodes.contains(countryCode.uppercased()) else {
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
    
    // MARK: - Experiment
    
    public enum YiRLoginExperimentAssignment {
        case control
        case groupB
    }
    
    private var assignmentCache: YiRLoginExperimentAssignment?
    
    public func needsLoginExperimentAssignment() -> Bool {
        if developerSettingsDataController.enableYiRLoginExperimentB {
            return false
        }
        
        if developerSettingsDataController.enableYiRLoginExperimentControl {
            return false
        }
        
        guard let primaryAppLanguage = WMFDataEnvironment.current.primaryAppLanguage else {
            return false
        }
        
        guard primaryAppLanguage.qualifiesForExperiment else {
            return false
        }
        
        guard let experimentsDataController else {
            return false
        }
        
        guard experimentsDataController.bucketForExperiment(.yirLoginPrompt) == nil else {
            return false
        }
        
        return true
    }
    
    public func assignLoginExperimentIfNeeded() throws -> YiRLoginExperimentAssignment {
        
        guard let experimentsDataController else {
            throw CustomError.missingExperimentsDataController
        }
        
        let bucketValue = try experimentsDataController.determineBucketForExperiment(.yirLoginPrompt, withPercentage: 50)

        let assignment: YiRLoginExperimentAssignment
        
        switch bucketValue {
        case .yirLoginPromptControl:
            assignment = .control
        case .yirLoginPromptGroupB:
            assignment = .groupB
        default:
            throw CustomError.unexpectedAssignment
        }
        
        self.assignmentCache = assignment
        return assignment
    }
    
    public var bypassLoginForPersonalizedFlow: Bool {
        if developerSettingsDataController.enableYiRLoginExperimentB {
            return true
        }
        
        if developerSettingsDataController.enableYiRLoginExperimentControl {
            return false
        }
        
        let assignment = getLoginExperimentAssignment()
        if let assignment {
            switch assignment {
            case .control:
                return false
            case .groupB:
                return true
            }
        }
        
        return false
    }
    
    public func getLoginExperimentAssignment() -> YiRLoginExperimentAssignment? {
        guard let primaryAppLanguage = WMFDataEnvironment.current.primaryAppLanguage else {
            return nil
        }
        
        guard let experimentsDataController else {
            return nil
        }
        
        guard primaryAppLanguage.qualifiesForExperiment else {
            return nil
        }
        
        if let assignmentCache {
            return assignmentCache
        }
        
        guard let bucketValue = experimentsDataController.bucketForExperiment(.yirLoginPrompt) else {
            return nil
        }
        
        let assignment: YiRLoginExperimentAssignment
        switch bucketValue {
            
        case .yirLoginPromptControl:
            assignment = .control
        case .yirLoginPromptGroupB:
            assignment = .groupB
        default:
            return nil
        }
        
        self.assignmentCache = assignment
        return assignment
    }
    
    // MARK: Report Data Population

    func shouldPopulateYearInReviewReportData(countryCode: String?) -> Bool {
        
        guard yearInReviewSettingsIsEnabled else {
            return false
        }
        
        guard let countryCode else {
            return false
        }
        
        guard let config = self.config else {
            return false
        }
        
        guard config.isActive(for: Date()) else {
            return false
        }

        // Check remote valid country codes
        let uppercaseConfigHideCountryCodes = config.hideCountryCodes.map { $0.uppercased() }
        guard !uppercaseConfigHideCountryCodes.contains(countryCode.uppercased()) else {
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
    public func populateYearInReviewReportData(for year: Int, countryCode: String,  primaryAppLanguageProject: WMFProject?, username: String?, userID: Int?, globalUserID: Int?, savedSlideDataDelegate: SavedArticleSlideDataDelegate, legacyPageViewsDataDelegate: LegacyPageViewsDataDelegate) async throws -> WMFYearInReviewReport? {

        guard shouldPopulateYearInReviewReportData(countryCode: countryCode) else {
            return nil
        }

        await beginDataPopulationBackgroundTask()
        
        defer {
            endDataPopulationBackgroundTask()
        }

        let backgroundContext = try coreDataStore.newBackgroundContext
        
        guard let config = self.config else {
            return nil
        }

        let slideFactory = YearInReviewSlideDataControllerFactory(
            year: year,
            config: config,
            username: username,
            userID: userID,
            globalUserID: globalUserID,
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
            
            var finalCDSlides: Set<CDYearInReviewSlide> = []
            
            // Only preserve existing slides that should freeze
            for slide in cdReport.slides as? Set<CDYearInReviewSlide> ?? [] {
                if let cdSlideID = slide.id,
                   let slideID = WMFYearInReviewPersonalizedSlideID(rawValue: cdSlideID) {
                    let dataController = slideID.dataController()
                    if dataController.shouldFreeze {
                        finalCDSlides.insert(slide)
                    } else {
                        backgroundContext.delete(slide)
                    }
                }
            }

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
        
        guard let config = self.config else {
            return false
        }

        guard let locale = Locale.current.region?.identifier else {
            return false
        }

        guard config.hideDonateCountryCodes.contains(locale) else {
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
    
    public func updateContributorStatus(isContributor: Bool) {
        try? userDefaultsStore?.save(
            key: WMFUserDefaultsKey.qualifiesForIcon2025.rawValue,
            value: isContributor
        )
    }
}

public struct WMFYearInReviewReadData: Codable {
    public let readCount: Int
    public let minutesRead: Int
}

public class SavedArticleSlideData: NSObject, Codable {
    public let savedArticlesCount: Int
    public let articleTitles: [String]

    public init(savedArticlesCount: Int, articleTitles: [String]) {
        self.savedArticlesCount = savedArticlesCount
        self.articleTitles = articleTitles
    }
}

public struct DonateAndEditCounts: Codable {
    public let donateCount: Int?
    public let editCount: Int?
    
    public init(donateCount: Int?, editCount: Int?) {
        self.donateCount = donateCount
        self.editCount = editCount
    }
}

public protocol SavedArticleSlideDataDelegate: AnyObject {
    func getSavedArticleSlideData(from startDate: Date, to endEnd: Date) async -> SavedArticleSlideData
}

public protocol LegacyPageViewsDataDelegate: AnyObject {
    func getLegacyPageViews(from startDate: Date, to endDate: Date, needsLatLong: Bool) async throws -> [WMFLegacyPageView]
}

fileprivate extension WMFLanguage {
    var qualifiesForExperiment: Bool {
        return languageCode.lowercased() == "en"
    }
}
