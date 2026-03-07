import XCTest

final class AppOnboardingTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testOnboardingLightMode() throws {
        let app = XCUIApplication()
        XCUIDevice.shared.appearance = .light
        // Not setting launch arguments (which pass in forced themes) so we can explicitly test system light mode and dark mode.
        // User shouldn't be able to see onboarding in sepia or dark themes, so need to test those
        // app.launchArguments += ProcessInfo().arguments
        app.launch()
        
        XCTAssertTrue(app.isDisplayingIntroduction)

        let introAttachment = XCTAttachment(screenshot: app.screenshot())
        introAttachment.name = ScreenshotNames.introduction.rawValue
        introAttachment.lifetime = .keepAlways
        add(introAttachment)
        
        let skipButton = app.buttons["App Onboarding Skip Button"]
        skipButton.tap()
        
        XCTAssertTrue(app.isDisplayingExplore)
    }
    
    func testOnboardingDarkMode() throws {
        let app = XCUIApplication()
        XCUIDevice.shared.appearance = .dark
        // Not setting launch arguments (which pass in forced themes) so we can explicitly test system light mode and dark mode.
        // User shouldn't be able to see onboarding in sepia or dark themes, so need to test those
        // app.launchArguments += ProcessInfo().arguments
        app.launch()
        
        XCTAssertTrue(app.isDisplayingIntroduction)

        let introAttachment = XCTAttachment(screenshot: app.screenshot())
        introAttachment.name = ScreenshotNames.introduction.rawValue
        introAttachment.lifetime = .keepAlways
        add(introAttachment)
        
        let skipButton = app.buttons["App Onboarding Skip Button"]
        skipButton.tap()
        
        XCTAssertTrue(app.isDisplayingExplore)
    }
}

extension XCUIApplication {
    var isDisplayingIntroduction: Bool {
        return otherElements["App Onboarding Introduction View"].exists
    }
    
    var isDisplayingExplore: Bool {
        return otherElements["Explore View"].exists
    }
}

private enum ScreenshotNames: String {
    case introduction = "App Onboarding Introduction View"
}
