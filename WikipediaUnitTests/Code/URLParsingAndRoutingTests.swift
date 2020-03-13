import XCTest
@testable import WMF

class URLParsingAndRoutingTests: XCTestCase {
    let configuration = Configuration.current
    let router = Configuration.current.router
    
    func testWikiResourcePath() {
        XCTAssertEqual("/wiki//æ/_raising".wikiResourcePath, "/æ/_raising")
        XCTAssertNil("/w//æ/_raising".wikiResourcePath)
        XCTAssertEqual("/wiki/อักษรละติน".wikiResourcePath, "อักษรละติน")
    }
    
    func testWResourcePath() {
        XCTAssertEqual("/w/index.php?title=/æ/_raising&oldid=905679984".wResourcePath, "index.php?title=/æ/_raising&oldid=905679984")
    }
    
    func testNamespace() {
        XCTAssertEqual("The_Clash:_Westway_to_the_World".namespaceOfWikiResourcePath(with: "en"), .main)
        XCTAssertEqual("The_Clash:_Westway_to_the_World".namespaceAndTitleOfWikiResourcePath(with: "en").title,  "The_Clash:_Westway_to_the_World")
    }
    
    func testMainPage() {
        let enMainPageURL = URL(string: "https://en.m.wikipedia.org/wiki/Main_Page")!
        let dest = router.destination(for: enMainPageURL)
        switch dest {
        case .inAppLink(let linkURL):
            XCTAssertEqual(linkURL, enMainPageURL.canonical)
        default:
            XCTAssertTrue(false)
        }
    }
    
    func testWikiResourcePathActivity() {
        guard var components = URLComponents(string: "//en.wikipedia.org/wiki/User_talk:Pink_Bull") else {
            XCTAssertTrue(false)
            return
        }
        
        var dest = router.destination(for: components.url!)
        switch dest {
        case .userTalk(let linkURL):
            XCTAssertEqual(linkURL, components.url!.canonical)
        default:
            XCTAssertTrue(false)
        }

        components.path = "/wiki//æ/_raising"
        dest = router.destination(for: components.url!)
        switch dest {
        case .article(let linkURL):
            XCTAssertEqual(linkURL, components.url!.canonical)
        default:
            XCTAssertTrue(false)
        }
        
        components.host = "fr.m.wikipedia.org"
        components.path = "/wiki/France"
        dest = router.destination(for: components.url!)
        switch dest {
        case .article(let linkURL):
            XCTAssertEqual(linkURL, components.url!.canonical)
        default:
            XCTAssertTrue(false)
        }
        
        // Special should work on frwiki because it's a canonical namespace
        components.path = "/wiki/Special:MobileDiff/24601"
        dest = router.destination(for: components.url!)
        switch dest {
        case .articleDiffSingle(let linkURL, _, let toRevID):
            XCTAssertEqual(linkURL, components.url!.canonical)
            XCTAssertEqual(toRevID, 24601)
        default:
            XCTAssertTrue(false)
        }
        
        components.host = "zh.m.wikipedia.org"
        components.path = "/wiki/特殊:MobileDiff/24601"
        dest = router.destination(for: components.url!)
        switch dest {
        case .articleDiffSingle(let linkURL, _, let toRevID):
            XCTAssertEqual(linkURL, components.url!.canonical)
            XCTAssertEqual(toRevID, 24601)
        default:
            XCTAssertTrue(false)
        }
    }
    
}
