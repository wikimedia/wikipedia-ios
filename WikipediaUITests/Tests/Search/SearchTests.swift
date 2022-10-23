//
//  SearchTests.swift
//  WikipediaUITests
//
//  Created by Eugene Tkachenko on 22.10.2022.
//

import XCTest

class SearchTests: BaseTest {

    func testArticleSearch() {
        
        let homeScreen = launchApp
        
        let searchTitle = "Apollo 11"
        let articleSubTitle = "First crewed Moon landing"
        let articleContent = "(July 16–24, 1969) was the American"

        homeScreen
            .openSearchScreen()
            .searchArticle(searchTitle)
            .openArticle(title: articleSubTitle)
            .validateArticle(content: articleContent)
    }
    
}
