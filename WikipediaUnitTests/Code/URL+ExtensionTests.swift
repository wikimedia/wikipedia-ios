import XCTest

class URL_ExtensionTests: XCTestCase {

    func testOpenInSafari() throws {
        // Article
        XCTAssertFalse(URL(string: "http://en.wikipedia.org/wiki/Grinnell_College")!.doesOpenInBrowser)

        // User page
        XCTAssertTrue(URL(string: "https://en.wikipedia.org/wiki/User:Jimbo_Wales")!.doesOpenInBrowser)

        // User talk redirect
        XCTAssertFalse(URL(string: "https://en.wikipedia.org/wiki/User_talk:Jimbo")!.doesOpenInBrowser)

        // User talk
        XCTAssertFalse(URL(string: "https://en.wikipedia.org/wiki/User_talk:Jimbo_Wales")!.doesOpenInBrowser)

        // Article talk
        XCTAssertFalse(URL(string: "https://en.wikipedia.org/wiki/Talk:Jo_Ann_Hardesty")!.doesOpenInBrowser)

        // Article in Chinese
        XCTAssertFalse(URL(string: "https://zh.wikipedia.org/wiki/%E7%BE%8E%E5%9C%8B%E9%91%84%E5%B9%A3%E5%B1%80")!.doesOpenInBrowser)

        // Off wiki link
        XCTAssertTrue(URL(string: "http://www.eff.org")!.doesOpenInBrowser)
    }

}
