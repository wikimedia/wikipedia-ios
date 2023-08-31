import XCTest

final class TopReadScreen: BaseScreen {
    
    private lazy var cellsCount = app.collectionViews.cells.count
    
    @discardableResult
    func checkTopReadScreen() -> Self {
        print(cellsCount)
        XCTAssertTrue(cellsCount > 5)
        return self
    }
}
