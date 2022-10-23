//
//  HomeScreen.swift
//  WikipediaUITests
//
//  Created by Eugene Tkachenko on 22.10.2022.
//
//  Home/Explore screen of the app


import XCTest

final class HomeScreen: XCTestCase {
    
    public func openSearchScreen() -> SearchScreen {
        let searchTabBarButton = XCUIApplication().tabBars.buttons["Search"]
        searchTabBarButton.tap()
        XCTAssertTrue(searchTabBarButton.isSelected, "Search screen is not opened")
    
        return SearchScreen()
    }
}
