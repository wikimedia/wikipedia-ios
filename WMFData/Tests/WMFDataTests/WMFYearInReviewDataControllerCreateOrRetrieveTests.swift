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
        let yearInReview = WMFFeatureConfigResponse.IOS.YearInReview(yearID: "2024.2", isEnabled: true, countryCodes: ["FR", "IT"], primaryAppLanguageCodes: ["fr", "it"], dataPopulationStartDateString: "2024-01-01T00:00:00Z", dataPopulationEndDateString: "2024-11-01T00:00:00Z", personalizedSlides: personalizedSlides, hideDonateCountryCodes: ["AE", "AF", "AX", "BY", "CD", "CI"])
        let ios = WMFFeatureConfigResponse.IOS(version: 1, yir: [yearInReview])
        let config = WMFFeatureConfigResponse(ios: [ios])
        let developerSettingsDataController = WMFMockDeveloperSettingsDataController(featureConfig: config)
        
        try super.init(coreDataStore: coreDataStore, developerSettingsDataController: developerSettingsDataController)
    }

    override func shouldPopulateYearInReviewReportData(countryCode: String?, primaryAppLanguageProject: WMFProject?) -> Bool {
        return shouldCreateOrRetrieve
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

    let year = 2024
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

        let existingSlide1 = WMFYearInReviewSlide(year: year, id: .readCount)
        let existingSlide2 = WMFYearInReviewSlide(year: year, id: .saveCount)
        let existingSlide3 = WMFYearInReviewSlide(year: year, id: .mostReadDay)
        let existingSlide4 = WMFYearInReviewSlide(year: year, id: .editCount)
        let existingSlide5 = WMFYearInReviewSlide(year: year, id: .viewCount)
        let existingSlide6 = WMFYearInReviewSlide(year: year, id: .donateCount)
        
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

        var report = try await dataController.populateYearInReviewReportData(for: year, countryCode: countryCode, primaryAppLanguageProject: enProject, username: nil, userID: nil, savedSlideDataDelegate: self, legacyPageViewsDataDelegate: self)

        try await dataController.deleteYearInReviewReport(year: year)

        report = try await dataController.populateYearInReviewReportData(for: year, countryCode: countryCode, primaryAppLanguageProject: enProject, username: nil, userID: nil, savedSlideDataDelegate: self, legacyPageViewsDataDelegate: self)

        XCTAssertNotNil(report, "Expected a new report to be created")
        XCTAssertEqual(report?.year, year)
        XCTAssertEqual(report?.slides.count, 4) // Expecting 4 slides instead of 6, because editing data (username and userID) is passed as nil above.
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
