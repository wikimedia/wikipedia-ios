import XCTest
@testable import WMFData
@testable import WMFDataMocks
import CoreData

fileprivate class WMFMockYearInReviewDataController: WMFYearInReviewDataController, @unchecked Sendable {
    var shouldCreateOrRetrieve = true

    override init(coreDataStore: WMFCoreDataStore? = WMFDataEnvironment.current.coreDataStore, userDefaultsStore: (any WMFKeyValueStore)? = WMFDataEnvironment.current.userDefaultsStore, developerSettingsDataController: any WMFDeveloperSettingsDataControlling = WMFDeveloperSettingsDataController.shared, experimentStore: WMFKeyValueStore? = WMFDataEnvironment.current.sharedCacheStore) throws {

        let common = WMFFeatureConfigResponse.Common(yir: [WMFFeatureConfigResponse.Common.YearInReview.testConfig])
        let config = WMFFeatureConfigResponse(common: common, ios: WMFFeatureConfigResponse.IOS(hCaptcha: nil))
        
        let developerSettingsDataController = WMFMockDeveloperSettingsDataController(featureConfig: config)

        try super.init(coreDataStore: coreDataStore, developerSettingsDataController: developerSettingsDataController)
    }

    override func shouldPopulateYearInReviewReportData(countryCode: String?) -> Bool {
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
        let language = WMFLanguage(languageCode: "en", languageVariantCode: nil)
        return .wikipedia(language)
    }()

    let year = 2026
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
        let report = try await dataController.populateYearInReviewReportData(for: year, countryCode: countryCode, primaryAppLanguageProject: enProject, username: username, userID: nil, globalUserID: nil, savedSlideDataDelegate: self, legacyPageViewsDataDelegate: self)
        XCTAssertNil(report, "Expected nil when shouldCreateOrRetrieveYearInReview returns false")

    }

    func testShouldCreateOrRetrieveYearInReview() async throws {
        
        guard let dataController else {
            throw TestsError.missingDataController
        }
        
        var report = try await dataController.populateYearInReviewReportData(for: year, countryCode: countryCode, primaryAppLanguageProject: enProject, username: username, userID: nil, globalUserID: nil, savedSlideDataDelegate: self, legacyPageViewsDataDelegate: self)
        
        dataController.shouldCreateOrRetrieve = true

        let existingSlide1 = WMFYearInReviewSlide(year: year, id: .readCount)
        let existingSlide2 = WMFYearInReviewSlide(year: year, id: .saveCount)
        let existingSlide3 = WMFYearInReviewSlide(year: year, id: .mostReadDate)
        let existingSlide4 = WMFYearInReviewSlide(year: year, id: .editCount)
        let existingSlide5 = WMFYearInReviewSlide(year: year, id: .viewCount)
        let existingSlide6 = WMFYearInReviewSlide(year: year, id: .donateCount)
        
        let existingReport = WMFYearInReviewReport(year: year, slides: [existingSlide1, existingSlide2, existingSlide3, existingSlide4, existingSlide5, existingSlide6])

        try await dataController.saveYearInReviewReport(existingReport)

        report = try await dataController.populateYearInReviewReportData(for: year, countryCode: countryCode, primaryAppLanguageProject: enProject, username: username, userID: nil, globalUserID: nil, savedSlideDataDelegate: self, legacyPageViewsDataDelegate: self)

        XCTAssertNotNil(report, "Expected a report to be retrieved")
        XCTAssertEqual(report?.year, year)
        XCTAssertEqual(report?.slides.count, 6)
    }

    func testShouldCreateOrRetrieveYearInReviewWithNewReport() async throws {
        
        guard let dataController else {
            throw TestsError.missingDataController
        }

        var report = try await dataController.populateYearInReviewReportData(for: year, countryCode: countryCode, primaryAppLanguageProject: enProject, username: nil, userID: nil, globalUserID: nil, savedSlideDataDelegate: self, legacyPageViewsDataDelegate: self)

        try await dataController.deleteYearInReviewReport(year: year)

        report = try await dataController.populateYearInReviewReportData(for: year, countryCode: countryCode, primaryAppLanguageProject: enProject, username: nil, userID: nil, globalUserID: nil, savedSlideDataDelegate: self, legacyPageViewsDataDelegate: self)

        XCTAssertNotNil(report, "Expected a new report to be created")
        XCTAssertEqual(report?.year, year)
        XCTAssertEqual(report?.slides.count, 3)
    }

    // MARK: - Niche interest slide format

    /// Saves a report with only a niche interest slide, then populates the report again.
    /// The categories data controller reads the store from the environment, so this sets it for the test.
    private func populateReport(withNicheInterestData data: Data) async throws -> WMFYearInReviewReport? {
        guard let dataController else {
            throw TestsError.missingDataController
        }

        let previousStore = WMFDataEnvironment.current.coreDataStore
        WMFDataEnvironment.current.coreDataStore = store
        defer {
            WMFDataEnvironment.current.coreDataStore = previousStore
        }

        let slide = WMFYearInReviewSlide(year: year, id: .mostReadCategories, data: data)
        try await dataController.saveYearInReviewReport(WMFYearInReviewReport(year: year, slides: [slide]))

        return try await dataController.populateYearInReviewReportData(for: year, countryCode: countryCode, primaryAppLanguageProject: enProject, username: nil, userID: nil, globalUserID: nil, savedSlideDataDelegate: self, legacyPageViewsDataDelegate: self)
    }

    /// An older build stored the niche interest slide as an array of category names.
    /// The slide is frozen, but the report must build it again in the current format.
    func testLegacyNicheInterestSlideIsBuiltAgain() async throws {
        let legacyData = try JSONEncoder().encode(["Cats", "Dogs"])

        let report = try await populateReport(withNicheInterestData: legacyData)

        let slides = report?.slides.filter { $0.id == .mostReadCategories } ?? []
        XCTAssertEqual(slides.count, 1, "The legacy slide is replaced, not kept next to the new slide")
        let data = try XCTUnwrap(slides.first?.data)
        XCTAssertNoThrow(try JSONDecoder().decode(WMFYearInReviewMostReadCategorySlideData.self, from: data))
    }

    /// A slide in the current format keeps its category. No categories are in the store, so a
    /// new pick would have no category.
    func testCurrentNicheInterestSlideKeepsItsCategory() async throws {
        let storedData = try JSONEncoder().encode(WMFYearInReviewMostReadCategorySlideData(categoryName: "Executed female serial killers"))

        let report = try await populateReport(withNicheInterestData: storedData)

        let slides = report?.slides.filter { $0.id == .mostReadCategories } ?? []
        XCTAssertEqual(slides.count, 1)
        let data = try XCTUnwrap(slides.first?.data)
        let payload = try JSONDecoder().decode(WMFYearInReviewMostReadCategorySlideData.self, from: data)
        XCTAssertEqual(payload.categoryName, "Executed female serial killers")
    }

    func testNicheInterestFormatCheck() throws {
        let legacyData = try JSONEncoder().encode(["Cats", "Dogs"])
        let currentData = try JSONEncoder().encode(WMFYearInReviewMostReadCategorySlideData(categoryName: "Cats"))
        let currentDataWithoutCategory = try JSONEncoder().encode(WMFYearInReviewMostReadCategorySlideData(categoryName: nil))

        XCTAssertFalse(YearInReviewMostReadCategoriesSlideDataController.hasCurrentFormat(legacyData))
        XCTAssertFalse(YearInReviewMostReadCategoriesSlideDataController.hasCurrentFormat(nil))
        XCTAssertTrue(YearInReviewMostReadCategoriesSlideDataController.hasCurrentFormat(currentData))
        XCTAssertTrue(YearInReviewMostReadCategoriesSlideDataController.hasCurrentFormat(currentDataWithoutCategory), "A stored nil category is a choice, not old data")
    }
}

extension WMFYearInReviewDataControllerCreateOrRetrieveTests: SavedArticleSlideDataDelegate {
    func getSavedArticleSlideData(from startDate: Date, to endEnd: Date) async -> WMFData.SavedArticleSlideData {
        return SavedArticleSlideData(savedArticlesCount: 30, articleTitles: ["Cat", "Dog", "Bird"])
    }
}

extension WMFYearInReviewDataControllerCreateOrRetrieveTests: LegacyPageViewsDataDelegate {
    func getLegacyPageViews(from startDate: Date, to endDate: Date, needsLatLong: Bool) async throws -> [WMFData.WMFLegacyPageView] {
        return []
    }
}
