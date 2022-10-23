//
//  BaseTest.swift
//  WikipediaUITests
//
//  Created by Eugene Tkachenko on 22.10.2022.
//
import XCTest

class BaseTest: XCTestCase {
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    public var launchApp: HomeScreen {
        let app = XCUIApplication()
        app.launchArguments += ["-ui_testing"]
        app.launch()
        XCTAssertEqual(app.state, .runningForeground)
        
        skipOnboarding()
        
        return HomeScreen()
    }
    
    // TODO: Add launchArguments parameter for ability to show/hide Onboarding.
    // TODO: Add launchArguments parameter for app 'clean install' state
    private func skipOnboarding() {
        let skipButton =  XCUIApplication().windows.buttons["Skip"].firstMatch
        if skipButton.exists {
            skipButton.tap()
            waitForElement(skipButton, toExist: false)
        }
    }
}
