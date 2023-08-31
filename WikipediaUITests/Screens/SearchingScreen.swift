import XCTest

final class SearchingScreen: BaseScreen {
    
    private lazy var search: XCUIElement = app.tabBars.buttons["Поиск"]
    private lazy var searchField: XCUIElement = app.searchFields.firstMatch
    private lazy var firstItemInList: XCUIElement = app.collectionViews.firstMatch.cells.descendants(matching: .staticText).firstMatch
    
    @discardableResult
    func tapSearch() -> Self {
        search.tap()
        return self
    }
    
    @discardableResult
    func tapFirstItemInList(_ text: String) -> Self {
        if app.collectionViews.firstMatch.cells.firstMatch.waitForExistence(timeout: 1) {
            app.staticTexts[text].tap()
        }
        return self
    }

    @discardableResult
    func typeSearchField(_ text: String) -> Self {
        searchField.tap()
        app.typeText(text)
        return self
    }
    
    @discardableResult
    func checkPageExist(_ text: String) -> Self {
        var exists = false
        if app.webViews.staticTexts[text].waitForExistence(timeout: 1) {
            exists = app.webViews.staticTexts[text].exists
        }
        XCTAssertTrue(exists)
        return self
    }
}

