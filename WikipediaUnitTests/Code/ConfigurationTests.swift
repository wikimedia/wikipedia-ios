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
        guard var components = URLComponents(string: "//en.wikipedia.org/wiki/User_talk:Pink_Bull") else {
            XCTAssertTrue(false)
            return
        }
        
        var info = configuration.activityInfoForWikiResourceURL(components.url!)
        XCTAssertEqual(info!.type, .userTalk)
        XCTAssertEqual(info!.title, "Pink_Bull")
        XCTAssertEqual(info!.language, "en")

        components.path = "/wiki//æ/_raising"
        info = configuration.activityInfoForWikiResourceURL(components.url!)
        XCTAssertEqual(info!.type, .article)
        XCTAssertEqual(info!.title, "/æ/_raising")
        XCTAssertEqual(info!.language, "en")
        
        components.host = "fr.m.wikipedia.org"
        components.path = "/wiki/France"
        info = configuration.activityInfoForWikiResourceURL(components.url!)
        XCTAssertEqual(info!.type, .article)
        XCTAssertEqual(info!.title, "France")
        XCTAssertEqual(info!.language, "fr")
        
        // Special should work on frwiki because it's a canonical namespace
        components.path = "/wiki/Special:MobileDiff/24601"
        info = configuration.activityInfoForWikiResourceURL(components.url!)
        XCTAssertEqual(info!.type, .articleDiff)
        XCTAssertEqual(info!.url, components.url!)
        XCTAssertEqual(info!.queryItems!.last, URLQueryItem(name: "oldid", value: "24601"))
    }
    
//    func testWResourcePathActivity() {
//        XCTAssertEqual(configuration.activityTypeForWResourcePath("index.php?title=Auguste_Rodin&action=history"), .articleHistory)
//        XCTAssertEqual(configuration.activityTypeForWResourcePath("index.php?title=Auguste_Rodin&type=revision&diff=925807777&oldid=925784505"), .diff)
//        XCTAssertNil(configuration.activityTypeForWResourcePath("index.php"))
//    }
}
