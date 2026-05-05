import Foundation
import XCTest

final class AppOnboardingUITests: XCTestCase {

    func testFirstLaunchShowsOnboardingSmoke() throws {
        let app = XCUIApplication()
        app.configureForUITestLaunch(configuration: .init(onboardingState: .notCompleted))
        app.launch()

        XCTAssertTrue(app.otherElements["App Onboarding Introduction View"].waitForExistence(timeout: 10))
    }

    func testOnboardingScreenshots() throws {
        let app = XCUIApplication()
        app.configureForUITestLaunch(configuration: .init(onboardingState: .notCompleted))
        app.launch()

        XCTAssertTrue(app.otherElements["App Onboarding Introduction View"].waitForExistence(timeout: 5))
        
        let initialAttachment = XCTAttachment(screenshot: app.screenshot())
        initialAttachment.name = ScreenshotNames.initial.rawValue
        initialAttachment.lifetime = .keepAlways
        add(initialAttachment)

        app.buttons["App Onboarding Skip Button"].tap()

        let exploreView = app.otherElements["Explore View"]
        XCTAssertTrue(exploreView.waitForExistence(timeout: 5))

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
