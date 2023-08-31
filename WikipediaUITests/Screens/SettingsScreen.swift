import XCTest

final class SettingsScreen: BaseScreen {
    
    private lazy var title: XCUIElement = app.toolbars.staticTexts["Настройки"]
    private lazy var closeButton: XCUIElement = app.buttons["Закрыть"]
    private lazy var supportWiki: XCUIElement = app.staticTexts["Поддержать Википедию"]
    
    @discardableResult
    func tapSupportWiki() -> Self {
        supportWiki.tap()
        return self
    }
    
    @discardableResult
    func tapCloseButton() -> Self {
        closeButton.tap()
        return self
    }

    @discardableResult
    func checkTitleIsHittable() -> Self {
        XCTAssertTrue(title.isHittable)
        return self
    }

}
