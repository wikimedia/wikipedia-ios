import XCTest
@testable import WMFData
@testable import WMFDataMocks
import CoreData

fileprivate class WMFMockYearInReviewDataController: WMFYearInReviewDataController {
    var shouldCreateOrRetrieve = true

    override init(coreDataStore: WMFCoreDataStore? = WMFDataEnvironment.current.coreDataStore, userDefaultsStore: (any WMFKeyValueStore)? = WMFDataEnvironment.current.userDefaultsStore, developerSettingsDataController: any WMFDeveloperSettingsDataControlling = WMFDeveloperSettingsDataController.shared) throws {

        let readCountSlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: true)
        let editCountSlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: true)
        let donateCountSlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: true)
        let mostReadDaySlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: true)
		let viewCountSlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: true)
        let savedCountSlideSettings = WMFFeatureConfigResponse.IOS.YearInReview.SlideSettings(isEnabled: true)
        let personalizedSlides = WMFFeatureConfigResponse.IOS.YearInReview.PersonalizedSlides(readCount: readCountSlideSettings, editCount: editCountSlideSettings, donateCount: donateCountSlideSettings, saveCount: savedCountSlideSettings, mostReadDay: mostReadDaySlideSettings, viewCount: viewCountSlideSettings)
        let yearInReview = WMFFeatureConfigResponse.IOS.YearInReview(yearID: "2024.2", isEnabled: false, countryCodes: ["FR", "IT"], primaryAppLanguageCodes: ["fr", "it"], dataPopulationStartDateString: "2024-01-01T00:00:00Z", dataPopulationEndDateString: "2024-11-01T00:00:00Z", personalizedSlides: personalizedSlides, hideDonateCountryCodes: ["AE", "AF", "AX", "BY", "CD", "CI"])
        let ios = WMFFeatureConfigResponse.IOS(version: 1, yir: [yearInReview])
        let config = WMFFeatureConfigResponse(ios: [ios])
        let developerSettingsDataController = WMFMockDeveloperSettingsDataController(featureConfig: config)
        
        try super.init(coreDataStore: coreDataStore, developerSettingsDataController: developerSettingsDataController)
    }

    override func shouldPopulateYearInReviewReportData(countryCode: String?, primaryAppLanguageProject: WMFProject?) -> Bool {
        return shouldCreateOrRetrieve
    }

    override func initialSlides(year: Int, moc: NSManagedObjectContext) throws -> Set<CDYearInReviewSlide> {
        
        var results = Set<CDYearInReviewSlide>()
        
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
        
        let savedCountSlide = try coreDataStore.create(entityType: CDYearInReviewSlide.self, in: moc)
        savedCountSlide.year = 2024
        savedCountSlide.id = WMFYearInReviewPersonalizedSlideID.saveCount.rawValue
        savedCountSlide.evaluated = false
        savedCountSlide.display = false
        savedCountSlide.data = nil
        results.insert(savedCountSlide)
        
        let mostReadDaySlide = try coreDataStore.create(entityType: CDYearInReviewSlide.self, in: moc)
        mostReadDaySlide.year = 2024
        mostReadDaySlide.id = WMFYearInReviewPersonalizedSlideID.mostReadDay.rawValue
        mostReadDaySlide.evaluated = false
        mostReadDaySlide.display = false
        mostReadDaySlide.data = nil
        results.insert(mostReadDaySlide)
        
        let viewCountSlide = try coreDataStore.create(entityType: CDYearInReviewSlide.self, in: moc)
        viewCountSlide.year = 2024
        viewCountSlide.id = WMFYearInReviewPersonalizedSlideID.viewCount.rawValue
        viewCountSlide.evaluated = false
        viewCountSlide.display = false
        viewCountSlide.data = nil
        results.insert(viewCountSlide)
        
        return results
    }
    
    override func fetchUserContributionsCount(username: String, project: WMFProject?, startDate: String, endDate: String) async throws -> (Int, Bool) {
        return (27, false)
    }
}

final class WMFYearInReviewDataControllerCreateOrRetrieveTests: XCTestCase {
    
    enum TestsError: Error {
        case missingDataController
    }
    
    var store: WMFCoreDataStore?
    fileprivate var dataController: WMFMockYearInReviewDataController?
    
    lazy var enProject: WMFProject = {
        let language = WMFLanguage(languageCode: "es", languageVariantCode: nil)
        return .wikipedia(language)
    }()

    let year = 2023
    let countryCode = "US"
    let username = "user"

    override func setUp() async throws {
        
        let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try await WMFCoreDataStore(appContainerURL: temporaryDirectory)
        
        self.store = store
        
        self.dataController = try WMFMockYearInReviewDataController(coreDataStore: store)
        
        try await super.setUp()
    }

    func testShouldNotCreateOrRetrieveYearInReview() async throws {
        
        guard let dataController else {
            throw TestsError.missingDataController
        }
        
        dataController.shouldCreateOrRetrieve = false
        let report = try await dataController.populateYearInReviewReportData(for: year, countryCode: countryCode, primaryAppLanguageProject: enProject, username: username, userID: nil, savedSlideDataDelegate: self, legacyPageViewsDataDelegate: self)
        XCTAssertNil(report, "Expected nil when shouldCreateOrRetrieveYearInReview returns false")

    }

    func testShouldCreateOrRetrieveYearInReview() async throws {
        
        guard let dataController else {
            throw TestsError.missingDataController
        }
        
        var report = try await dataController.populateYearInReviewReportData(for: year, countryCode: countryCode, primaryAppLanguageProject: enProject, username: username, userID: nil, savedSlideDataDelegate: self, legacyPageViewsDataDelegate: self)
        
        dataController.shouldCreateOrRetrieve = true

        let existingSlide1 = WMFYearInReviewSlide(year: year, id: .readCount, evaluated: true, display: true)
        let existingSlide2 = WMFYearInReviewSlide(year: year, id: .saveCount, evaluated: true, display: true)
        let existingSlide3 = WMFYearInReviewSlide(year: year, id: .mostReadDay, evaluated: true, display: true)
        let existingSlide4 = WMFYearInReviewSlide(year: year, id: .editCount, evaluated: true, display: true)
        let existingSlide5 = WMFYearInReviewSlide(year: year, id: .viewCount, evaluated: true, display: true)
        let existingSlide6 = WMFYearInReviewSlide(year: year, id: .donateCount, evaluated: true, display: true)
        
        let existingReport = WMFYearInReviewReport(year: year, slides: [existingSlide1, existingSlide2, existingSlide3, existingSlide4, existingSlide5, existingSlide6])

        try await dataController.saveYearInReviewReport(existingReport)

        report = try await dataController.populateYearInReviewReportData(for: year, countryCode: countryCode, primaryAppLanguageProject: enProject, username: username, userID: nil, savedSlideDataDelegate: self, legacyPageViewsDataDelegate: self)

        XCTAssertNotNil(report, "Expected a report to be retrieved")
        XCTAssertEqual(report?.year, year)
        XCTAssertEqual(report?.slides.count, 6)
    }

    func testShouldCreateOrRetrieveYearInReviewWithNewReport() async throws {
        
        guard let dataController else {
            throw TestsError.missingDataController
        }

        var report = try await dataController.populateYearInReviewReportData(for: year, countryCode: countryCode, primaryAppLanguageProject: enProject, username: username, userID: nil, savedSlideDataDelegate: self, legacyPageViewsDataDelegate: self)

        try await dataController.deleteYearInReviewReport(year: year)

        report = try await dataController.populateYearInReviewReportData(for: year, countryCode: countryCode, primaryAppLanguageProject: enProject, username: username, userID: nil, savedSlideDataDelegate: self, legacyPageViewsDataDelegate: self)

        XCTAssertNotNil(report, "Expected a new report to be created")
        XCTAssertEqual(report?.year, year)
        XCTAssertEqual(report?.slides.count, 6)
    }
}

extension WMFYearInReviewDataControllerCreateOrRetrieveTests: SavedArticleSlideDataDelegate {
    func getSavedArticleSlideData(from startDate: Date, to endEnd: Date) async -> WMFData.SavedArticleSlideData {
        return SavedArticleSlideData(savedArticlesCount: 30, articleTitles: ["Cat", "Dog", "Bird"])
    }
}

extension WMFYearInReviewDataControllerCreateOrRetrieveTests: LegacyPageViewsDataDelegate {
    func getLegacyPageViews(from startDate: Date, to endDate: Date) async throws -> [WMFData.WMFLegacyPageView] {
        return []
    }
    
    
}
