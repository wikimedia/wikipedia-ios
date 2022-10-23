//
//  Article.swift
//  WikipediaUITests
//
//  Created by Eugene Tkachenko on 22.10.2022.
//

import XCTest

public class Article {
    
    @discardableResult
    public func validateArticle(content: String) -> Self {
        let articleContent = XCUIApplication().webViews.otherElements.staticTexts[content].firstMatch
        waitForElement(articleContent, toExist: true, assertMessage: "Can't find \(content) content in opened article")
        return self
    }
    
    public func closeArticleScreen() -> SearchScreen {
        let backButton = XCUIApplication().navigationBars.buttons["Back"]
        backButton.tap()
        waitForElement(backButton, toExist: false)
        return SearchScreen()
    }
}
