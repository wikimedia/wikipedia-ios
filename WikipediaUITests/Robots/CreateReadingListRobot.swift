import XCTest
import WMFComponents

/// Represents the "Create a new list" form.
struct CreateReadingListRobot: ScreenshotCapturingRobot {
    let base: UITestRobot
    let configuration: UITestConfiguration
}

extension CreateReadingListRobot {
    @discardableResult
    func assertVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(formView, timeout: 15, description: "create reading list form", file: file, line: line)
        base.assertExists(nameTextField, timeout: 15, description: "reading list name field", file: file, line: line)
        return self
    }

    @discardableResult
    func assertDismissed(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.waitForElementToDisappear(formView, timeout: 10, file: file, line: line)
        return self
    }

    @discardableResult
    func assertCreateButtonEnabled(_ isEnabled: Bool, file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(createButton, timeout: 5, description: "create reading list button", file: file, line: line)
        let predicate = NSPredicate(format: "enabled == %@", NSNumber(value: isEnabled))
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: createButton)
        XCTAssertEqual(
            XCTWaiter.wait(for: [expectation], timeout: 5),
            .completed,
            "Expected the create reading list button enabled == \(isEnabled).",
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func assertNameErrorVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(
            base.app.staticTexts[AccessibilityIdentifiers.CreateReadingList.nameErrorLabel],
            timeout: 5,
            description: "reading list name error",
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func typeName(_ name: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertVisible(nameTextField, timeout: 10, description: "reading list name field", file: file, line: line)
        nameTextField.tap()
        nameTextField.typeText(name)
        return self
    }

    @discardableResult
    func typeDescription(_ description: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        let field = base.app.textFields[AccessibilityIdentifiers.CreateReadingList.descriptionTextField]
        base.assertVisible(field, timeout: 10, description: "reading list description field", file: file, line: line)
        field.tap()
        field.typeText(description)
        return self
    }

    @discardableResult
    func tapCreate(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.tapButton(withIdentifier: AccessibilityIdentifiers.CreateReadingList.createButton, timeout: 10, file: file, line: line)
        return self
    }

    @discardableResult
    func close(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.tapButton(withIdentifier: AccessibilityIdentifiers.CreateReadingList.closeButton, timeout: 10, file: file, line: line)
        return assertDismissed(file: file, line: line)
    }
}

private extension CreateReadingListRobot {
    var formView: XCUIElement {
        base.app.otherElements[AccessibilityIdentifiers.CreateReadingList.view]
    }

    var nameTextField: XCUIElement {
        base.app.textFields[AccessibilityIdentifiers.CreateReadingList.nameTextField]
    }

    var createButton: XCUIElement {
        base.app.buttons[AccessibilityIdentifiers.CreateReadingList.createButton]
    }
}
