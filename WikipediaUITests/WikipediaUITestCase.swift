//
//  WikipediaUITests.swift
//  WikipediaUITests
//
//  Created by Xue Qin on 10/19/17.
//  Copyright © 2017 Wikimedia Foundation. All rights reserved.
//

import XCTest

class WikipediaUITestCase: XCTestCase {
    
    let app = XCUIApplication()
    let today = "Monday, February 26"
    let yesterday = "Sunday, February 25"
    
    override func setUp() {
        super.setUp()
        app.launchEnvironment = ["UITEST_DISABLE_ANIMATIONS" : "YES"]
        continueAfterFailure = false
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        app.terminate()
    }
    
    func launch() {
        app.launch()
        sleep(3)
        if app.buttons["GET STARTED"].exists {
            welcomeTest()
        }
        if app.navigationBars["Wikipedia, return to Explore"].buttons.matching(identifier: "Back").element(boundBy: 0).exists {
            app.navigationBars["Wikipedia, return to Explore"].buttons.matching(identifier: "Back").element(boundBy: 0).tap()
        }
        if app.navigationBars["W"].buttons["Places"].exists {
            app.navigationBars["W"].buttons["Places"].tap()
            sleep(2)
            app.tabBars.buttons["Explore"].tap()
        }
        
    }
    
    func launchWithReset() {
        app.launchArguments = ["--Reset", "--IncreaseLayerSpeed"]
        app.launch()
    }
    
    func welcomeTest() {
        
        app.buttons["GET STARTED"].tap()
        let tablesQuery = app.tables
        
        tablesQuery.buttons["Add another language"].tap()
        tablesQuery.cells.staticTexts["Old English"].tap()
        app.buttons["CONTINUE"].tap()
        
        app.switches["Send usage reports"].tap()
        app.buttons["DONE"].tap()
        
        app.collectionViews.cells.buttons["Dismiss"].tap()
        
        app.tabBars.buttons["Places"].tap()
        app.buttons["Enable location"].tap()
        sleep(5)
        if app.alerts["Allow “Wikipedia” to access your location while you use the app?"].exists {
            app.alerts["Allow “Wikipedia” to access your location while you use the app?"].buttons["Allow"].tap()
        }
        
        app.tabBars.buttons["Explore"].tap()
        let todayElement = app.collectionViews.otherElements["Picture of the day " + today]
        scrollToElement(element: todayElement)
        todayElement.tap()
        
        let shareButton = app.navigationBars.buttons["share"]
        shareButton.tap()
        let collectionViewsQuery = app.otherElements["ActivityListView"].collectionViews.cells.collectionViews
        
        // Save Image
        collectionViewsQuery.buttons["Save Image"].tap()
        sleep(5)
        if app.alerts["“Wikipedia” Would Like to Access Your Photos"].exists {
            app.alerts["“Wikipedia” Would Like to Access Your Photos"].buttons["OK"].tap()
        }
        
        // jump to home page
        app.navigationBars.buttons["close"].tap()
        
        // login
        app.navigationBars["Explore"].buttons["settings"].tap()
        app.tables.cells.staticTexts.matching(identifier: "Log in").element(boundBy: 0).tap()
        
        let elementsQuery = app.scrollViews.otherElements
        let enterUsernameTextField = elementsQuery.textFields["enter username"]
        let enterPasswordTextField = elementsQuery.secureTextFields["enter password"]
        
        enterUsernameTextField.typeText("guileak")
        app.buttons["Next"].tap()
        
        enterPasswordTextField.typeText("utsa")
        enterPasswordTextField.typeText("123456")
        if elementsQuery.buttons["Log in"].isEnabled {
            elementsQuery.buttons["Log in"].tap()
        }
        sleep(4)
        app.navigationBars["Settings"].buttons["Close"].tap()
    }
    
    /**
     Scrolls to a particular element until it is rendered in the visible rect
     - Parameter elememt: the element we want to scroll to
     */
    func scrollToElement(element: XCUIElement)
    {
        while element.exists == false
        {
            let collectionViewsQuery = app.collectionViews
            if collectionViewsQuery.cells.buttons["Turn on notifications"].exists {
                collectionViewsQuery.cells.buttons["Turn on notifications"].tap()
                app.alerts["“Wikipedia” Would Like to Send You Notifications"].buttons["Allow"].tap()
            }
            if collectionViewsQuery.cells.buttons["Enable location"].exists {
                collectionViewsQuery.cells.buttons["Enable location"].tap()
                app.alerts["Allow “Wikipedia” to access your location while you use the app?"].buttons["Allow"].tap()
            }
            app.swipeUp()
        }
    }
    
    func logout() {
        if app.tables.cells.staticTexts.matching(identifier: "Logged in as Guileak").element(boundBy: 0).exists {
            app.tables.cells.staticTexts.matching(identifier: "Logged in as Guileak").element(boundBy: 0).tap()
            app.alerts["Are you sure you want to log out?"].buttons["Log out"].tap()
        }
    }
    /*
    func waitForElementToAppear(_ element: XCUIElement, file: String = #file, line: UInt = #line) {
        let existsPredicate = NSPredicate(format: "exists == true")
        expectation(for: existsPredicate, evaluatedWith: element, handler: nil)
        
        waitForExpectations(timeout: 5) { (error) -> Void in
            if (error != nil) {
                let message = "Failed to find \(element) after 5 seconds."
                self.recordFailure(withDescription: message, inFile: file, atLine: line, expected: true)
            }
        }
    }
 */

    
    
}
