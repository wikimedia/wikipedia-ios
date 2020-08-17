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
    
    func testTitlesWithForwardSlashes() {
        var url = URL(string: "https://en.wikipedia.org/wiki/G/O_Media")!
        XCTAssertEqual(url.resolvingRelativeWikiHref("./Gizmodo")?.absoluteString, "https://en.wikipedia.org/wiki/Gizmodo")
        url = URL(string: "https://en.wikipedia.org/wiki//dev/random")!
        XCTAssertEqual(url.resolvingRelativeWikiHref(".//dev/null")?.absoluteString, "https://en.wikipedia.org/wiki//dev/null")
    }
    
    /// Ensure the 'transcoded' path component is inserted after the language path component for audio hosted on Wikipedia
    func testWikipediaCompatibilityAdjustments() {
        let url = URL(string: "https://upload.wikimedia.org/wikipedia/en/3/3f/DeanScream.ogg")!
        let expected = URL(string: "https://upload.wikimedia.org/wikipedia/en/transcoded/3/3f/DeanScream.ogg/DeanScream.ogg.mp3")!
        XCTAssertEqual(url.byMakingAudioFileCompatibilityAdjustments, expected)
    }
    
    /// Ensure the 'transcoded' path component is inserted after the 'commons' path component for audio hosted on Commons
    func testCommonsCompatibilityAdjustments() {
        let url = URL(string: "https://upload.wikimedia.org/wikipedia/commons/8/8a/En-Paprika_%28American%29.oga")!
        let expected = URL(string: "https://upload.wikimedia.org/wikipedia/commons/transcoded/8/8a/En-Paprika_(American).oga/En-Paprika_(American).oga.mp3")!
        XCTAssertEqual(url.byMakingAudioFileCompatibilityAdjustments, expected)
    }
    
    /// Ensure non audio and non-upload.wikimedia.org links aren't transcoded and don't break in unexpected ways
    func testInvalidCompatibilityAdjustment() {
        var url = URL(string: "https://upload.wikimedia.org/commons/3/3f/DeanScream.ogv")!
        XCTAssertFalse(url.isWikimediaHostedAudioFileLink)
        url = URL(string: "https://en.wikipedia.org/commons/3/3f/DeanScream.ogg")!
        XCTAssertFalse(url.isWikimediaHostedAudioFileLink)
    }
}
