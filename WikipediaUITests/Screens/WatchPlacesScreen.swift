import XCTest

final class WatchPlacesScreen: BaseScreen {
    
    private lazy var locationButton: XCUIElement = app.buttons["Показать ваше положение в центре карты"]
    private lazy var switchOnLocationButton: XCUIElement = app.buttons["switch on"]
    
    @discardableResult
    func tapLocationButton() -> Self {
        locationButton.tap()
        return self
    }
    
    @discardableResult
    func checkSwitchOnLocationButton() -> Self {
        XCTAssertTrue(switchOnLocationButton.isHittable)
        return self
    }
}
