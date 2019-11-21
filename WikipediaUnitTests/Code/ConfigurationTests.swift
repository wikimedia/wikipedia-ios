import XCTest
@testable import WMF

class ConfigurationTests: XCTestCase {
    let configuration = Configuration.current
    let router = Configuration.current.router
    
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
        
        var dest = try? router.destination(for: components.url!)
        switch dest {
        case .userTalk(let linkURL):
            XCTAssertEqual(linkURL, components.url!.canonical)
        default:
            XCTAssertTrue(false)
        }

        components.path = "/wiki//æ/_raising"
        dest = try? router.destination(for: components.url!)
        switch dest {
        case .article(let linkURL):
            XCTAssertEqual(linkURL, components.url!.canonical)
        default:
            XCTAssertTrue(false)
        }
        
        components.host = "fr.m.wikipedia.org"
        components.path = "/wiki/France"
        dest = try? router.destination(for: components.url!)
        switch dest {
        case .article(let linkURL):
            XCTAssertEqual(linkURL, components.url!.canonical)
        default:
            XCTAssertTrue(false)
        }
        
        // Special should work on frwiki because it's a canonical namespace
        components.path = "/wiki/Special:MobileDiff/24601"
        dest = try? router.destination(for: components.url!)
        switch dest {
        case .articleDiff(let linkURL, let rev):
            XCTAssertEqual(linkURL, components.url!.canonical)
            XCTAssertEqual(rev, "24601")
        default:
            XCTAssertTrue(false)
        }
    }
    
}
