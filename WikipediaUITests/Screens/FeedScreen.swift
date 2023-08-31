import XCTest

final class FeedScreen: BaseScreen {
    
    private lazy var settingsButton: XCUIElement = app.buttons["Настройки"]
    private lazy var search: XCUIElement = app.tabBars.buttons["Поиск"]
    private lazy var readingContinue: XCUIElement = app.collectionViews.cells.staticTexts["Продолжить чтение"]
    private lazy var topReadButton: XCUIElement = app.staticTexts["Самые читаемые"]
    
    @discardableResult
    func tapSettingsButton() -> Self {
        settingsButton.tap()
        return self
    }
    
    @discardableResult
    func tapReadingContinue() -> Self {
        readingContinue.tap()
        return self
    }
    
    @discardableResult
    func tapTopRead() -> Self {
        while (!topReadButton.isHittable){
            app.swipeUp(velocity: 5000)
        }
        topReadButton.tap()
        return self
    }
    
    @discardableResult
    func swipeToContinue() -> Self {
        while (!readingContinue.isHittable){
            app.swipeUp()
        }
        return self
    }
    
    @discardableResult
    func checkSettingsButtonIsHittable() -> Self {
        XCTAssertTrue(settingsButton.isHittable)
        return self
    }
}
