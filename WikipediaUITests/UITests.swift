//
//  UITests.swift
//  Wikipedia
//
//  Created by Xue Qin on 10/26/17.
//  Copyright © 2017 Wikimedia Foundation. All rights reserved.
//

import XCTest
import UIKit
import Foundation

class UITests: WikipediaUITestCase{
    
    func testSearchFieldAndCheckHistory() {
        launch()
        app.searchFields["Search Wikipedia2"].tap()
        sleep(2)
        
        // search "ios"
        app.keyboards.keys["i"].tap()
        app.keyboards.keys["o"].tap()
        app.keyboards.keys["s"].tap()
        app.keyboards.buttons["Search"].tap()
        sleep(2)
        
        // delete input to check search history
        let deleteKey = app.keyboards.keys["delete"]
        deleteKey.tap()
        deleteKey.tap()
        deleteKey.tap()
        sleep(2)
        
        XCTAssert(app.staticTexts["RECENTLY SEARCHED"].exists, "No recently research history")
        app.buttons["Close"].tap()
    }
    
    func testDeleteRecentlyHistory() {
        launch()
        app.searchFields["Search Wikipedia2"].tap()
        sleep(2)
        
        // search "ios"
        app.keyboards.keys["i"].tap()
        app.keyboards.keys["o"].tap()
        app.keyboards.keys["s"].tap()
        app.keyboards.buttons["Search"].tap()
        sleep(2)
        
        // delete input to check search history
        let deleteKey = app.keyboards.keys["delete"]
        deleteKey.tap()
        deleteKey.tap()
        deleteKey.tap()
        sleep(2)
        
        //XCTAssert(app.staticTexts["RECENTLY SEARCHED"].exists, "No recently research history")
        //XCTAssert(app.buttons["Delete"].exists, "Deleting Recent History Button" +
        //                                        "Not Exist")
        
        let deleteHistoryButton = app.buttons["Delete"]
        let deleteAllRecentSearchesAlert = app.alerts["Delete all recent searches?"]
        deleteHistoryButton.tap()
        sleep(2)
        deleteAllRecentSearchesAlert.buttons["Cancel"].tap()
        sleep(2)
        deleteHistoryButton.tap()
        sleep(2)
        deleteAllRecentSearchesAlert.buttons["Delete All"].tap()
        app.buttons["Close"].tap()
    }
    
    /* This test case will test the basic operations on one wiki page about SONY.
       The operations include: view/select content, change language, add/delete bookmark, share, 
       change theme, brightness, font size, in-page search
     */
    func testOpenAWikiPage() {
        launch()
        app.searchFields["Search Wikipedia2"].tap()
        sleep(2)
        
        // search "sony"
        app.keyboards.keys["s"].tap()
        app.keyboards.keys["o"].tap()
        app.keyboards.keys["n"].tap()
        app.keyboards.keys["y"].tap()
        app.keyboards.buttons["Search"].tap()
        sleep(2)
        
        app.tables.cells.links["Sony\nJapanese multinational conglomerate corporation"].tap()
        app.navigationBars["Wikipedia, return to Explore"].buttons.matching(identifier: "Back").element(boundBy: 0).tap()
    }
    
    

    
    func testToolbarContents() {
        
        launch()
        app.searchFields["Search Wikipedia2"].tap()
        sleep(2)
        
        // search "sony"
        app.keyboards.keys["s"].tap()
        app.keyboards.keys["o"].tap()
        app.keyboards.keys["n"].tap()
        app.keyboards.keys["y"].tap()
        app.keyboards.buttons["Search"].tap()
        sleep(2)
        app.tables.cells.links["Sony\nJapanese multinational conglomerate corporation"].tap()
        
        let toolbarsQuery = app.toolbars
        
        // view/select content
        let tableOfContentsButton = toolbarsQuery.buttons["Table of contents"]
        sleep(2)
        tableOfContentsButton.tap()
        sleep(2)
        app.buttons["Close Table of contents"].tap()
        sleep(2)
        tableOfContentsButton.tap()
        sleep(2)
        app.tables.cells.staticTexts["History"].tap()
        //app.buttons["Close Table of contents"].tap()
        app.navigationBars["Wikipedia, return to Explore"].buttons.matching(identifier: "Back").element(boundBy: 0).tap()
        
        //app.navigationBars["Wikipedia, return to Explore"].buttons.matching(identifier: "Back").element(boundBy: 0).tap()
    }
    
    func testToolbarBookmark() {
        launch()
        app.searchFields["Search Wikipedia2"].tap()
        
        // search "sony"
        app.keyboards.keys["s"].tap()
        app.keyboards.keys["o"].tap()
        app.keyboards.keys["n"].tap()
        app.keyboards.keys["y"].tap()
        app.keyboards.buttons["Search"].tap()
        app.tables.cells.links["Sony\nJapanese multinational conglomerate corporation"].tap()
        
        let toolbarsQuery = app.toolbars
        
        toolbarsQuery.buttons["Save for later"].tap()
        sleep(1)
        toolbarsQuery.buttons["Saved. Activate to unsave."].tap()
        app.navigationBars["Wikipedia, return to Explore"].buttons.matching(identifier: "Back").element(boundBy: 0).tap()
        
    }
    
    func testToolbarShareReminder() {
        launch()
        app.searchFields["Search Wikipedia2"].tap()
        sleep(2)
        
        // search "sony"
        app.keyboards.keys["s"].tap()
        app.keyboards.keys["o"].tap()
        app.keyboards.keys["n"].tap()
        app.keyboards.keys["y"].tap()
        app.keyboards.buttons["Search"].tap()
        sleep(2)
        app.tables.cells.links["Sony\nJapanese multinational conglomerate corporation"].tap()
        
        let toolbarsQuery = app.toolbars
        let shareButton = toolbarsQuery.buttons["Share"]
        let tablesQuery = app.tables
        
        /********* Reminder **********/
        // approach 1
        shareButton.tap()
        app.otherElements["ActivityListView"].collectionViews.cells.collectionViews.buttons["Reminders"].tap()
        let reminderNavigationBar = app.navigationBars["Reminder"]
        reminderNavigationBar.buttons["Cancel"].tap()
        
        // approach 2
        shareButton.tap()
        app.otherElements["ActivityListView"].collectionViews.cells.collectionViews.buttons["Reminders"].tap()
        reminderNavigationBar.buttons["Add"].tap()
        
        // approach 3
        shareButton.tap()
        app.otherElements["ActivityListView"].collectionViews.cells.collectionViews.buttons["Reminders"].tap()
        tablesQuery.cells.staticTexts["Options"].tap()
        tablesQuery.segmentedControls.buttons["None"].tap()
        tablesQuery.segmentedControls.buttons["priority 1"].tap()
        tablesQuery.segmentedControls.buttons["priority 2"].tap()
        tablesQuery.segmentedControls.buttons["priority 3"].tap()
        tablesQuery.switches["Remind me on a day"].tap()
        
        app.navigationBars["Options"].buttons["Reminder"].tap()
        app.navigationBars["Reminder"].buttons["Cancel"].tap()
        app.navigationBars["Wikipedia, return to Explore"].buttons.matching(identifier: "Back").element(boundBy: 0).tap()
        
    }
    
    func testToolbarShareReminderEditingDate() {
        launch()
        app.searchFields["Search Wikipedia2"].tap()
        sleep(2)
        
        // search "sony"
        app.keyboards.keys["s"].tap()
        app.keyboards.keys["o"].tap()
        app.keyboards.keys["n"].tap()
        app.keyboards.keys["y"].tap()
        app.keyboards.buttons["Search"].tap()
        sleep(2)
        app.tables.cells.links["Sony\nJapanese multinational conglomerate corporation"].tap()
        
        let toolbarsQuery = app.toolbars
        let shareButton = toolbarsQuery.buttons["Share"]
        let tablesQuery = app.tables
        
        shareButton.tap()
        app.otherElements["ActivityListView"].collectionViews.cells.collectionViews.buttons["Reminders"].tap()
        tablesQuery.cells.staticTexts["Options"].tap()
        tablesQuery.switches["Remind me on a day"].tap()
        tablesQuery.cells.staticTexts["Alarm"].tap()
        
        let firstWheel = app.pickerWheels.element(boundBy: 0)
        firstWheel.adjust(toPickerWheelValue: "Mar 1")
        
        let secondWheel = app.pickerWheels.element(boundBy: 1)
        secondWheel.adjust(toPickerWheelValue: "4")
        
        let thirdWheel = app.pickerWheels.element(boundBy: 2)
        thirdWheel.adjust(toPickerWheelValue: "30")
        
        let fourthWheel = app.pickerWheels.element(boundBy: 3)
        fourthWheel.adjust(toPickerWheelValue: "AM")
        
        app.navigationBars["Options"].buttons["Reminder"].tap()
        app.navigationBars["Reminder"].buttons["Cancel"].tap()
        app.navigationBars["Wikipedia, return to Explore"].buttons.matching(identifier: "Back").element(boundBy: 0).tap()
    }
    
    func testToolbarShareReminderEditingFrequency() {
        launch()
        app.searchFields["Search Wikipedia2"].tap()
        sleep(2)
        
        // search "sony"
        app.keyboards.keys["s"].tap()
        app.keyboards.keys["o"].tap()
        app.keyboards.keys["n"].tap()
        app.keyboards.keys["y"].tap()
        app.keyboards.buttons["Search"].tap()
        sleep(2)
        app.tables.cells.links["Sony\nJapanese multinational conglomerate corporation"].tap()
        
        let toolbarsQuery = app.toolbars
        let shareButton = toolbarsQuery.buttons["Share"]
        let tablesQuery = app.tables
        
        shareButton.tap()
        app.otherElements["ActivityListView"].collectionViews.cells.collectionViews.buttons["Reminders"].tap()
        tablesQuery.cells.staticTexts["Options"].tap()
        tablesQuery.switches["Remind me on a day"].tap()
        let repeatButton = tablesQuery.cells.staticTexts["Repeat"]
        
        repeatButton.tap()
        tablesQuery.cells.staticTexts["Every Day"].tap()
        sleep(2)
        repeatButton.tap()
        tablesQuery.cells.staticTexts["Every Week"].tap()
        sleep(2)
        repeatButton.tap()
        tablesQuery.cells.staticTexts["Every 2 Weeks"].tap()
        sleep(2)
        repeatButton.tap()
        tablesQuery.cells.staticTexts["Every Month"].tap()
        sleep(2)
        repeatButton.tap()
        tablesQuery.cells.staticTexts["Every Year"].tap()
        sleep(2)
        
        // Custom Repeat
        repeatButton.tap()
        tablesQuery.cells.staticTexts["Custom"].tap()
        tablesQuery.cells.staticTexts["Frequency"].tap()
        
        let freqWheel = app.pickerWheels.element(boundBy: 0)
        freqWheel.adjust(toPickerWheelValue: "Weekly")
        tablesQuery.cells.staticTexts["Every"].tap()
        
        let everyWheel = app.pickerWheels.element(boundBy: 0)
        everyWheel.adjust(toPickerWheelValue: "4")
        
        //XCTAssertTrue(tablesQuery.cells.staticTexts["Sunday"].exists, "Weekly Frequency failed")
        
        app.navigationBars["Custom"].buttons["Repeat"].tap()
        app.navigationBars["Repeat"].buttons["Options"].tap()
        
        let repeatEndButton = tablesQuery.cells.staticTexts["End Repeat"]
        repeatEndButton.tap()
        app.navigationBars["End Repeat"].buttons["Cancel"].tap()
        
        // repeat end edit
        repeatEndButton.tap()
        tablesQuery.cells.staticTexts["End Repeat Date"].tap()
        
        let thirdWheel = app.pickerWheels.element(boundBy: 2)
        thirdWheel.adjust(toPickerWheelValue: "2018")
        
        let secondWheel = app.pickerWheels.element(boundBy: 1)
        secondWheel.adjust(toPickerWheelValue: "10")
        
        let firstWheel = app.pickerWheels.element(boundBy: 0)
        firstWheel.adjust(toPickerWheelValue: "October")
        
        app.navigationBars["End Repeat"].buttons["Done"].tap()
        
        //XCTAssertTrue(tablesQuery.cells.staticTexts["Wed, Oct 10, 2018"].exists, "Weekly Frequency failed")
        
        app.navigationBars["Options"].buttons["Reminder"].tap()
        app.navigationBars["Reminder"].buttons["Add"].tap()
        app.navigationBars["Wikipedia, return to Explore"].buttons.matching(identifier: "Back").element(boundBy: 0).tap()
    }
    
    func testToolbarShareAddToReadList() {
        launch()
        app.searchFields["Search Wikipedia2"].tap()
        sleep(2)
        
        // search "sony"
        app.keyboards.keys["s"].tap()
        app.keyboards.keys["o"].tap()
        app.keyboards.keys["n"].tap()
        app.keyboards.keys["y"].tap()
        app.keyboards.buttons["Search"].tap()
        sleep(2)
        app.tables.cells.links["Sony\nJapanese multinational conglomerate corporation"].tap()
        
        let toolbarsQuery = app.toolbars
        let shareButton = toolbarsQuery.buttons["Share"]
        
        // Add to Reading List
        shareButton.tap()
        app.otherElements["ActivityListView"].collectionViews.cells.collectionViews.buttons["Add to Reading List"].tap()
        app.navigationBars["Wikipedia, return to Explore"].buttons.matching(identifier: "Back").element(boundBy: 0).tap()
        
    }
    
    func testToolbarShareCopy() {
        launch()
        app.searchFields["Search Wikipedia2"].tap()
        sleep(2)
        
        // search "sony"
        app.keyboards.keys["s"].tap()
        app.keyboards.keys["o"].tap()
        app.keyboards.keys["n"].tap()
        app.keyboards.keys["y"].tap()
        app.keyboards.buttons["Search"].tap()
        sleep(2)
        app.tables.cells.links["Sony\nJapanese multinational conglomerate corporation"].tap()
        
        let toolbarsQuery = app.toolbars
        let shareButton = toolbarsQuery.buttons["Share"]
        
        // Add to Reading List
        shareButton.tap()
        app.otherElements["ActivityListView"].collectionViews.cells.collectionViews.buttons["Copy"].tap()
        app.navigationBars["Wikipedia, return to Explore"].buttons.matching(identifier: "Back").element(boundBy: 0).tap()
        
    }
    
    func testToolbarShareOpenInSafari() {
        launch()
        app.searchFields["Search Wikipedia2"].tap()
        sleep(2)
        
        // search "sony"
        app.keyboards.keys["s"].tap()
        app.keyboards.keys["o"].tap()
        app.keyboards.keys["n"].tap()
        app.keyboards.keys["y"].tap()
        app.keyboards.buttons["Search"].tap()
        sleep(2)
        app.tables.cells.links["Sony\nJapanese multinational conglomerate corporation"].tap()
        
        let toolbarsQuery = app.toolbars
        let shareButton = toolbarsQuery.buttons["Share"]
        
        // Add to Reading List
        shareButton.tap()
        app.otherElements["ActivityListView"].collectionViews.cells.collectionViews.buttons["Open in Safari"].tap()
        
    }
    
    func testToolbarShareButtomMore() {
        launch()
        if app.searchFields["Search Wikipedia2"].exists {
            app.searchFields["Search Wikipedia2"].tap()
        } else {
            app.navigationBars["Wikipedia, return to Explore"].buttons.matching(identifier: "Back").element(boundBy: 0).tap()
            app.searchFields["Search Wikipedia2"].tap()
        }
        sleep(2)
        
        // search "sony"
        app.keyboards.keys["s"].tap()
        app.keyboards.keys["o"].tap()
        app.keyboards.keys["n"].tap()
        app.keyboards.keys["y"].tap()
        app.keyboards.buttons["Search"].tap()
        sleep(2)
        app.tables.cells.links["Sony\nJapanese multinational conglomerate corporation"].tap()
        
        let toolbarsQuery = app.toolbars
        let shareButton = toolbarsQuery.buttons["Share"]
        
        // Add to Reading List
        shareButton.tap()
        app.otherElements["ActivityListView"].collectionViews.cells.collectionViews.buttons.matching(identifier: "More").element(boundBy: 1).tap()
        app.navigationBars["Activities"].buttons.matching(identifier: "Done").element(boundBy: 0).tap()
        app.buttons["Cancel"].tap()
        app.navigationBars["Wikipedia, return to Explore"].buttons.matching(identifier: "Back").element(boundBy: 0).tap()
    }
    
    func testToolbarShareTopMore() {
        launch()
        if app.searchFields["Search Wikipedia2"].exists {
            app.searchFields["Search Wikipedia2"].tap()
        } else {
            app.navigationBars["Wikipedia, return to Explore"].buttons.matching(identifier: "Back").element(boundBy: 0).tap()
            app.searchFields["Search Wikipedia2"].tap()
        }
        sleep(2)
        
        // search "sony"
        app.keyboards.keys["s"].tap()
        app.keyboards.keys["o"].tap()
        app.keyboards.keys["n"].tap()
        app.keyboards.keys["y"].tap()
        app.keyboards.buttons["Search"].tap()
        sleep(2)
        app.tables.cells.links["Sony\nJapanese multinational conglomerate corporation"].tap()
        
        let toolbarsQuery = app.toolbars
        let shareButton = toolbarsQuery.buttons["Share"]
        let tablesQuery = app.tables
        
        // Add to Reading List
        shareButton.tap()
        app.otherElements["ActivityListView"].collectionViews.cells.collectionViews.buttons.matching(identifier: "More").element(boundBy: 0).tap()
        //app.tables.cells["1"].children(matching: .switch).matching(identifier: "Reminders").element(boundBy: 0).tap()
        tablesQuery.switches.matching(identifier: "Reminders").element(boundBy: 0).tap()
        tablesQuery.switches.matching(identifier: "Reminders").element(boundBy: 0).tap()
        app.navigationBars["Activities"].buttons.matching(identifier: "Done").element(boundBy: 0).tap()
        app.buttons["Cancel"].tap()
        app.navigationBars["Wikipedia, return to Explore"].buttons.matching(identifier: "Back").element(boundBy: 0).tap()
        
    }
    
    func testToolbarThemesEdit() {
        launch()
        app.searchFields["Search Wikipedia2"].tap()
        sleep(2)
        
        // search "sony"
        app.keyboards.keys["s"].tap()
        app.keyboards.keys["o"].tap()
        app.keyboards.keys["n"].tap()
        app.keyboards.keys["y"].tap()
        app.keyboards.buttons["Search"].tap()
        sleep(2)
        app.tables.cells.links["Sony\nJapanese multinational conglomerate corporation"].tap()
        
        let readingThemesControlsButton = app.toolbars.buttons["Reading Themes Controls"]
        readingThemesControlsButton.tap()
        
        let scrollViewsQuery = app.scrollViews
        //let textSizeSlider = scrollViewsQuery.otherElements.sliders["Text size slider"]
        //textSizeSlider.adjust(toNormalizedSliderPosition: 0.0)
        
        let brightnessSlider = scrollViewsQuery.otherElements.sliders["Brightness slider"]
        brightnessSlider.adjust(toNormalizedSliderPosition: 1.0)
        
        scrollViewsQuery.otherElements.buttons["Dark theme"].tap()
        scrollViewsQuery.otherElements.buttons["Sepia theme"].tap()
        scrollViewsQuery.otherElements.buttons["Light theme"].tap()
        
        app.children(matching: .window).element(boundBy: 0).tap()
        app.navigationBars["Wikipedia, return to Explore"].buttons.matching(identifier: "Back").element(boundBy: 0).tap()
        
    }
    
    func testToolbarInPageSearch() {
        launch()
        app.searchFields["Search Wikipedia2"].tap()
        sleep(2)
        
        // search "sony"
        app.keyboards.keys["s"].tap()
        app.keyboards.keys["o"].tap()
        app.keyboards.keys["n"].tap()
        app.keyboards.keys["y"].tap()
        app.keyboards.buttons["Search"].tap()
        sleep(2)
        app.tables.cells.links["Sony\nJapanese multinational conglomerate corporation"].tap()
        
        let toolbarsQuery = app.toolbars
        let findInPageButton = toolbarsQuery.buttons["Find in page"]
        
        findInPageButton.tap()
        app.keyboards.keys["s"].tap()
        app.keyboards.keys["o"].tap()
        app.keyboards.keys["n"].tap()
        app.keyboards.keys["y"].tap()
        app.keyboards.buttons["Search"].tap()
        
        let chevronDownButton = app.buttons["chevron down"]
        let chevronUpButton = app.buttons["chevron up"]
        chevronDownButton.tap()
        chevronUpButton.tap()
        app.buttons["close"].tap()
        
        //return to main menu
        app.navigationBars["Wikipedia, return to Explore"].buttons.matching(identifier: "Back").element(boundBy: 0).tap()
        
    }
    
    
    func testPlacesShareOpenInMaps() {
        launch()
        let tabBarsQuery = app.tabBars
        tabBarsQuery.buttons["Places"].tap()
        sleep(3)
        app.links["Union Square, San Francisco\nNeighborhood in San Francisco\n350 feet"].tap()
        app.toolbars.buttons["Share"].tap()
        app.otherElements["ActivityListView"].collectionViews.cells.collectionViews.buttons["Open in Maps"].tap()
        
    }
    
    func testPlacesShareGetDirections() {
        launch()
        let tabBarsQuery = app.tabBars
        tabBarsQuery.buttons["Places"].tap()
        
        app.links["Union Square, San Francisco\nNeighborhood in San Francisco\n350 feet"].tap()
        app.toolbars.buttons["Share"].tap()
        app.otherElements["ActivityListView"].collectionViews.cells.collectionViews.buttons["Get Directions"].tap()
        
    }
 
    
    func testPlacesSearchAndSave() {
        launch()
        let tabBarsQuery = app.tabBars
        tabBarsQuery.buttons["Places"].tap()
        
        let showAsMapButton = app.segmentedControls.buttons["Show as map"]
        let showAsListButton = app.segmentedControls.buttons["Show as list"]
        showAsMapButton.tap()
        showAsListButton.tap()
        
        let searchPlacesSearchField = app.searchFields["Search Places"]
        searchPlacesSearchField.tap()
        
        app.keyboards.keys["S"].tap()
        app.keyboards.keys["a"].tap()
        app.keyboards.keys["n"].tap()
        app.keyboards.keys["space"].tap()
        app.keyboards.keys["a"].tap()
        app.keyboards.keys["n"].tap()
        app.keyboards.keys["t"].tap()
        app.keyboards.keys["o"].tap()
        app.keyboards.keys["n"].tap()
        app.keyboards.keys["i"].tap()
        app.keyboards.keys["o"].tap()
        app.keyboards.buttons["Search"].tap()
        sleep(3)
        
        let tablesQuery = app.tables
        tablesQuery.links["San Antonio, County seat city in Bexar County, Texas, USA, 1489.15 miles at 4 o'clock"].tap()
        sleep(2)
        //app.navigationBars["Wikipedia, return to Explore"].buttons.matching(identifier: "Back").element(boundBy: 0).tap()
        app.navigationBars["W"].buttons["Places"].tap()
        app.tabBars.buttons["Explore"].tap()
    }
    
    func testHistory() {
        launch()
        app.tabBars.buttons["History"].tap()
        let historyNavigationBar = app.navigationBars["History"]
        
        if historyNavigationBar.buttons["Clear"].isEnabled {
            // has history
            historyNavigationBar.buttons["search"].tap()
            app.buttons["Close"].tap()
            historyNavigationBar.buttons["Clear"].tap()
            app.sheets["Are you sure you want to delete all your recent items?"].buttons["Cancel"].tap()
            historyNavigationBar.buttons["Clear"].tap()
            app.sheets["Are you sure you want to delete all your recent items?"].buttons["Yes, delete all"].tap()
            app.tabBars.buttons["Explore"].tap()
        } else {
            // do nothing
        }
        
        
    }
    
    /*func testCreateAccount() {
        launch()
        app.navigationBars["Explore"].buttons["settings"].tap()
        app.tables.cells.containing(.staticText, identifier:"Log in").element(boundBy: 0).tap()
    
        let elementsQuery = app.scrollViews.otherElements
        elementsQuery.staticTexts["Don't have an account? Join Wikipedia."].tap()
        
    }*/
    
    func testSupport() {
        launch()
        app.navigationBars["Explore"].buttons["settings"].tap()
        app.tables.cells.containing(.staticText, identifier:"Support Wikipedia").element(boundBy: 0).tap()
    }
    
    func testLanguageSetting() {
        launch()
        app.navigationBars["Explore"].buttons["settings"].tap()
        app.tables.cells.staticTexts.matching(identifier: "My languages").element(boundBy: 0).tap()
        
        // Add language
        let tablesQuery = app.tables
        tablesQuery.buttons["Add another language"].tap()
        tablesQuery.cells.staticTexts["Aragonese"].tap()

        // Edit Language
        app.navigationBars["My languages"].buttons["Edit"].tap()
        app.navigationBars["My languages"].buttons["Done"].tap()
        
        app.navigationBars["My languages"].buttons["Close"].tap()
        app.navigationBars["Settings"].buttons["Close"].tap()
    }
    
    func testShowLanguagesOnSearch() {
        launch()
        app.navigationBars["Explore"].buttons["settings"].tap()
        
        let tablesQuery = app.tables        
        let showLanguagesOnSearchSwitch = tablesQuery.staticTexts.switches.matching(identifier: "Show languages on search")
        
        // If there is at least one
        if showLanguagesOnSearchSwitch.count > 0 {
            // We take the first one and tap it
            let firstButton = showLanguagesOnSearchSwitch.element(boundBy: 0)
            firstButton.tap()
            firstButton.tap()
        }
        
        app.navigationBars["Settings"].buttons["Close"].tap()
    }
    
    func testNotifications() {
        launch()
        app.navigationBars["Explore"].buttons["settings"].tap()
        app.tables.cells.containing(.staticText, identifier:"Notifications").element(boundBy: 0).tap()

        let tablesQuery = app.tables
        tablesQuery.cells.containing(.staticText, identifier:"Learn more about notifications").element(boundBy: 0).tap()
        app.alerts["More about notifications"].buttons["Got it"].tap()
        sleep(3)
        let trendingCurrentEventsSwitch = tablesQuery.cells.containing(.switch, identifier:"Trending current events").element(boundBy: 0)
        trendingCurrentEventsSwitch.tap()
        sleep(2)
        
        // may pop alert
        if app.alerts["“Wikipedia” Would Like to Send You Notifications"].exists {
            app.alerts["“Wikipedia” Would Like to Send You Notifications"].buttons["Allow"].tap()
        }
        
        app.navigationBars["Settings"].buttons["Settings"].tap()
        app.navigationBars["Settings"].buttons["Close"].tap()
    }
    
    func testAppearance() {
        launch()
        app.navigationBars["Explore"].buttons["settings"].tap()
        
        let tablesQuery = app.tables
        tablesQuery.cells.staticTexts.matching(identifier: "Appearance").element(boundBy: 0).tap()
        tablesQuery.cells.staticTexts.matching(identifier: "Sepia").element(boundBy: 0).tap()
        tablesQuery.cells.staticTexts.matching(identifier: "Dark").element(boundBy: 0).tap()
        
        let dimImagesSwitch = tablesQuery.cells.switches.matching(identifier: "Dim images").element(boundBy: 0)
        dimImagesSwitch.tap()

        //let textSizeSliderElement = tablesQuery.cells.otherElements.sliders["Text size slider"]
        //let textSizeSliderElement = tablesQuery.cells.sliders.matching(identifier: "Text size slider").element(boundBy: 0)
        //textSizeSliderElement.adjust(toNormalizedSliderPosition: 0.5)

        tablesQuery.cells.staticTexts.matching(identifier: "Default").element(boundBy: 0).tap()
        
        XCUIApplication().navigationBars["Reading themes"].buttons["Settings"].tap()
        app.navigationBars["Settings"].buttons["Close"].tap()

    }
    
    func testClearCachedData() {
        launch()
        app.navigationBars["Explore"].buttons["settings"].tap()
        app.tables.staticTexts.matching(identifier: "Clear cached data").element(boundBy: 0).tap()
        app.alerts["Clear cached data?"].buttons["Clear cache"].tap()
        app.navigationBars["Settings"].buttons["Close"].tap()
        
    }
    
    func testPrivacyPolicy() {
        launch()
        app.navigationBars["Explore"].buttons["settings"].tap()
        app.tables.staticTexts.matching(identifier: "Privacy policy").element(boundBy: 0).tap()
        app.buttons["Done"].tap()
        app.navigationBars["Settings"].buttons["Close"].tap()
    }
    
    func testTermsOfUse() {
        launch()
        app.navigationBars["Explore"].buttons["settings"].tap()
        app.tables.staticTexts.matching(identifier: "Terms of Use").element(boundBy: 0).tap()
        app.buttons["Done"].tap()
        app.navigationBars["Settings"].buttons["Close"].tap()
    }
    
    func testSendUsageReports() {
        launch()
        app.navigationBars["Explore"].buttons["settings"].tap()
        
        let tablesQuery = app.tables
        let sendUsageReportsSwitch = tablesQuery.staticTexts.switches.matching(identifier: "Send usage reports")
        
        // If there is at least one
        if sendUsageReportsSwitch.count > 0 {
            // We take the first one and tap it
            let firstButton = sendUsageReportsSwitch.element(boundBy: 0)
            firstButton.tap()
            firstButton.tap()
        }
        app.navigationBars["Settings"].buttons["Close"].tap()
    }
    
    func testWarnIfLeavingZero() {
        launch()
        app.navigationBars["Explore"].buttons["settings"].tap()
        let tablesQuery = app.tables
        let warnElement = tablesQuery.staticTexts.staticTexts["Warn if leaving Zero"]
        scrollToElement(element: warnElement)
        tablesQuery.staticTexts.switches.matching(identifier: "Warn if leaving Zero").element(boundBy: 0).tap()
        app.navigationBars["Settings"].buttons["Close"].tap()
    }
    
    func testWikiZeroFAQ() {
        launch()
        app.navigationBars["Explore"].buttons["settings"].tap()
        let tablesQuery = app.tables
        let faqElement = tablesQuery.staticTexts.matching(identifier: "Wikipedia Zero FAQ").element(boundBy: 0)
        scrollToElement(element: faqElement)
        faqElement.tap()
    }
    
    func testRateApp() {
        launch()
        app.navigationBars["Explore"].buttons["settings"].tap()
        app.swipeUp()
        app.swipeUp()
        let rateTheAppStaticText = app.tables.cells.staticTexts.matching(identifier: "Rate the app").element(boundBy: 0)
        rateTheAppStaticText.tap()

    }
    
    /*
    func testHelpAndFeedback() {
        launch()
        app.navigationBars["Explore"].buttons["settings"].tap()
        let helpfeedback = app.tables.cells.staticTexts.matching(identifier: "Help and feedback").element(boundBy: 0)
        scrollToElement(element: helpfeedback)
        helpfeedback.tap()
        sleep(2)
        app.navigationBars["W"].buttons["Settings"].tap()
        app.navigationBars["Settings"].buttons["Close"].tap()
        
    }
 */
    
    func testLogoutAndFailedLogin() {
        launch()
        // logout
        app.navigationBars["Explore"].buttons["settings"].tap()
        logout()
        sleep(2)
        app.tables.cells.staticTexts.matching(identifier: "Log in").element(boundBy: 0).tap()
        
        // createAccount
        let elementsQuery = app.scrollViews.otherElements
        elementsQuery.staticTexts["Don't have an account? Join Wikipedia."].tap()
        app.navigationBars["Wikipedia.WMFAccountCreationView"].buttons["close"].tap()
        
        // failed login
        app.tables.cells.staticTexts.matching(identifier: "Log in").element(boundBy: 0).tap()
        let enterUsernameTextField = elementsQuery.textFields["enter username"]
        let enterPasswordTextField = elementsQuery.secureTextFields["enter password"]
        
        enterUsernameTextField.typeText("guiileak")
        app.buttons["Next"].tap()
        
        enterPasswordTextField.typeText("utsa")
        enterPasswordTextField.typeText("123456")
        
        if elementsQuery.buttons["Log in"].isEnabled {
            elementsQuery.buttons["Log in"].tap()
        }
        
        sleep(3)
        
        enterUsernameTextField.tap()
        enterUsernameTextField.buttons["clear mini"].tap()
        enterUsernameTextField.typeText("guileak")
        app.buttons["Next"].tap()
        
        enterPasswordTextField.typeText("utsa")
        
        if elementsQuery.buttons["Log in"].isEnabled {
            elementsQuery.buttons["Log in"].tap()
        }
        
    }
    
/*    func testFailedLogin() {
        launch()
        app.navigationBars["Explore"].buttons["settings"].tap()
        app.tables.cells.staticTexts.matching(identifier: "Log in").element(boundBy: 0).tap()
        
        let elementsQuery = app.scrollViews.otherElements
        let enterUsernameTextField = elementsQuery.textFields["enter username"]
        let enterPasswordTextField = elementsQuery.secureTextFields["enter password"]
        
        enterUsernameTextField.typeText("guiileak")
        app.buttons["Next"].tap()
        
        enterPasswordTextField.typeText("utsa")
        enterPasswordTextField.typeText("123456")
        
        if elementsQuery.buttons["Log in"].isEnabled {
            elementsQuery.buttons["Log in"].tap()
        }
        
        sleep(3)
        
        enterUsernameTextField.tap()
        enterUsernameTextField.buttons["clear mini"].tap()
        enterUsernameTextField.typeText("guileak")
        app.buttons["Next"].tap()
        
        enterPasswordTextField.typeText("utsa")
        
        if elementsQuery.buttons["Log in"].isEnabled {
            elementsQuery.buttons["Log in"].tap()
        }
        
    } */
    
    func testForgetPasswordbyUserName() {
        launch()
        app.navigationBars["Explore"].buttons["settings"].tap()
        logout()
        app.tables.cells.staticTexts.matching(identifier: "Log in").element(boundBy: 0).tap()
        
        let elementsQuery = app.scrollViews.otherElements
        elementsQuery.staticTexts["Forgot your password?"].tap()
        
        let enterUsernameTextField = elementsQuery.textFields["enter username"]
        enterUsernameTextField.tap()
        enterUsernameTextField.typeText("guileak")
        elementsQuery.buttons["Reset"].tap()
    }
    
    func testForgetPasswordbyEmail() {
        launch()
        app.navigationBars["Explore"].buttons["settings"].tap()
        logout()
        app.tables.cells.staticTexts.matching(identifier: "Log in").element(boundBy: 0).tap()
        
        let elementsQuery = app.scrollViews.otherElements
        elementsQuery.staticTexts["Forgot your password?"].tap()
        
        let enterUsernameTextField = elementsQuery.textFields["enter username"]
        let enterEmailTextField = elementsQuery.textFields["example@example.org"]
        enterUsernameTextField.tap()
        
        app.buttons["Next"].tap()
        enterEmailTextField.typeText("ui.privacy@gmail.com")
        
        
        elementsQuery.buttons["Reset"].tap()
    }
    
    func testTopRead() {
        launch()
        let yesterdayElement = app.collectionViews.otherElements["Top read on English Wikipedia " + yesterday]
        scrollToElement(element: yesterdayElement)
        yesterdayElement.tap()
    }
    
    // OnThisDay
    func testPictureTodayLocalShare() {
        launch()
        let todayElement = app.collectionViews.otherElements["Picture of the day " + today]
        scrollToElement(element: todayElement)
        todayElement.tap()
        
        let shareButton = app.navigationBars.buttons["share"]
        shareButton.tap()
        
        let collectionViewsQuery = app.otherElements["ActivityListView"].collectionViews.cells.collectionViews
        
        // Approach 1: Copy
        collectionViewsQuery.buttons["Copy"].tap()
        
        // Approach 2: Save Image
        shareButton.tap()
        collectionViewsQuery.buttons["Save Image"].tap()
        if app.alerts["“Wikipedia” Would Like to Access Your Photos"].exists {
            app.alerts["“Wikipedia” Would Like to Access Your Photos"].buttons["OK"].tap()
        }
        
        // Approach 3: Print
        shareButton.tap()
        collectionViewsQuery.buttons["Print"].tap()
        
        let tablesQuery = app.tables
        tablesQuery.cells.buttons["Increment"].tap()
        tablesQuery.cells.buttons["Decrement"].tap()
        app.navigationBars["Printer Options"].buttons["Cancel"].tap()
        
        // Approach 4: Assign to Contact
        shareButton.tap()
        collectionViewsQuery.buttons["Assign to Contact"].tap()
        app.tables.staticTexts["John Appleseed"].tap()
        app.buttons["Choose"].tap()
        
    }
    
    func testPictureTodayOnlineShare(){
        launch()
        let todayElement = app.collectionViews.otherElements["Picture of the day " + today]
        scrollToElement(element: todayElement)
        todayElement.tap()
        
        app.buttons["info white"].tap()
        let shareButton = app.toolbars.buttons["Share"]
        shareButton.tap()
        let collectionViewsQuery = app.otherElements["ActivityListView"].collectionViews.cells.collectionViews
        
        //Approach 1: share on Twitter
        collectionViewsQuery.buttons["Twitter"].tap()
        sleep(2)
        app.alerts["No Twitter Accounts"].buttons["Cancel"].tap()
        
        //Approach 2: share on Facebook
        shareButton.tap()
        collectionViewsQuery.buttons["Facebook"].tap()
        sleep(2)
        app.alerts["No Facebook Account"].buttons["Cancel"].tap()
        
        //Approach 3
        shareButton.tap()
        collectionViewsQuery.buttons["Add to Reading List"].tap()
        
        //Approach 4
        shareButton.tap()
        collectionViewsQuery.buttons["Copy"].tap()
        
        //Approach 5: Add BookMark to Favorites
        shareButton.tap()
        collectionViewsQuery.buttons["Add Bookmark"].tap()
        let saveButton = app.navigationBars["Add Bookmark"].buttons["Save"]
        saveButton.tap()
        
        //Approach 6: Add BookMark to Bookmarks
        shareButton.tap()
        collectionViewsQuery.buttons["Add Bookmark"].tap()
        let favoritesStaticText = app.tables.cells.staticTexts["Favorites"]
        favoritesStaticText.tap()
        let BookmarksStaticText = app.tables.cells.staticTexts["Bookmarks"]
        BookmarksStaticText.tap()
        saveButton.tap()
        
        //Approach 6: Add BookMark to Bookmarks
        shareButton.tap()
        collectionViewsQuery.buttons["Add Bookmark"].tap()
        BookmarksStaticText.tap()
        favoritesStaticText.tap()
        saveButton.tap()
        
        //Approach 7
        shareButton.tap()
        collectionViewsQuery.buttons["Request Desktop Site"].tap()
        
        //Approach 8
        let safariButton = app.toolbars.buttons["Open in Safari"]
        safariButton.tap()
    }
    
    func testFeaturedAriticle(){
        launch()
        if app.collectionViews.otherElements["Featured article " + today].exists {
            app.collectionViews.cells.buttons["Save for later"].tap()
            app.collectionViews.otherElements["Featured article " + today].tap()
        }
        sleep(3)
        app.navigationBars["Wikipedia, return to Explore"].buttons.matching(identifier: "Back").element(boundBy: 0).tap()
    }
    
    func testRandomArticle(){
        launch()
        let randomElement = app.collectionViews.otherElements["Random article Wikipedia"]
        scrollToElement(element: randomElement)
        randomElement.tap()
        //app.buttons.matching(identifier: "Randomizer").element(boundBy: 0).tap()
        //app.navigationBars["Wikipedia, return to Explore"].buttons.matching(identifier: "Back").element(boundBy: 0).tap()
        app.navigationBars["Wikipedia, return to Explore"].buttons.matching(identifier: "Back").element(boundBy: 0).tap()
    }
    
    func testTodayOnWiki(){
        launch()
        let todayElement = app.collectionViews.otherElements["Today on Wikipedia " + today]
        scrollToElement(element: todayElement)
        todayElement.tap()
        sleep(1)
        app.navigationBars["Wikipedia, return to Explore"].buttons.matching(identifier: "Back").element(boundBy: 0).tap()
    }
    
    func testOnThisDay(){
        launch()
        let todayElement = app.collectionViews.otherElements["On this day " + today]
        scrollToElement(element: todayElement)
        todayElement.tap()
        app.navigationBars["On this day"].buttons.matching(identifier: "Back").element(boundBy: 0).tap()
        
    }
    
    /*
    func testIntheNews() {
        launch()
        let moreInTheNewsElement = app.collectionViews.staticTexts["More in the news"]
        scrollToElement(element: moreInTheNewsElement)
        moreInTheNewsElement.tap()
        sleep(5)
        if app.alerts["“Wikipedia” Would Like to Send You Notifications"].exists {
            sleep(3)
            app.alerts["“Wikipedia” Would Like to Send You Notifications"].buttons["Allow"].tap()
        }
        app.swipeUp()
        app.swipeUp()
        app.navigationBars["In the news"].buttons.matching(identifier: "Back").element(boundBy: 0).tap()
        
    }
 */
    
    func testPlaceNear() {
        launch()
        let placeElement = app.collectionViews.staticTexts["More from nearby your location"]
        scrollToElement(element: placeElement)
        placeElement.tap()
        sleep(2)
        app.navigationBars["Explore"].buttons.matching(identifier: "Back").element(boundBy: 0).tap()
    }

}
