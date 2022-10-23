//
//  SearchScreen.swift
//  WikipediaUITests
//
//  Created by Eugene Tkachenko on 22.10.2022.
//

import XCTest


public class SearchScreen: XCTestCase {
    
    @discardableResult
    public func searchArticle(_ searchQuery: String) -> Self {
        let searchField = XCUIApplication().otherElements["search_bar"].searchFields.firstMatch
        searchField.tap()
        searchField.typeText(searchQuery+"\n")
        
        let searchResultsCell = XCUIApplication().collectionViews.cells["search_results_cell"].staticTexts[searchQuery].firstMatch
        waitForElement(searchResultsCell, toExist: true)
        return self
    }
    
    public func openArticle(title: String) -> Article {
        let articleCell = XCUIApplication().collectionViews.cells["search_results_cell"].staticTexts[title].firstMatch
        articleCell.tap()
        
        let articleNavigationBar = XCUIApplication().navigationBars["W"]
        waitForElement(articleNavigationBar, toExist: true)
        return Article()
    }
    
    public func openArticle(index: Int) -> Article {
        let articleCell = XCUIApplication().collectionViews.cells["search_results_cell"].staticTexts.element(boundBy: index)
        articleCell.tap()
        
        let articleNavigationBar = XCUIApplication().navigationBars["W"]
        waitForElement(articleNavigationBar, toExist: true)
        return Article()
    }
}

