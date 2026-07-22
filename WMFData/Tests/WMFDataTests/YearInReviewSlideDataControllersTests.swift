import XCTest
import WMFDataTestSupport
@testable import WMFData
@testable import WMFDataMocks

/// Covers the contracts shared across the Year in Review slide data controllers.
/// These controllers are near-identical, so the per-slide constants (id binding,
/// personalized-network-data flag, freeze flag) and the `shouldPopulate` branching
/// are the behavior worth pinning down against copy-paste drift.
final class YearInReviewSlideDataControllersTests: XCTestCase {

    private let year = 2025

    private let enProject = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    private let fixture = WMFDataTestFixture()

    override func setUp() async throws {
        try await super.setUp()
        await fixture.setUp()
        // Fresh mock stores so WMFDeveloperSettingsDataController.shared state is deterministic.
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.sharedCacheStore = WMFMockKeyValueStore()
        await fixture.resetWMFDataTestState()
    }

    override func tearDown() async throws {
        await fixture.tearDown()
        try await super.tearDown()
    }

    private func makeDependencies(username: String? = nil, userID: Int? = nil) -> YearInReviewSlideDataControllerDependencies {
        YearInReviewSlideDataControllerDependencies(
            legacyPageViewsDataDelegate: nil,
            savedSlideDataDelegate: nil,
            username: username,
            project: enProject,
            userID: userID,
            globalUserID: nil,
            languageCode: "en"
        )
    }

    private func userInfo(username: String? = nil, userID: Int? = nil) -> YearInReviewUserInfo {
        YearInReviewUserInfo(username: username, userID: userID, globalUserID: nil, project: enProject)
    }

    // MARK: - Identity

    func testSlideIdentifiersMatchExpectedSlideIDs() {
        let deps = makeDependencies()
        let config = WMFFeatureConfigResponse.Common.YearInReview.testConfig

        XCTAssertEqual(YearInReviewReadCountSlideDataController(year: year, yirConfig: config, dependencies: deps).id, WMFYearInReviewPersonalizedSlideID.readCount.rawValue)
        XCTAssertEqual(YearInReviewEditCountSlideDataController(year: year, yirConfig: config, dependencies: deps).id, WMFYearInReviewPersonalizedSlideID.editCount.rawValue)
        XCTAssertEqual(YearInReviewDonateCountSlideDataController(year: year, yirConfig: config, dependencies: deps).id, WMFYearInReviewPersonalizedSlideID.donateCount.rawValue)
        XCTAssertEqual(YearInReviewSaveCountSlideDataController(year: year, yirConfig: config, dependencies: deps).id, WMFYearInReviewPersonalizedSlideID.saveCount.rawValue)
        XCTAssertEqual(YearInReviewMostReadDateSlideDataController(year: year, yirConfig: config, dependencies: deps).id, WMFYearInReviewPersonalizedSlideID.mostReadDate.rawValue)
        XCTAssertEqual(YearInReviewViewCountSlideDataController(year: year, yirConfig: config, dependencies: deps).id, WMFYearInReviewPersonalizedSlideID.viewCount.rawValue)
        XCTAssertEqual(YearInReviewTopReadArticleSlideDataController(year: year, yirConfig: config, dependencies: deps).id, WMFYearInReviewPersonalizedSlideID.topArticles.rawValue)
        XCTAssertEqual(YearInReviewMostReadCategoriesSlideDataController(year: year, yirConfig: config, dependencies: deps).id, WMFYearInReviewPersonalizedSlideID.mostReadCategories.rawValue)
        XCTAssertEqual(YearInReviewLocationSlideDataController(year: year, yirConfig: config, dependencies: deps).id, WMFYearInReviewPersonalizedSlideID.location.rawValue)
    }

    func testSlideYearIsRetained() {
        let controller = YearInReviewReadCountSlideDataController(year: year, yirConfig: .testConfig, dependencies: makeDependencies())
        XCTAssertEqual(controller.year, year)
    }

    // MARK: - Flags

    func testContainsPersonalizedNetworkDataFlags() {
        // Slides backed by personalized network data are cleared on logout.
        XCTAssertTrue(YearInReviewSaveCountSlideDataController.containsPersonalizedNetworkData)
        XCTAssertTrue(YearInReviewViewCountSlideDataController.containsPersonalizedNetworkData)
        XCTAssertTrue(YearInReviewEditCountSlideDataController.containsPersonalizedNetworkData)

        XCTAssertFalse(YearInReviewReadCountSlideDataController.containsPersonalizedNetworkData)
        XCTAssertFalse(YearInReviewDonateCountSlideDataController.containsPersonalizedNetworkData)
        XCTAssertFalse(YearInReviewMostReadDateSlideDataController.containsPersonalizedNetworkData)
        XCTAssertFalse(YearInReviewMostReadCategoriesSlideDataController.containsPersonalizedNetworkData)
        XCTAssertFalse(YearInReviewLocationSlideDataController.containsPersonalizedNetworkData)
        XCTAssertFalse(YearInReviewTopReadArticleSlideDataController.containsPersonalizedNetworkData)
    }

    func testShouldFreezeFlags() {
        XCTAssertFalse(YearInReviewDonateCountSlideDataController.shouldFreeze)
        XCTAssertFalse(YearInReviewViewCountSlideDataController.shouldFreeze)
        XCTAssertFalse(YearInReviewEditCountSlideDataController.shouldFreeze)

        XCTAssertTrue(YearInReviewReadCountSlideDataController.shouldFreeze)
        XCTAssertTrue(YearInReviewSaveCountSlideDataController.shouldFreeze)
        XCTAssertTrue(YearInReviewMostReadDateSlideDataController.shouldFreeze)
        XCTAssertTrue(YearInReviewMostReadCategoriesSlideDataController.shouldFreeze)
        XCTAssertTrue(YearInReviewLocationSlideDataController.shouldFreeze)
        XCTAssertTrue(YearInReviewTopReadArticleSlideDataController.shouldFreeze)
    }

    // MARK: - shouldPopulate

    func testConfigOnlySlidesPopulateWhenActiveRegardlessOfUser() {
        // testConfig is active for the current date, and these slides depend only on that.
        let config = WMFFeatureConfigResponse.Common.YearInReview.testConfig
        let anonymous = userInfo()

        XCTAssertTrue(YearInReviewReadCountSlideDataController.shouldPopulate(from: config, userInfo: anonymous))
        XCTAssertTrue(YearInReviewDonateCountSlideDataController.shouldPopulate(from: config, userInfo: anonymous))
        XCTAssertTrue(YearInReviewSaveCountSlideDataController.shouldPopulate(from: config, userInfo: anonymous))
        XCTAssertTrue(YearInReviewMostReadDateSlideDataController.shouldPopulate(from: config, userInfo: anonymous))
        XCTAssertTrue(YearInReviewMostReadCategoriesSlideDataController.shouldPopulate(from: config, userInfo: anonymous))
        XCTAssertTrue(YearInReviewLocationSlideDataController.shouldPopulate(from: config, userInfo: anonymous))
        XCTAssertTrue(YearInReviewTopReadArticleSlideDataController.shouldPopulate(from: config, userInfo: anonymous))
    }

    func testViewCountSlideRequiresUserID() {
        let config = WMFFeatureConfigResponse.Common.YearInReview.testConfig

        XCTAssertTrue(YearInReviewViewCountSlideDataController.shouldPopulate(from: config, userInfo: userInfo(userID: 42)))
        // A username without a userID is not enough.
        XCTAssertFalse(YearInReviewViewCountSlideDataController.shouldPopulate(from: config, userInfo: userInfo(username: "user", userID: nil)))
    }

    func testEditCountSlideRequiresUsername() {
        let config = WMFFeatureConfigResponse.Common.YearInReview.testConfig

        XCTAssertTrue(YearInReviewEditCountSlideDataController.shouldPopulate(from: config, userInfo: userInfo(username: "user")))
        // A userID without a username is not enough.
        XCTAssertFalse(YearInReviewEditCountSlideDataController.shouldPopulate(from: config, userInfo: userInfo(username: nil, userID: 42)))
    }
}
