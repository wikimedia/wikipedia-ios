import XCTest

class WikipediaUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        let app = XCUIApplication()
        app.launchArguments.append("-WMFAppReset")
        app.launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testTurnOnNotificationsVisibleOnInitialLaunch() {
        let app = XCUIApplication()
        app.buttons["GET STARTED"].tap()
        app.buttons["CONTINUE"].tap()
        app.buttons["DONE"].tap()
        let turnOnNotifications = app.collectionViews.buttons["Turn on notifications"]
        XCTAssert(turnOnNotifications.isHittable)
    }
    
}
