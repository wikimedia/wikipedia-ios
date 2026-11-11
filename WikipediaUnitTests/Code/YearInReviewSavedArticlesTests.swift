import XCTest
import CoreData
@testable import WMF
import WMFData

/// The saved articles that the Year in Review saved slide stores, read from a temporary data store.
final class YearInReviewSavedArticlesTests: XCTestCase {

    private var dataStore: MWKDataStore!

    private let startDate = Date(timeIntervalSinceNow: -24 * 60 * 60)
    private let endDate = Date(timeIntervalSinceNow: 60 * 60)

    override func setUp(completion: @escaping (Error?) -> Void) {
        MWKDataStore.createTemporaryDataStore(completion: { dataStore in
            self.dataStore = dataStore
            completion(nil)
        })
    }

    override func tearDown() {
        dataStore.removeFolderAtBasePath()
        dataStore = nil
        super.tearDown()
    }

    @MainActor
    func testAnArticleWithoutADisplayTitleIsCountedAndListedWithItsURLTitle() throws {
        let article = try saveArticle(titled: "Hello_world", displayTitle: nil)
        XCTAssertNil(article.displayTitle, "an article synced from a reading list has no display title yet")

        let slideData = try XCTUnwrap(dataStore.savedPageList.savedArticleSlideData(from: startDate, to: endDate, count: 3))

        XCTAssertEqual(slideData.savedArticlesCount, 1)
        XCTAssertEqual(slideData.articles?.map(\.title), ["Hello world"])
        XCTAssertEqual(slideData.articles?.first?.pageTitle, "Hello world")
        XCTAssertTrue(slideData.isEligible, "the count and the list agree, so the slide does not say 0 saved")
    }

    @MainActor
    func testTheDisplayTitleIsShownWhenThereIsOne() throws {
        try saveArticle(titled: "IPhone", displayTitle: "iPhone")

        let slideData = try XCTUnwrap(dataStore.savedPageList.savedArticleSlideData(from: startDate, to: endDate, count: 3))

        XCTAssertEqual(slideData.articles?.first?.title, "iPhone")
        XCTAssertEqual(slideData.articles?.first?.pageTitle, "IPhone")
    }

    @MainActor
    func testTheListHasAtMostTheCountButTheTotalCountsEveryArticle() throws {
        for title in ["A", "B", "C", "D", "E"] {
            try saveArticle(titled: title, displayTitle: title)
        }

        let slideData = try XCTUnwrap(dataStore.savedPageList.savedArticleSlideData(from: startDate, to: endDate, count: 3))

        XCTAssertEqual(slideData.savedArticlesCount, 5)
        let titles = try XCTUnwrap(slideData.articles?.map(\.title))
        XCTAssertEqual(titles.count, 3)
        XCTAssertEqual(Set(titles).count, 3, "each article is picked once")
        XCTAssertTrue(Set(titles).isSubset(of: ["A", "B", "C", "D", "E"]))
    }

    @MainActor
    func testArticlesSavedOutsideTheDataPeriodAreLeftOut() throws {
        try saveArticle(titled: "Inside", displayTitle: "Inside")
        try saveArticle(titled: "Before", displayTitle: "Before", savedDate: startDate.addingTimeInterval(-60))

        let slideData = try XCTUnwrap(dataStore.savedPageList.savedArticleSlideData(from: startDate, to: endDate, count: 3))

        XCTAssertEqual(slideData.savedArticlesCount, 1)
        XCTAssertEqual(slideData.articles?.map(\.title), ["Inside"])
    }

    @MainActor
    func testNoSavedArticlesGiveAnEmptyListNotAFailure() throws {
        let slideData = try XCTUnwrap(dataStore.savedPageList.savedArticleSlideData(from: startDate, to: endDate, count: 3))

        XCTAssertEqual(slideData.savedArticlesCount, 0)
        XCTAssertEqual(slideData.articles, [])
        XCTAssertFalse(slideData.isEligible)
    }

    @MainActor
    func testTheLanguageVariantIsPartOfTheProject() throws {
        var url = try XCTUnwrap(URL(string: "https://zh.wikipedia.org/wiki/%E7%8C%AB"))
        url.wmf_languageVariantCode = "zh-hans"
        try saveArticle(url: url, displayTitle: "猫")

        let slideData = try XCTUnwrap(dataStore.savedPageList.savedArticleSlideData(from: startDate, to: endDate, count: 3))

        let expectedProject = WMFProject.wikipedia(WMFLanguage(languageCode: "zh", languageVariantCode: "zh-hans"))
        XCTAssertEqual(slideData.articles?.first?.projectID, expectedProject.id)
        XCTAssertEqual(slideData.articles?.first?.project, expectedProject)
    }

    // MARK: - Helpers

    @discardableResult
    private func saveArticle(titled title: String, displayTitle: String?, savedDate: Date = Date(timeIntervalSinceNow: -60)) throws -> WMFArticle {
        let url = try XCTUnwrap(URL(string: "https://en.wikipedia.org/wiki/\(title)"))
        return try saveArticle(url: url, displayTitle: displayTitle, savedDate: savedDate)
    }

    @discardableResult
    private func saveArticle(url: URL, displayTitle: String?, savedDate: Date = Date(timeIntervalSinceNow: -60)) throws -> WMFArticle {
        let article = try XCTUnwrap(dataStore.fetchOrCreateArticle(with: url))
        if let displayTitle {
            article.displayTitleHTML = displayTitle
        }
        dataStore.savedPageList.addSavedPage(with: url)
        article.savedDate = savedDate
        try dataStore.viewContext.save()
        return article
    }
}
