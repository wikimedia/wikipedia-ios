import XCTest
import SnapshotTesting

final class AppOnboardingTests: XCTestCase {
    
    var updateScreenshots: Bool = false

    override func setUpWithError() throws {
        continueAfterFailure = updateScreenshots ? true : false
    }
    
    var screenshotNameSuffix: String {
        // note: not doing theme name here, since onboarding doesn't need to support our themes, only system light/dark mode.
        return "\(deviceLanguageCode)"
    }
    
    override func invokeTest() {
        let shouldRecord: SnapshotTestingConfiguration.Record =
        updateScreenshots ? .all : .missing
        withSnapshotTesting(record: shouldRecord) {
            super.invokeTest()
        }
    }

    func testOnboardingLightMode() throws {
        let app = XCUIApplication()
        XCUIDevice.shared.appearance = .light
        // Fix the status bar so clock/battery don't cause false failures
        app.launchArguments += ["-UIStatusBarShowingBatteryLevel", "0",
                                "-StatusBarOverrideTime", "10:00"]
        app.launch()

        XCTAssertTrue(app.isDisplayingIntroduction)

        // Snapshot the introduction screen
        assertSnapshot(of: app.screenshot().image,
                       as: .image(precision: 1.0),
                       named: "introduction-light-\(screenshotNameSuffix)")

        app.buttons["App Onboarding Skip Button"].tap()

        // XCTAssertTrue(app.isDisplayingExplore)
    }

    func testOnboardingDarkMode() throws {
        let app = XCUIApplication()
        XCUIDevice.shared.appearance = .dark
        app.launchArguments += ["-UIStatusBarShowingBatteryLevel", "0",
                                "-StatusBarOverrideTime", "10:00"]
        app.launch()

        XCTAssertTrue(app.isDisplayingIntroduction)

        assertSnapshot(of: app.screenshot().image,
                       as: .image(precision: 1.0),
                       named: "introduction-dark-\(screenshotNameSuffix)")

        app.buttons["App Onboarding Skip Button"].tap()

        // XCTAssertTrue(app.isDisplayingExplore)
    }
}

extension XCUIApplication {
    var isDisplayingIntroduction: Bool {
        otherElements["App Onboarding Introduction View"].exists
    }
    var isDisplayingExplore: Bool {
        otherElements["Explore View"].exists
    }
}
