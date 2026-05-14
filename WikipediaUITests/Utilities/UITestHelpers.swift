import Foundation
import XCTest

extension XCTestCase {
    func launchWikipediaApp(
        onboardingState: UITestConfiguration.OnboardingState,
        resetsPreferredLanguages: Bool = true
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.configureForUITestLaunch(configuration: .init(
            onboardingState: onboardingState,
            resetsPreferredLanguages: resetsPreferredLanguages
        ))
        app.launch()
        return app
    }
    
    func tapButton(withIdentifier identifier: String, in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons.matching(identifier: identifier).firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 5), file: file, line: line)
        button.tap()
    }
    
    func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval = 5, file: StaticString = #filePath, line: UInt = #line) {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = expectation(for: predicate, evaluatedWith: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, file: file, line: line)
    }
    
    func captureScreenshot(named name: String, in app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
