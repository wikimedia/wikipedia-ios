import XCTest

final class BrowserScreen {
    private lazy var browserSafari: XCUIApplication = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
    
    func checkBrowser() {
        XCTAssertTrue(browserSafari.label == "Safari")
    }
}

