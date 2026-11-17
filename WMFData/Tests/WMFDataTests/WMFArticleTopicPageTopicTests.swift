import XCTest
@testable import WMFData

final class WMFArticleTopicPageTopicTests: XCTestCase {

    func testLabelsAsThePageContentServiceSendsThem() {
        // Real labels from the Page Content Service: underscores, and "*" on parent topics.
        XCTAssertEqual(WMFArticleTopic(pageTopicLabel: "History_and_Society.Military_and_warfare"), .militaryAndWarfare)
        XCTAssertEqual(WMFArticleTopic(pageTopicLabel: "History_and_Society.History"), .history)
        XCTAssertEqual(WMFArticleTopic(pageTopicLabel: "Culture.Biography.Biography*"), .biography)
        XCTAssertEqual(WMFArticleTopic(pageTopicLabel: "Culture.Visual_arts.Visual_arts*"), .visualArts)
        XCTAssertEqual(WMFArticleTopic(pageTopicLabel: "Culture.Food_and_drink"), .foodAndDrink)
        XCTAssertEqual(WMFArticleTopic(pageTopicLabel: "STEM.STEM*"), .stem)
        XCTAssertEqual(WMFArticleTopic(pageTopicLabel: "STEM.Physics"), .physics)
    }

    func testLabelsWithSpaces() {
        XCTAssertEqual(WMFArticleTopic(pageTopicLabel: "STEM.Biology"), .biology)
        XCTAssertEqual(WMFArticleTopic(pageTopicLabel: "Culture.Internet culture"), .internetCulture)
        XCTAssertEqual(WMFArticleTopic(pageTopicLabel: "History and Society.History"), .history)
        XCTAssertEqual(WMFArticleTopic(pageTopicLabel: "STEM.Medicine & Health"), .medicineAndHealth)
    }

    func testLabelsThatGoToATopicWithTheSameDisplayName() {
        XCTAssertEqual(WMFArticleTopic(pageTopicLabel: "Culture.Media.Television"), .films)
        XCTAssertEqual(WMFArticleTopic(pageTopicLabel: "Culture.Literature"), .books)
        XCTAssertEqual(WMFArticleTopic(pageTopicLabel: "Culture.Media.Software"), .internetCulture)
        XCTAssertEqual(WMFArticleTopic(pageTopicLabel: "STEM.Computing"), .internetCulture)
        XCTAssertEqual(WMFArticleTopic(pageTopicLabel: "STEM.Earth_and_environment"), .geographical)
        XCTAssertEqual(WMFArticleTopic(pageTopicLabel: "Geography.Geographical"), .geographical)
    }

    func testRegionsAndSubregionsGoToTheirContinent() {
        XCTAssertEqual(WMFArticleTopic(pageTopicLabel: "Geography.Regions.Asia.Asia*"), .asia)
        XCTAssertEqual(WMFArticleTopic(pageTopicLabel: "Geography.Regions.Asia.East_Asia"), .asia)
        XCTAssertEqual(WMFArticleTopic(pageTopicLabel: "Geography.Regions.Europe.Western_Europe"), .europe)
        XCTAssertEqual(WMFArticleTopic(pageTopicLabel: "Geography.Regions.Africa.Western_Africa"), .africa)
        XCTAssertEqual(WMFArticleTopic(pageTopicLabel: "Geography.Regions.Americas.North_America"), .northAmerica)
        XCTAssertEqual(WMFArticleTopic(pageTopicLabel: "Geography.Regions.Americas.Central_America"), .centralAmerica)
        XCTAssertEqual(WMFArticleTopic(pageTopicLabel: "Geography.Regions.Americas.South_America"), .southAmerica)
        XCTAssertEqual(WMFArticleTopic(pageTopicLabel: "Geography.Regions.Oceania"), .oceania)
    }

    func testLabelsWithoutATopic() {
        XCTAssertNil(WMFArticleTopic(pageTopicLabel: "Culture.Media.Media*"))
        XCTAssertNil(WMFArticleTopic(pageTopicLabel: "Culture.Linguistics"))
        XCTAssertNil(WMFArticleTopic(pageTopicLabel: "STEM.Space"))
        XCTAssertNil(WMFArticleTopic(pageTopicLabel: ""))
        XCTAssertNil(WMFArticleTopic(pageTopicLabel: "Biology"), "a topic ID is not a label")
    }
}
