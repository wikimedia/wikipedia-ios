import XCTest
@testable import WMFData

final class WMFYearInReviewTopicIllustrationTests: XCTestCase {

    /// The expected URLs come from the Commons API (imageinfo url) for these files.
    func testCommonsUploadURLUsesTheHashedPath() {
        XCTAssertEqual(URL.commonsUploadURL(fileName: "09 Sports.png")?.absoluteString, "https://upload.wikimedia.org/wikipedia/commons/1/1b/09_Sports.png")
        XCTAssertEqual(URL.commonsUploadURL(fileName: "33 - 39 Regional.png")?.absoluteString, "https://upload.wikimedia.org/wikipedia/commons/4/49/33_-_39_Regional.png")
        XCTAssertEqual(URL.commonsUploadURL(fileName: "01 Architecture.png")?.absoluteString, "https://upload.wikimedia.org/wikipedia/commons/d/d4/01_Architecture.png")
    }

    func testAllRegionsUseTheRegionalIllustration() {
        let regions: [WMFArticleTopic] = [.africa, .asia, .centralAmerica, .europe, .northAmerica, .oceania, .southAmerica]
        XCTAssertEqual(Set(regions.map(\.yearInReviewIllustrationFileName)), ["33 - 39 Regional.png"])
    }

    func testEachOtherTopicHasItsOwnIllustration() {
        let regions: Set<WMFArticleTopic> = [.africa, .asia, .centralAmerica, .europe, .northAmerica, .oceania, .southAmerica]
        let others = WMFArticleTopic.allCases.filter { !regions.contains($0) }
        XCTAssertEqual(Set(others.map(\.yearInReviewIllustrationFileName)).count, others.count)
    }
}
