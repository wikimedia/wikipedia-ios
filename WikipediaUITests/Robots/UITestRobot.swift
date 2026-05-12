import XCTest

/// Provides screenshot capture to robots that expose the shared UITestRobot primitive.
protocol ScreenshotCapturingRobot {
    var base: UITestRobot { get }
}

extension ScreenshotCapturingRobot {
    @discardableResult
    func captureScreenshot(_ screenshot: any RawRepresentable<String>) -> Self {
        base.captureScreenshot(named: screenshot.rawValue)
        return self
    }
}

/// Shared primitive used by screen robots for common waits, taps, screenshots, and failure reporting.
struct UITestRobot {
    let app: XCUIApplication
    private let testCase: XCTestCase

    init(app: XCUIApplication, testCase: XCTestCase) {
        self.app = app
        self.testCase = testCase
    }

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
    func tapButton(
        withIdentifier identifier: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let button = app.buttons.matching(identifier: identifier).firstMatch
        assertExists(
            button,
            description: "button with identifier '\(identifier)'",
            file: file,
            line: line
        )
        button.tap()
        return self
    }

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

    private static func describe(_ element: XCUIElement) -> String {
        if !element.identifier.isEmpty {
            return "element with identifier '\(element.identifier)'"
        }

        return String(describing: element)
    }
}
