import XCTest

/// Provides screenshot capture to robots that expose the shared UITestRobot primitive.
protocol ScreenshotCapturingRobot {
    var base: UITestRobot { get }
}

// MARK: - Shared screen actions

extension ScreenshotCapturingRobot {
    @discardableResult
    func captureScreenshot(_ screenshot: any RawRepresentable<String>) -> Self {
        base.captureScreenshot(named: screenshot.rawValue)
        return self
    }

    @discardableResult
    func rotateToLandscapeLeft() -> Self {
        base.rotateToLandscapeLeft()
        return self
    }

    @discardableResult
    func rotateToPortrait() -> Self {
        base.rotateToPortrait()
        return self
    }
}

/// Shared primitive used by screen robots for common waits, taps, gestures, screenshots, and failure reporting.
struct UITestRobot {
    static let systemBackButtonIdentifier = "BackButton"

    let app: XCUIApplication
    private let testCase: XCTestCase

    init(app: XCUIApplication, testCase: XCTestCase) {
        self.app = app
        self.testCase = testCase
    }
}

// MARK: - Assertions

extension UITestRobot {
    @discardableResult
    func assertExists(
        _ element: XCUIElement,
        timeout: TimeInterval = 5,
        description: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        XCTAssertTrue(
            element.waitForExistence(timeout: timeout),
            "Expected \(description ?? Self.describe(element)) to exist within \(timeout) seconds.",
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func assertVisible(
        _ element: XCUIElement,
        timeout: TimeInterval = 5,
        description: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let predicate = NSPredicate(format: "exists == true && hittable == true")
        let expectation = testCase.expectation(for: predicate, evaluatedWith: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(
            result,
            .completed,
            "Expected \(description ?? Self.describe(element)) to be visible within \(timeout) seconds.",
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func assertSelected(
        _ element: XCUIElement,
        timeout: TimeInterval = 5,
        description: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let predicate = NSPredicate(format: "selected == true")
        let expectation = testCase.expectation(for: predicate, evaluatedWith: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(
            result,
            .completed,
            "Expected \(description ?? Self.describe(element)) to be selected within \(timeout) seconds.",
            file: file,
            line: line
        )
        return self
    }
}

// MARK: - Element resolution

extension UITestRobot {
    func firstHittableElement(
        matching query: XCUIElementQuery,
        timeout: TimeInterval = 15,
        description: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        var hittableElement: XCUIElement?
        let predicate = NSPredicate { _, _ in
            hittableElement = query.allElementsBoundByIndex.first { element in
                element.exists && element.isHittable
            }
            return hittableElement != nil
        }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(
            result,
            .completed,
            "Expected \(description) to be visible within \(timeout) seconds.",
            file: file,
            line: line
        )
        return hittableElement ?? query.firstMatch
    }
}

// MARK: - Actions

extension UITestRobot {
    @discardableResult
    func tapButton(
        withIdentifier identifier: String,
        timeout: TimeInterval = 15,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let button = app.buttons.matching(identifier: identifier).firstMatch
        assertVisible(
            button,
            timeout: timeout,
            description: "button with identifier '\(identifier)'",
            file: file,
            line: line
        )
        button.tap()
        return self
    }
}

// MARK: - Gestures

extension UITestRobot {
    @discardableResult
    func tapCenter(
        of element: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        XCTAssertFalse(
            element.frame.isEmpty,
            "Expected \(Self.describe(element)) to have a tappable frame.",
            file: file,
            line: line
        )
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        return self
    }

    @discardableResult
    func dragUp(_ element: XCUIElement) -> Self {
        let start = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85))
        let end = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        start.press(forDuration: 0.01, thenDragTo: end)
        return self
    }

    @discardableResult
    func dragDown(_ element: XCUIElement) -> Self {
        let start = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        let end = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85))
        start.press(forDuration: 0.01, thenDragTo: end)
        return self
    }
}

// MARK: - Device orientation

extension UITestRobot {
    @discardableResult
    func rotateToLandscapeLeft() -> Self {
        XCUIDevice.shared.orientation = .landscapeLeft
        return self
    }

    @discardableResult
    func rotateToPortrait() -> Self {
        XCUIDevice.shared.orientation = .portrait
        return self
    }
}

// MARK: - Navigation

extension UITestRobot {
    func backButton(in navigationBar: XCUIElement, isRightToLeft: Bool) -> XCUIElement {
        let systemBackButton = navigationBar.buttons.matching(identifier: Self.systemBackButtonIdentifier).firstMatch
        if systemBackButton.exists {
            return systemBackButton
        }

        let buttons = navigationBar.buttons.allElementsBoundByIndex
            .filter { $0.exists && !$0.frame.isEmpty }
            .sorted { $0.frame.midX < $1.frame.midX }

        // Some simulator versions do not expose the system back button identifier.
        // Select the visually leading navigation-bar button instead of relying on query order.
        return (isRightToLeft ? buttons.last : buttons.first) ?? navigationBar.buttons.firstMatch
    }
}

// MARK: - Waiting and screenshots

extension UITestRobot {
    @discardableResult
    func waitForElementToDisappear(
        _ element: XCUIElement,
        timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = testCase.expectation(for: predicate, evaluatedWith: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(
            result,
            .completed,
            "Expected \(Self.describe(element)) to disappear within \(timeout) seconds.",
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func captureScreenshot(named name: String) -> Self {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        testCase.add(attachment)
        return self
    }
}

// MARK: - Private helpers

private extension UITestRobot {
    static func describe(_ element: XCUIElement) -> String {
        if !element.identifier.isEmpty {
            return "element with identifier '\(element.identifier)'"
        }

        return String(describing: element)
    }
}
