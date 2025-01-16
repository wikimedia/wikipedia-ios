import Foundation
import UIKit
import CoreData

@preconcurrency
@objc public class WMFYearInReviewDataController: NSObject {

    public let coreDataStore: WMFCoreDataStore
    private let userDefaultsStore: WMFKeyValueStore?
    private let developerSettingsDataController: WMFDeveloperSettingsDataControlling

    private weak var savedSlideDataDelegate: SavedArticleSlideDataDelegate?
    private weak var legacyPageViewsDataDelegate: LegacyPageViewsDataDelegate?

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
    
    public func shouldShowYiRNotification(primaryAppLanguageProject: WMFProject?, isLoggedOut: Bool) -> Bool {
        if isLoggedOut {
            return !hasTappedProfileItem && !hasSeenYiRIntroSlide && shouldShowYearInReviewEntryPoint(countryCode: Locale.current.region?.identifier, primaryAppLanguageProject: primaryAppLanguageProject)
        }
        return !hasSeenYiRIntroSlide && shouldShowYearInReviewEntryPoint(countryCode: Locale.current.region?.identifier, primaryAppLanguageProject: primaryAppLanguageProject)
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

        guard let iosFeatureConfig = developerSettingsDataController.loadFeatureConfig()?.ios.first,
              let yirConfig = iosFeatureConfig.yir(yearID: targetConfigYearID) else {
            return false
        }

        // Check remote feature disable switch
        guard yirConfig.isEnabled else {
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

        guard let iosFeatureConfig = developerSettingsDataController.loadFeatureConfig()?.ios.first,
              let yirConfig = iosFeatureConfig.yir(yearID: targetConfigYearID) else {
            return false
        }

        guard let countryCode,
              let primaryAppLanguageProject else {
            return false
        }

        // Check remote feature disable switch
        guard yirConfig.isEnabled else {
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
        
        self.savedSlideDataDelegate = savedSlideDataDelegate
        self.legacyPageViewsDataDelegate = legacyPageViewsDataDelegate
        
        let backgroundContext = try coreDataStore.newBackgroundContext

        let result: (report: CDYearInReviewReport, needsReadingPopulation: Bool, needsEditingPopulation: Bool, needsDonatingPopulation: Bool, needsSaveCountPopulation: Bool, needsDayPopulation: Bool, needsEditViewsPopulation: Bool)? = try await backgroundContext.perform { [weak self] in

            return try self?.getYearInReviewReportAndDataPopulationFlags(year: year, backgroundContext: backgroundContext, project: primaryAppLanguageProject, username: username, userId: userID)
        }

        guard let result else {
            endDataPopulationBackgroundTask()
            return nil
        }

        let report = result.report
        
        if result.needsReadingPopulation == true || result.needsDayPopulation {
            
            var legacyPageViews: [WMFLegacyPageView] = []
            if let iosFeatureConfig = developerSettingsDataController.loadFeatureConfig()?.ios.first,
               let yirConfig = iosFeatureConfig.yir(yearID: targetConfigYearID),
               let startDate = yirConfig.dataPopulationStartDate,
               let endDate = yirConfig.dataPopulationEndDate,
               let legacyPageViewsDataDelegate = self.legacyPageViewsDataDelegate {
                legacyPageViews = try await legacyPageViewsDataDelegate.getLegacyPageViews(from: startDate, to: endDate)
            }
            
            try await backgroundContext.perform { [weak self] in
                if result.needsReadingPopulation {
                    try self?.populateReadingSlide(report: report, backgroundContext: backgroundContext, legacyPageViews: legacyPageViews)
                }
                
                if result.needsDayPopulation {
                    try self?.populateDaySlide(report: report, backgroundContext: backgroundContext, legacyPageViews: legacyPageViews)
                }
            }
        }

        if result.needsEditingPopulation == true {
            if let username {
                let edits = try await fetchEditCount(username: username, project: primaryAppLanguageProject)
                try await backgroundContext.perform { [weak self] in
                    try self?.populateEditingSlide(edits: edits, report: report, backgroundContext: backgroundContext)
                }
            }
        }

        if result.needsDonatingPopulation == true {
            try await backgroundContext.perform { [weak self] in
                try self?.populateDonatingSlide(report: report, backgroundContext: backgroundContext)
            }
        }

        if result.needsSaveCountPopulation == true {
            if let iosFeatureConfig = developerSettingsDataController.loadFeatureConfig()?.ios.first,
               let yirConfig = iosFeatureConfig.yir(yearID: targetConfigYearID),
               let startDate = yirConfig.dataPopulationStartDate,
               let endDate = yirConfig.dataPopulationEndDate {
                let savedArticlesData = await self.savedSlideDataDelegate?.getSavedArticleSlideData(from: startDate, to: endDate)

                try await backgroundContext.perform { [weak self] in
                    guard let self = self, let savedArticlesData = savedArticlesData else { return }
                    try self.populateSaveCountSlide(report: report, backgroundContext: backgroundContext, savedArticlesData: savedArticlesData)
                }
            }
        }
        
        if result.needsEditViewsPopulation == true {
            if let userID, let languageCode = primaryAppLanguageProject?.languageCode {
                let editViews = try await fetchEditViews(
                    project: primaryAppLanguageProject,
                    userId: userID,
                    language: languageCode
                )
                try await backgroundContext.perform { [weak self] in
                    try self?.populateViewCountSlide(
                        editViews: editViews,
                        report: report,
                        backgroundContext: backgroundContext
                    )
                }
            }
        }
        
        endDataPopulationBackgroundTask()

        return await backgroundContext.perform {
            return WMFYearInReviewReport(cdReport: report)
        }
    }

    private func getYearInReviewReportAndDataPopulationFlags(year: Int, backgroundContext: NSManagedObjectContext, project: WMFProject?, username: String?, userId: String?) throws -> (report: CDYearInReviewReport, needsReadingPopulation: Bool, needsEditingPopulation: Bool, needsDonatingPopulation: Bool, needsSaveCountPopulation: Bool, needsDayPopulation: Bool, needsEditViewsPopulation: Bool)? {

        let predicate = NSPredicate(format: "year == %d", year)
        let cdReport = try self.coreDataStore.fetchOrCreate(entityType: CDYearInReviewReport.self, predicate: predicate, in: backgroundContext)

        guard let cdReport else {
            return nil
        }

        cdReport.year = Int32(year)
        if (cdReport.slides?.count ?? 0) == 0 {
            cdReport.slides = try self.initialSlides(year: year, moc: backgroundContext) as NSSet
        }
        
        // If needed: Populate initial saveCount slide
        if var slides = cdReport.slides as? Set<CDYearInReviewSlide> {
            let containsSaveCount = slides.contains(where: { slide in
                slide.id == WMFYearInReviewPersonalizedSlideID.saveCount.rawValue
            })
            if !containsSaveCount,
                let initialSaveCountSlide = try? initialSaveCountSlide(year: year, moc: backgroundContext) {
                slides.insert(initialSaveCountSlide)
                cdReport.slides = slides as NSSet
            }
        }

        // If needed: Populate initial mostReadDay slide
        if var slides = cdReport.slides as? Set<CDYearInReviewSlide> {
            let containsMostRead = slides.contains(where: { slide in
                slide.id == WMFYearInReviewPersonalizedSlideID.mostReadDay.rawValue
            })
            if !containsMostRead,
                let initialMostReadDaySlide = try? initialMostReadDaySlide(year: year, moc: backgroundContext) {
                slides.insert(initialMostReadDaySlide)
                cdReport.slides = slides as NSSet
            }
        }
        
        // If needed: Populate initial viewCount slide
        if var slides = cdReport.slides as? Set<CDYearInReviewSlide> {
            let containsViewCount = slides.contains(where: { slide in
                slide.id == WMFYearInReviewPersonalizedSlideID.viewCount.rawValue
            })
            if !containsViewCount,
                let initialViewCountSlide = try? initialViewCountSlide(year: year, moc: backgroundContext) {
                slides.insert(initialViewCountSlide)
                cdReport.slides = slides as NSSet
            }
        }
        
        try self.coreDataStore.saveIfNeeded(moc: backgroundContext)

        guard let iosFeatureConfig = developerSettingsDataController.loadFeatureConfig()?.ios.first,
              let yirConfig = iosFeatureConfig.yir(yearID: targetConfigYearID) else {
            return nil
        }

        guard let cdSlides = cdReport.slides as? Set<CDYearInReviewSlide> else {
            return nil
        }

        var needsReadingPopulation = false
        var needsEditingPopulation = false
        var needsDonatingPopulation = false
        var needsSaveCountPopulation = false
        var needsDayPopulation = false
        var needsEditViewPopulation = false
        
        for slide in cdSlides {
            switch slide.id {

            case WMFYearInReviewPersonalizedSlideID.readCount.rawValue:
                if slide.evaluated == false && yirConfig.personalizedSlides.readCount.isEnabled {
                    needsReadingPopulation = true
                }
            case WMFYearInReviewPersonalizedSlideID.editCount.rawValue:
                if slide.evaluated == false && yirConfig.personalizedSlides.editCount.isEnabled && username != nil {
                    needsEditingPopulation = true
                }
            case WMFYearInReviewPersonalizedSlideID.donateCount.rawValue:
                if slide.evaluated == false && yirConfig.personalizedSlides.donateCount.isEnabled {
                    needsDonatingPopulation = true
                }
            case WMFYearInReviewPersonalizedSlideID.saveCount.rawValue:
                if slide.evaluated == false && yirConfig.personalizedSlides.saveCount.isEnabled {
                    needsSaveCountPopulation = true
                }
            case WMFYearInReviewPersonalizedSlideID.mostReadDay.rawValue:
                if slide.evaluated == false && yirConfig.personalizedSlides.mostReadDay.isEnabled {
                    needsDayPopulation = true
                }
            case WMFYearInReviewPersonalizedSlideID.viewCount.rawValue:
                if slide.evaluated == false && yirConfig.personalizedSlides.viewCount.isEnabled && userId != nil {
                    needsEditViewPopulation = true
                }
            default:
                debugPrint("Unrecognized Slide ID")
            }
        }

        return (report: cdReport, needsReadingPopulation: needsReadingPopulation, needsEditingPopulation: needsEditingPopulation, needsDonatingPopulation: needsDonatingPopulation, needsSaveCountPopulation: needsSaveCountPopulation, needsDayPopulation: needsDayPopulation, needsEditViewsPopulation: needsEditViewPopulation)
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

            let donateCountSlide = try coreDataStore.create(entityType: CDYearInReviewSlide.self, in: moc)
            donateCountSlide.year = 2024
            donateCountSlide.id = WMFYearInReviewPersonalizedSlideID.donateCount.rawValue
            donateCountSlide.evaluated = false
            donateCountSlide.display = false
            donateCountSlide.data = nil
            results.insert(donateCountSlide)

            if let savedArticlesSlide = try? initialSaveCountSlide(year: 2024, moc: moc) {
                results.insert(savedArticlesSlide)
            }

            if let initialMostReadDaySlide = try? initialMostReadDaySlide(year: 2024, moc: moc) {
                results.insert(initialMostReadDaySlide)
            }

            if let initialViewCountSlide = try? initialViewCountSlide(year: 2024, moc: moc) {
                results.insert(initialViewCountSlide)
            }
        }

        return results
    }
    
    private func initialSaveCountSlide(year: Int, moc: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let savedArticlesSlide = try coreDataStore.create(entityType: CDYearInReviewSlide.self, in: moc)
        savedArticlesSlide.year = Int32(year)
        savedArticlesSlide.id = WMFYearInReviewPersonalizedSlideID.saveCount.rawValue
        savedArticlesSlide.evaluated = false
        savedArticlesSlide.display = false
        savedArticlesSlide.data = nil
        return savedArticlesSlide
    }

    private func initialMostReadDaySlide(year: Int, moc: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let mostReadDaySlide = try coreDataStore.create(entityType: CDYearInReviewSlide.self, in: moc)
        mostReadDaySlide.year = Int32(year)
        mostReadDaySlide.id = WMFYearInReviewPersonalizedSlideID.mostReadDay.rawValue
        mostReadDaySlide.evaluated = false
        mostReadDaySlide.display = false
        mostReadDaySlide.data = nil
        return mostReadDaySlide
    }
    
    private func initialViewCountSlide(year: Int, moc: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let viewCountSlide = try coreDataStore.create(entityType: CDYearInReviewSlide.self, in: moc)
        viewCountSlide.year = Int32(year)
        viewCountSlide.id = WMFYearInReviewPersonalizedSlideID.viewCount.rawValue
        viewCountSlide.evaluated = false
        viewCountSlide.display = false
        viewCountSlide.data = nil
        return viewCountSlide
    }
    
    private func populateReadingSlide(report: CDYearInReviewReport, backgroundContext: NSManagedObjectContext, legacyPageViews: [WMFLegacyPageView]) throws {

        guard let slides = report.slides as? Set<CDYearInReviewSlide> else {
            return
        }

        for slide in slides {

            guard let slideID = slide.id else {
                continue
            }

            switch slideID {
            case WMFYearInReviewPersonalizedSlideID.readCount.rawValue:
                let encoder = JSONEncoder()
                slide.data = try encoder.encode(legacyPageViews.count)

                if legacyPageViews.count > 5 {
                    slide.display = true
                }

                slide.evaluated = true
            default:
                break
            }
        }

        try coreDataStore.saveIfNeeded(moc: backgroundContext)
    }

    private func fetchEditCount(username: String, project: WMFProject?) async throws -> Int {

        guard let iosFeatureConfig = developerSettingsDataController.loadFeatureConfig()?.ios.first,
              let yirConfig = iosFeatureConfig.yir(yearID: targetConfigYearID) else {
            throw WMFYearInReviewDataControllerError.missingRemoteConfig
        }

        let dataPopulationStartDateString = yirConfig.dataPopulationStartDateString
        let dataPopulationEndDateString = yirConfig.dataPopulationEndDateString

        let (edits, _) = try await fetchUserContributionsCount(username: username, project: project, startDate: dataPopulationStartDateString, endDate: dataPopulationEndDateString)

        return edits
    }

    private func populateEditingSlide(edits: Int, report: CDYearInReviewReport, backgroundContext: NSManagedObjectContext) throws {

        guard let slides = report.slides as? Set<CDYearInReviewSlide> else {
            return
        }

        for slide in slides {

            guard let slideID = slide.id else {
                continue
            }

            switch slideID {
            case WMFYearInReviewPersonalizedSlideID.editCount.rawValue:
                let encoder = JSONEncoder()
                slide.data = try encoder.encode(edits)

                if edits > 0 {
                    slide.display = true
                }

                slide.evaluated = true
            default:
                break
            }
        }

        try coreDataStore.saveIfNeeded(moc: backgroundContext)
    }

    private func populateSaveCountSlide(report: CDYearInReviewReport, backgroundContext: NSManagedObjectContext, savedArticlesData: SavedArticleSlideData) throws {

        guard let slides = report.slides as? Set<CDYearInReviewSlide> else {
            return
        }

        for slide in slides {
            guard let slideID = slide.id else { continue }

            switch slideID {
            case WMFYearInReviewPersonalizedSlideID.saveCount.rawValue:
                let encoder = JSONEncoder()
                slide.data = try encoder.encode(savedArticlesData)
                if savedArticlesData.savedArticlesCount > 2 {
                    slide.display = true
                }
                slide.evaluated = true
            default:
                break
            }
        }

        try coreDataStore.saveIfNeeded(moc: backgroundContext)
    }

    private func populateDaySlide(report: CDYearInReviewReport, backgroundContext: NSManagedObjectContext, legacyPageViews: [WMFLegacyPageView]) throws {
        
        var countsDictionary: [Int: Int] = [:]
        
        for legacyPageView in legacyPageViews {
            let timestamp = legacyPageView.viewedDate
            let calendar = Calendar.current
            let dayOfWeek = calendar.component(.weekday, from: timestamp) // Sunday = 1, Monday = 2, ..., Saturday = 7
                
            countsDictionary[dayOfWeek, default: 0] += 1
        }
        
        let pageViews = countsDictionary.sorted(by: { $0.key < $1.key }).map { dayOfWeek, count in
            WMFPageViewDay(day: dayOfWeek, viewCount: count)
        }

        guard let mostPopularDay = pageViews.max(by: { $0.viewCount < $1.viewCount }) else {
            return
        }

        guard let slides = report.slides as? Set<CDYearInReviewSlide> else {
            return
        }

        for slide in slides {
            guard let slideID = slide.id else {
                continue
            }

            switch slideID {
            case WMFYearInReviewPersonalizedSlideID.mostReadDay.rawValue:
                let encoder = JSONEncoder()
                slide.data = try encoder.encode(mostPopularDay)

                if mostPopularDay.viewCount > 0 {
                    slide.display = true
                }

                slide.evaluated = true
            default:
                break
            }
        }

        try coreDataStore.saveIfNeeded(moc: backgroundContext)
    }
    
    private func populateViewCountSlide(
        editViews: Int,
        report: CDYearInReviewReport,
        backgroundContext: NSManagedObjectContext
    ) throws {

        guard let slides = report.slides as? Set<CDYearInReviewSlide> else { return }

        for slide in slides {
            guard let slideID = slide.id else { continue }

            switch slideID {
            case WMFYearInReviewPersonalizedSlideID.viewCount.rawValue:
                let encoder = JSONEncoder()
                slide.data = try encoder.encode(editViews)

                if editViews > 0 {
                    slide.display = true
                }

                slide.evaluated = true
            default:
                break
            }
        }

        try coreDataStore.saveIfNeeded(moc: backgroundContext)
    }
    
    public func fetchEditViews(project: WMFProject?, userId: String, language: String) async throws -> (Int) {
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

    public func fetchEditViews(project: WMFProject?, userId: String, language: String, completion: @escaping (Result<Int, Error>) -> Void) {

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

    private func populateDonatingSlide(report: CDYearInReviewReport, backgroundContext: NSManagedObjectContext) throws {

        guard let iosFeatureConfig = developerSettingsDataController.loadFeatureConfig()?.ios.first,
              let yirConfig = iosFeatureConfig.yir(yearID: targetConfigYearID) else {
            return
        }

        guard let dataPopulationStartDate = yirConfig.dataPopulationStartDate,
              let dataPopulationEndDate = yirConfig.dataPopulationEndDate else {
            return
        }

        let donateHistory = WMFDonateDataController.shared.loadLocalDonationHistory(startDate: dataPopulationStartDate, endDate: dataPopulationEndDate)
        let donateCount = donateHistory?.count ?? 0

        guard let slides = report.slides as? Set<CDYearInReviewSlide> else {
            return
        }

        for slide in slides {

            guard let slideID = slide.id else {
                continue
            }

            switch slideID {
            case WMFYearInReviewPersonalizedSlideID.donateCount.rawValue:
                let encoder = JSONEncoder()
                slide.data = try encoder.encode(donateCount)

                if donateCount > 0 {
                    slide.display = true
                }

                slide.evaluated = true
            default:
                break
            }
        }

        try coreDataStore.saveIfNeeded(moc: backgroundContext)
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
        case "donateCount":
            return .donateCount
        case "mostReadDay":
            return .mostReadDay
        case "saveCount":
            return .saveCount
        case "viewCount":
            return .viewCount
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

    public func deleteAllPersonalizedEditingData() async throws {
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

                    guard slide.id == WMFYearInReviewPersonalizedSlideID.editCount.rawValue ||
                            slide.id == WMFYearInReviewPersonalizedSlideID.viewCount.rawValue ||
                            slide.id == WMFYearInReviewPersonalizedSlideID.saveCount.rawValue
                    else {
                        continue
                    }

                    slide.data = nil
                    slide.display = false
                    slide.evaluated = false
                }
            }

            try self.coreDataStore.saveIfNeeded(moc: backgroundContext)
        }
    }

    public func fetchUserContributionsCount(username: String, project: WMFProject?, startDate: String, endDate: String) async throws -> (Int, Bool) {
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

    public func fetchUserContributionsCount(username: String, project: WMFProject?, startDate: String, endDate: String, completion: @escaping (Result<(Int, Bool), Error>) -> Void) {
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

    public func shouldHideDonateButton() -> Bool {
        guard let iosFeatureConfig = developerSettingsDataController.loadFeatureConfig()?.ios.first,
              let yirConfig = iosFeatureConfig.yir(yearID: targetConfigYearID) else {
            return false
        }

        guard let locale = Locale.current.region?.identifier else {
            return false
        }

        guard yirConfig.hideDonateCountryCodes.contains(locale) else {
            return false
        }

        return true
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
    
    struct UserStats: Decodable {
        let version: Int
        let userId: Int
        let userName: String
        let receivedThanksCount: Int
        let editCountByNamespace: [String: Int]
        let editCountByDay: [String: Int]
        let editCountByTaskType: [String: Int]
        let totalUserEditCount: Int
        let revertedEditCount: Int
        let newcomerTaskEditCount: Int
        let lastEditTimestamp: Int
        let generatedAt: Int
        let longestEditingStreak: LongestEditingStreak
        let totalEditsCount: Int
        let dailyTotalViews: [String: Int]
        let recentEditsWithoutPageviews: [String]
        let topViewedArticles: [String: TopViewedArticle]
        let topViewedArticlesCount: Int
        let totalPageviewsCount: Int
    }

    struct LongestEditingStreak: Decodable {
        let datePeriod: DatePeriod
        let totalEditCountForPeriod: Int
    }

    struct DatePeriod: Decodable {
        let start: String
        let end: String
        let days: Int
    }

    struct TopViewedArticle: Decodable {
        let imageUrl: String
        let firstEditDate: String
        let newestEdit: String
        let views: [String: Int]
        let viewsCount: Int
        let pageviewsUrl: String
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
