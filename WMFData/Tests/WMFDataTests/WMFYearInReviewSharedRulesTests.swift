import XCTest
@testable import WMFData
@testable import WMFDataMocks
import CoreData

/// Covers the rules that all Year in Review 2026 slides share: the two date ranges, the active
/// window, the setting gate, and which stored slides each clear action deletes.
final class WMFYearInReviewSharedRulesTests: XCTestCase {

    private typealias YearInReview = WMFFeatureConfigResponse.Common.YearInReview

    private var store: WMFCoreDataStore!
    private var userDefaultsStore: WMFMockKeyValueStore!

    override func setUp() async throws {
        try await super.setUp()
        let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        store = try await WMFCoreDataStore(appContainerURL: temporaryDirectory)
        userDefaultsStore = WMFMockKeyValueStore()
    }

    private func date(_ string: String) -> Date {
        DateFormatter.mediaWikiAPIDateFormatter.date(from: string)!
    }

    private func makeConfig(activeStartDateString: String? = nil, activeEndDateString: String? = nil) -> YearInReview {
        let testConfig = YearInReview.testConfig
        return YearInReview(
            year: testConfig.year,
            activeStartDateString: activeStartDateString ?? testConfig.activeStartDateString,
            activeEndDateString: activeEndDateString ?? testConfig.activeEndDateString,
            dataStartDateString: testConfig.dataStartDateString,
            dataEndDateString: testConfig.dataEndDateString,
            languages: testConfig.languages,
            articles: testConfig.articles,
            savedArticlesApps: testConfig.savedArticlesApps,
            viewsApps: testConfig.viewsApps,
            editsApps: testConfig.editsApps,
            editsPerMinute: testConfig.editsPerMinute,
            averageArticlesReadPerYear: testConfig.averageArticlesReadPerYear,
            edits: testConfig.edits,
            editsEN: testConfig.editsEN,
            hoursReadEN: testConfig.hoursReadEN,
            yearsReadEN: testConfig.yearsReadEN,
            topReadEN: testConfig.topReadEN,
            topReadPercentages: testConfig.topReadPercentages,
            bytesAddedEN: testConfig.bytesAddedEN,
            hideCountryCodes: testConfig.hideCountryCodes,
            hideDonateCountryCodes: testConfig.hideDonateCountryCodes
        )
    }

    private func makeDataController(config: YearInReview = .testConfig) throws -> WMFYearInReviewDataController {
        let featureConfig = WMFFeatureConfigResponse(common: WMFFeatureConfigResponse.Common(yir: [config]), ios: WMFFeatureConfigResponse.IOS(hCaptcha: nil))
        let developerSettingsDataController = WMFMockDeveloperSettingsDataController(featureConfig: featureConfig)
        return try WMFYearInReviewDataController(coreDataStore: store, userDefaultsStore: userDefaultsStore, developerSettingsDataController: developerSettingsDataController)
    }

    // MARK: - Clearing data

    private let allSlideIDs: [WMFYearInReviewPersonalizedSlideID] = [.readCount, .editCount, .donateCount, .saveCount, .mostReadDate, .viewCount, .mostReadCategories, .location, .topArticles]

    private func storedSlideIDs(year: Int) async throws -> Set<WMFYearInReviewPersonalizedSlideID> {
        let store = try XCTUnwrap(store)
        return try await store.viewContext.perform {
            let slides = try store.fetch(entityType: CDYearInReviewSlide.self, predicate: NSPredicate(format: "year == %d", year), fetchLimit: nil, in: store.viewContext) ?? []
            return Set(slides.compactMap { $0.id.flatMap(WMFYearInReviewPersonalizedSlideID.init(rawValue:)) })
        }
    }

    private func saveAllSlides(dataController: WMFYearInReviewDataController, year: Int = 2026) async throws {
        let slides = allSlideIDs.map { WMFYearInReviewSlide(year: year, id: $0, data: nil) }
        try await dataController.createNewYearInReviewReport(year: year, slides: slides)
    }

    func testSavingOneYearsReportKeepsOtherYearsSlides() async throws {
        let dataController = try makeDataController()
        try await dataController.createNewYearInReviewReport(year: 2025, slides: [WMFYearInReviewSlide(year: 2025, id: .readCount, data: nil)])
        try await dataController.createNewYearInReviewReport(year: 2026, slides: [WMFYearInReviewSlide(year: 2026, id: .readCount, data: nil)])

        let remaining2025 = try await storedSlideIDs(year: 2025)
        let remaining2026 = try await storedSlideIDs(year: 2026)
        XCTAssertEqual(remaining2025, [.readCount])
        XCTAssertEqual(remaining2026, [.readCount])
    }
}
