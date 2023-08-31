import XCTest

final class TapBar: BaseScreen {
    
    private lazy var feed: XCUIElement = app.tabBars.buttons["Лента"]
    private lazy var search: XCUIElement = app.tabBars.buttons["Поиск"]
    private lazy var history: XCUIElement = app.tabBars.buttons["История"]
    private lazy var placesButton: XCUIElement = app.tabBars.buttons["Места"]
    
    @discardableResult
    func tapSearch() -> Self {
        search.tap()
        return self
    }

    @discardableResult
    func tapFeed() -> Self {
        feed.tap()
        return self
    }
    
    @discardableResult
    func tapHistory() -> Self {
        history.tap()
        return self
    }
    
    @discardableResult
    func tapPlacesButton() -> Self {
        placesButton.tap()
        return self
    }
    
    @discardableResult
    func checkSearchSelection(isSelectedElement: Bool) -> Self {
        XCTAssertEqual(search.isSelected, isSelectedElement)
        return self
    }
    @discardableResult
    func checkFeedSelection(isSelectedElement: Bool) -> Self {
        XCTAssertEqual(feed.isSelected, isSelectedElement)
        return self
    }
}
