//
//  WikipediaUITests.swift
//  WikipediaUITests
//
//  Created by Bastien Cojan on 06/04/2017.
//  Copyright © 2017 Wikimedia Foundation. All rights reserved.
//

import XCTest

class WikipediaUITests: XCTestCase {
    var args: [String] = []
    let app = XCUIApplication()
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
//        let app = XCUIApplication()

//        app.launchArguments = [
//            "-inUITest",
//            "-AppleLanguages",
//            "(de)",
//            "-AppleLocale",
//            "de-DE"
//        ]

        
        setupSnapshot(app)
        
        args = app.launchArguments
        
        app.launch()
        print(app.launchArguments)

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    
    func enUS () {
//        let app = XCUIApplication()
        let existsPredicate = NSPredicate(format: "exists == true")
        
        if app.buttons["GET STARTED"].exists {
            app.buttons["GET STARTED"].tap()
            app.buttons["CONTINUE"].tap()
            app.buttons["DONE"].tap()
        }
        if app.alerts["Allow “Wikipedia” to access your location while you use the app?"].exists {
            app.alerts["Allow “Wikipedia” to access your location while you use the app?"].buttons["Allow"].tap()
        }
        
        if app.navigationBars["Wikipedia, return to Explore"].exists {
            app.navigationBars["Wikipedia, return to Explore"].buttons["Explore"].tap()
        }
        
        snapshot("Home page")
        
        app.navigationBars["Explore"].buttons["search"].tap()
        
        app.searchFields["Search Wikipedia"].typeText("steve jobs")
        
        
        snapshot("Search")
        
        let tablesQuery = app.tables
        
        let steveJobsLink = tablesQuery.links["Steve Jobs\nAmerican entrepreneur and co-founder of Apple Inc.\n"]
        expectation(for: existsPredicate, evaluatedWith: steveJobsLink, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
        
        let steveJobsElement = app.staticTexts["Steve Jobs"]
        
        expectation(for: existsPredicate, evaluatedWith: steveJobsElement, handler: nil)
        
        tablesQuery.links["Steve Jobs\nAmerican entrepreneur and co-founder of Apple Inc.\n"].tap()
        
        waitForExpectations(timeout: 5, handler: nil)
        
        
        
        snapshot("Steve Jobs Page")
    }
    
    func frFR () {
//        let app = XCUIApplication()
        let existsPredicate = NSPredicate(format: "exists == true")
        
        if app.buttons["COMMENCER"].exists {
            app.buttons["COMMENCER"].tap()
            app.buttons["CONTINUER"].tap()
            app.buttons["TERMINÉ"].tap()
        }
        if app.alerts["Allow “Wikipedia” to access your location while you use the app?"].exists {
            app.alerts["Allow “Wikipedia” to access your location while you use the app?"].buttons["Allow"].tap()
        }
        
        if app.navigationBars["Wikipédia, revenir à Explorer"].exists {
            app.navigationBars["Wikipédia, revenir à Explorer"].buttons["Explorer"].tap()
        }
        
        snapshot("Home page")
        
        app.navigationBars["Explorer"].buttons["search"].tap()
        
        app.searchFields["Rechercher dans Wikipédia"].typeText("steve jobs")
        
        snapshot("Search")
        
        let tablesQuery = app.tables
        
        let steveJobsLink = tablesQuery.links["Steve Jobs\nEntrepreneur et inventeur américain\n"]
        expectation(for: existsPredicate, evaluatedWith: steveJobsLink, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
        
        let steveJobsElement = app.staticTexts["Steve Jobs"]
        expectation(for: existsPredicate, evaluatedWith: steveJobsElement, handler: nil)
        
        tablesQuery.links["Steve Jobs\nEntrepreneur et inventeur américain\n"].tap()
        
        waitForExpectations(timeout: 5, handler: nil)
        
        
        snapshot("Steve Jobs Page")

    }
    
    func deDE () {
        let existsPredicate = NSPredicate(format: "exists == true")
        
        if app.buttons["ANFANGEN"].exists {
            app.buttons["ANFANGEN"].tap()
            app.buttons["FORTFAHREN"].tap()
            app.buttons["FERTIG"].tap()
        }
        if app.alerts["Allow “Wikipedia” to access your location while you use the app?"].exists {
            app.alerts["Allow “Wikipedia” to access your location while you use the app?"].buttons["Allow"].tap()
        }
        
        if app.navigationBars["Wikipedia, return to Explore"].exists {
            app.navigationBars["Wikipedia, return to Explore"].buttons["Explore"].tap()
        }
        
        if app.navigationBars["Wikipedia, zurück zu Entdecken"].exists {
            XCUIApplication().navigationBars["Wikipedia, zurück zu Entdecken"].buttons["Entdecken"].tap()
        }
        
        snapshot("Home page")
        
        
        app.navigationBars["Entdecken"].buttons["search"].tap()
        app.searchFields["Wikipedia durchsuchen"].typeText("steve jobs")



        snapshot("Search")
        
        let tablesQuery = app.tables
        
        let steveJobsLink = tablesQuery.links["Steve Jobs\nUS-amerikanischer Unternehmer, Mitbegründer von Apple Computer\n"]
        expectation(for: existsPredicate, evaluatedWith: steveJobsLink, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
        
        let steveJobsElement = app.staticTexts["Steve Jobs"]
        
        expectation(for: existsPredicate, evaluatedWith: steveJobsElement, handler: nil)
        
        tablesQuery.links["Steve Jobs\nUS-amerikanischer Unternehmer, Mitbegründer von Apple Computer\n"].tap()
        
        waitForExpectations(timeout: 5, handler: nil)
        
        snapshot("Steve Jobs Page")
    }
    
    
    func testExample() {
        
        
        
        
        let locales = args.filter { (locale) -> Bool in
            return locale == "de-DE"
            || locale == "en-US"
            || locale == "fr-FR"
        }
        print(args)
        let locale = locales.first
        print(locale)

        if let locale = locale {
            switch locale {
                case "de-DE": deDE()
                case "fr-FR": frFR()
                case "en-US": enUS()
            default:
                break
            }
            
        }
    }
    
}
