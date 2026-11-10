import XCTest
@testable import WMFData
@testable import WMFDataMocks
import CoreData
import WMFDataTestSupport

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
    
    private let fixture = WMFDataTestFixture()
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
        try await super.setUp()
        await fixture.setUp()

        let store = try await fixture.makeTemporaryCoreDataStore()
        self.store = store

        self.dataController = try WMFMockYearInReviewDataController(coreDataStore: store)
    }

    override func tearDown() async throws {
        dataController = nil
        store = nil
        await fixture.resetWMFDataTestState()
        await fixture.tearDown()
        try await super.tearDown()
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

        // The read count slide is frozen, so it is kept only if its data uses the current format.
        // Data in an older format, or no data, makes the report build the slide again.
        let readData = try JSONEncoder().encode(WMFYearInReviewReadData(readCount: 5, minutesRead: 10))
        let existingSlide1 = WMFYearInReviewSlide(year: year, id: .readCount, data: readData)
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

    func testOutdatedFrozenSlideStaysWhenItsRebuildFails() async throws {
        // The read count data controller reads the store from the environment. With no store there,
        // its rebuild fails. The report itself uses its own store. The fixture changes the environment
        // under the global test lock, then restores it.
        let report = try await fixture.withConfiguredEnvironment(configure: {
            WMFDataEnvironment.current.coreDataStore = nil
        }) {
            XCTAssertNil(WMFDataEnvironment.current.coreDataStore)
            let dataController = try WMFMockYearInReviewDataController(coreDataStore: try await fixture.makeTemporaryCoreDataStore())

            // Read data from before the minutes read slide: no format.
            let oldData = try JSONSerialization.data(withJSONObject: ["readCount": 5, "minutesRead": 500])
            try await dataController.saveYearInReviewReport(WMFYearInReviewReport(year: year, slides: [
                WMFYearInReviewSlide(year: year, id: .readCount, data: oldData)
            ]))

            return try await dataController.populateYearInReviewReportData(for: year, countryCode: countryCode, primaryAppLanguageProject: enProject, username: username, userID: nil, globalUserID: nil, savedSlideDataDelegate: self, legacyPageViewsDataDelegate: self)
        }

        let slide = try XCTUnwrap(report?.slides.first { $0.id == .readCount }, "the old slide stays when it cannot be built again")
        let readData = try JSONDecoder().decode(WMFYearInReviewReadData.self, from: try XCTUnwrap(slide.data))
        XCTAssertEqual(readData.readCount, 5)
        XCTAssertFalse(readData.isMinutesReadEligible, "the old minutes used older rules, so they do not show")
        XCTAssertEqual(WMFYearInReviewDataController.fullSlideCount(for: slide), 1)
    }

    /// Only a slide whose data controller opts in keeps outdated data on a failed rebuild. An older
    /// niche interest slide cannot decode, so it is deleted even when the new one cannot be built.
    func testOutdatedNicheInterestSlideIsDeletedWhenItsRebuildFails() async throws {
        // The categories data controller reads the store from the environment. With no store there,
        // its rebuild fails. The report itself uses its own store.
        let report = try await fixture.withConfiguredEnvironment(configure: {
            WMFDataEnvironment.current.coreDataStore = nil
        }) {
            XCTAssertNil(WMFDataEnvironment.current.coreDataStore)
            let dataController = try WMFMockYearInReviewDataController(coreDataStore: try await fixture.makeTemporaryCoreDataStore())

            let legacyData = try JSONEncoder().encode(["Cats", "Dogs"])
            try await dataController.saveYearInReviewReport(WMFYearInReviewReport(year: year, slides: [
                WMFYearInReviewSlide(year: year, id: .mostReadCategories, data: legacyData)
            ]))

            return try await dataController.populateYearInReviewReportData(for: year, countryCode: countryCode, primaryAppLanguageProject: enProject, username: username, userID: nil, globalUserID: nil, savedSlideDataDelegate: self, legacyPageViewsDataDelegate: self)
        }

        XCTAssertNil(report?.slides.first { $0.id == .mostReadCategories }, "the old niche interest slide is deleted, not kept")
    }

    func testOnlyReadCountKeepsOutdatedDataOnFailedRebuild() {
        let slideIDs: [WMFYearInReviewPersonalizedSlideID] = [.readCount, .editCount, .donateCount, .saveCount, .mostReadDate, .viewCount, .topArticles, .mostReadCategories, .location, .topTopics, .daysVisited, .rabbitHoles]
        for slideID in slideIDs {
            XCTAssertEqual(slideID.dataController().keepsOutdatedDataOnFailedRebuild, slideID == .readCount, "\(slideID)")
        }
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
    private func populateReport(withNicheInterestData data: Data) async throws -> WMFYearInReviewReport? {
        // The categories data controller reads the store from the environment. The fixture changes
        // the environment under the global test lock, then restores it. The store is made here,
        // because taking the lock removes the stores that the fixture made in setUp.
        return try await fixture.withConfiguredEnvironment(configure: {
            WMFDataEnvironment.current.coreDataStore = try await fixture.makeTemporaryCoreDataStore()
        }) {
            let store = try XCTUnwrap(WMFDataEnvironment.current.coreDataStore)
            let dataController = try WMFMockYearInReviewDataController(coreDataStore: store)

            let slide = WMFYearInReviewSlide(year: year, id: .mostReadCategories, data: data)
            try await dataController.saveYearInReviewReport(WMFYearInReviewReport(year: year, slides: [slide]))

            return try await dataController.populateYearInReviewReportData(for: year, countryCode: countryCode, primaryAppLanguageProject: enProject, username: nil, userID: nil, globalUserID: nil, savedSlideDataDelegate: self, legacyPageViewsDataDelegate: self)
        }
    }

    /// An older build stored the niche interest slide as an array of category names.
    /// The slide is frozen, but the report must build it again in the current format.
    func testLegacyNicheInterestSlideIsBuiltAgain() async throws {
        let legacyData = try JSONEncoder().encode(["Cats", "Dogs"])

        let report = try await populateReport(withNicheInterestData: legacyData)

        let slides = report?.slides.filter { $0.id == .mostReadCategories } ?? []
        XCTAssertEqual(slides.count, 1, "The legacy slide is replaced, not kept next to the new slide")
        let data = try XCTUnwrap(slides.first?.data)
        XCTAssertNoThrow(try JSONDecoder().decode(WMFYearInReviewNicheCategorySlideData.self, from: data))
    }

    /// A slide in the current format keeps its category. No categories are in the store, so a
    /// new pick would have no category.
    func testCurrentNicheInterestSlideKeepsItsCategory() async throws {
        let storedData = try JSONEncoder().encode(WMFYearInReviewNicheCategorySlideData(categoryName: "Executed female serial killers"))

        let report = try await populateReport(withNicheInterestData: storedData)

        let slides = report?.slides.filter { $0.id == .mostReadCategories } ?? []
        XCTAssertEqual(slides.count, 1)
        let data = try XCTUnwrap(slides.first?.data)
        let payload = try JSONDecoder().decode(WMFYearInReviewNicheCategorySlideData.self, from: data)
        XCTAssertEqual(payload.categoryName, "Executed female serial killers")
    }

    func testNicheInterestFormatCheck() throws {
        let legacyData = try JSONEncoder().encode(["Cats", "Dogs"])
        let currentData = try JSONEncoder().encode(WMFYearInReviewNicheCategorySlideData(categoryName: "Cats"))
        let currentDataWithoutCategory = try JSONEncoder().encode(WMFYearInReviewNicheCategorySlideData(categoryName: nil))

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
