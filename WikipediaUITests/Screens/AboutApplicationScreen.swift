import XCTest

final class AboutApplicationScreen: BaseScreen {
    
    private lazy var settingsButton: XCUIElement = app.buttons["Настройки"]
    private lazy var about: XCUIElement = app.staticTexts["О приложении"]
    private lazy var authors: XCUIElement = app.staticTexts["Авторы"]
    private lazy var translators: XCUIElement = app.staticTexts["Переводчики"]
    private lazy var license: XCUIElement = app.staticTexts["Лицензия содержимого"]
    
    @discardableResult
    func tapSettingsButton1() -> Self {
        settingsButton.tap()
        return self
    }
    
    @discardableResult
    func tapAbout() -> Self {
        about.tap()
        return self
    }
    
    @discardableResult
    func checkAuthors() -> Self {
        XCTAssertTrue(authors.isHittable)
        return self
    }
    
    @discardableResult
    func checkTranslators() -> Self {
        while (!translators.isHittable){
            app.swipeUp()
        }
        XCTAssertTrue(translators.isHittable)
        return self
    }
    
    @discardableResult
    func checkLicense() -> Self {
        while (!license.isHittable){
            app.swipeUp()
        }
        XCTAssertTrue(license.isHittable)
        return self
    }
}

