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
        if isTemporaryAccount {
            return false
        }

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

        let backgroundContext = try coreDataStore.newBackgroundContext

        let yirConfig = developerSettingsDataController.loadFeatureConfig()?.ios.first?.yir(yearID: targetConfigYearID)

        guard let yirConfig else {
            endDataPopulationBackgroundTask()
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
            legacyPageViewsDataDelegate: legacyPageViewsDataDelegate,
            fetchEditCount: { username, project in
                try await self.fetchEditCount(username: username, project: project)
            },
            fetchEditViews: { project, userId, language in
                try await self.fetchEditViews(project: project, userId: userId, language: language)
            },
            donationFetcher: { start, end in
                WMFDonateDataController.shared.loadLocalDonationHistory(startDate: start, endDate: end)?.count
            }
        )

        let existingIDs = try await backgroundContext.perform {
            let predicate = NSPredicate(format: "year == %d", year)
            let cdReport = try self.coreDataStore.fetchOrCreate(
                entityType: CDYearInReviewReport.self,
                predicate: predicate,
                in: backgroundContext
            )
            return Set((cdReport?.slides as? Set<CDYearInReviewSlide>)?.compactMap { $0.id } ?? [])
        }

        var slideDataControllers = try await slideFactory.makeSlideDataControllers(missingFrom: existingIDs)
        for index in slideDataControllers.indices {
            do {
                try await slideDataControllers[index].populateSlideData(in: backgroundContext)
                slideDataControllers[index].isEvaluated = true
            } catch {
                slideDataControllers[index].isEvaluated = false
            }
        }

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

            return cdReport
        }

        endDataPopulationBackgroundTask()

        return await backgroundContext.perform {
            let slides: [WMFYearInReviewSlide] = (report.slides as? Set<CDYearInReviewSlide>)?.compactMap { cdSlide in
                guard let id = self.getSlideId(cdSlide.id) else { return nil }
                return WMFYearInReviewSlide(year: Int(cdSlide.year), id: id, data: cdSlide.data)
            } ?? []

            return WMFYearInReviewReport(year: year, slides: slides)
        }
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
        guard let cdReport = cdReports.first else { return nil }

        let slides = (cdReport.slides as? Set<CDYearInReviewSlide>)?.compactMap(makeSlide(from:)) ?? []
        return WMFYearInReviewReport(year: Int(cdReport.year), slides: slides)
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

    private func makeSlide(from cdSlide: CDYearInReviewSlide) -> WMFYearInReviewSlide? {
        guard let id = self.getSlideId(cdSlide.id) else { return nil }
        return WMFYearInReviewSlide(
            year: Int(cdSlide.year),
            id: id,
            data: cdSlide.data
        )
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


    private func getSlideId(_ idString: String?) -> WMFYearInReviewPersonalizedSlideID? {
        guard let raw = idString else { return nil }
        return WMFYearInReviewPersonalizedSlideID(rawValue: raw)
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
                            else { continue }
                    slide.data = nil
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
