import XCTest

final class HistoryScreen: BaseScreen {
    
    private lazy var clean: XCUIElement = app.buttons["Очистить"]
    private lazy var agree: XCUIElement = app.buttons["Да, удалить всё"]
    private lazy var cellsCount = app.collectionViews.cells.count
    
    @discardableResult
    func tapClean() -> Self {
        clean.tap()
        agree.tap()
        return self
    }

    @discardableResult
    func checkHistoryWithElements() -> Self {
        XCTAssertTrue(cellsCount > 0)
        return self
    }
    
    @discardableResult
    func checkHistoryEmpty() -> Self {
        XCTAssertTrue(cellsCount == 0)
        return self
    }
}
