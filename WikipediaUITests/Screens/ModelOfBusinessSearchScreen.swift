import XCTest

final class ModelOfBusinessSearchScreen: BaseScreen {
    
    private lazy var contentButton: XCUIElement = app.toolbars.buttons["Содержание"]
    private lazy var modelOfBusiness: XCUIElement = app.tables.staticTexts["Модель бизнеса"]
    private lazy var isFocusedModel: XCUIElement = app.otherElements.staticTexts["Модель бизнеса"]
    
    @discardableResult
    func tapContent() -> Self {
        contentButton.tap()
        return self
    }
    
    @discardableResult
    func tapModelOfBusiness() -> Self {
        modelOfBusiness.tap()
        return self
    }
    
    @discardableResult
    func checkModelOfBusinessPage() -> Self {
        XCTAssertTrue(isFocusedModel.hasFocus)
        return self
    }
}
