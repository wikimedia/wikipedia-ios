import XCTest

final class AppOnboardingUITests: XCTestCase {

    func testOnboardingLightMode() throws {
        let app = XCUIApplication()
        XCUIDevice.shared.appearance = .light
        app.launch()

        XCTAssertTrue(app.otherElements["App Onboarding Introduction View"].waitForExistence(timeout: 5))
        
        let initialAttachment = XCTAttachment(screenshot: app.screenshot())
        initialAttachment.name = ScreenshotNames.initial.rawValue
        initialAttachment.lifetime = .keepAlways
        add(initialAttachment)

        app.buttons["App Onboarding Skip Button"].tap()

        XCTAssertTrue(app.otherElements["Explore View"].waitForExistence(timeout: 5))
        
        let exploreAttachment = XCTAttachment(screenshot: app.screenshot())
        exploreAttachment.name = ScreenshotNames.explore.rawValue
        exploreAttachment.lifetime = .keepAlways
        add(exploreAttachment)
    }

    func testOnboardingDarkMode() throws {
        let app = XCUIApplication()
        XCUIDevice.shared.appearance = .dark
        app.launch()

        XCTAssertTrue(app.otherElements["App Onboarding Introduction View"].waitForExistence(timeout: 5))
        
        let initialAttachment = XCTAttachment(screenshot: app.screenshot())
        initialAttachment.name = ScreenshotNames.initial.rawValue
        initialAttachment.lifetime = .keepAlways
        add(initialAttachment)

        app.buttons["App Onboarding Skip Button"].tap()

        XCTAssertTrue(app.otherElements["Explore View"].waitForExistence(timeout: 5))
        let exploreAttachment = XCTAttachment(screenshot: app.screenshot())
        exploreAttachment.name = ScreenshotNames.explore.rawValue
        exploreAttachment.lifetime = .keepAlways
        add(exploreAttachment)
    }
}

private enum ScreenshotNames: String {
    case initial = "App Onboarding Initial"
    case explore = "App Onboarding Explore"
}
