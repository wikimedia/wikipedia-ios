import XCTest
@testable import WMF

class ConfigurationTests: XCTestCase {
    let configuration = Configuration.current
    func testWikiResourcePath() {
        XCTAssertEqual(configuration.wikiResourcePath("/wiki//æ/_raising"), "/æ/_raising")
        XCTAssertNil(configuration.wikiResourcePath("/w//æ/_raising"))
    }
    
    func testWResourcePath() {
        XCTAssertEqual(configuration.wResourcePath("/w/index.php?title=/æ/_raising&oldid=905679984"), "index.php?title=/æ/_raising&oldid=905679984")
    }
    
    func testWikiResourcePathActivity() {
        XCTAssertEqual(configuration.activityTypeForWikiResourcePath("User_talk:Pink_Bull", with: "en"), .userTalk)
        XCTAssertEqual(configuration.activityTypeForWikiResourcePath("/æ/_raising", with: "en"), .article)
    }
}
