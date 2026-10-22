import XCTest
import WMFComponents

/// Represents the "Add to reading list" / "Move to reading list" sheet.
struct AddToReadingListRobot: ScreenshotCapturingRobot {
    let base: UITestRobot
    let configuration: UITestConfiguration
}

extension AddToReadingListRobot {
    @discardableResult
    func assertVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(sheetView, timeout: 15, description: "add to reading list sheet", file: file, line: line)
        return self
    }

    @discardableResult
    func assertDismissed(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.waitForElementToDisappear(sheetView, timeout: 10, file: file, line: line)
        return self
    }

    @discardableResult
    func assertReadingListVisible(_ name: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(readingListCell(name), timeout: 15, description: "reading list cell '\(name)' in sheet", file: file, line: line)
        return self
    }

    @discardableResult
    func assertReadingListAbsent(_ name: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        assertVisible(file: file, line: line)
        XCTAssertFalse(readingListCell(name).exists, "Expected reading list '\(name)' to be left out of the sheet.", file: file, line: line)
        return self
    }

    /// Taps a list. The sheet dismisses on its own after the articles are added.
    @discardableResult
    func chooseReadingList(_ name: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        let cell = readingListCell(name)
        base.assertVisible(cell, timeout: 15, description: "reading list cell '\(name)' in sheet", file: file, line: line)
        cell.tap()
        return self
    }

    @discardableResult
    func createNewList(file: StaticString = #filePath, line: UInt = #line) -> CreateReadingListRobot {
        base.tapButton(withIdentifier: AccessibilityIdentifiers.AddToReadingList.createNewListButton, timeout: 10, file: file, line: line)
        return CreateReadingListRobot(base: base, configuration: configuration).assertVisible(file: file, line: line)
    }

    /// Creates a list from the sheet's button. The articles land in the new list and the form
    /// dismisses. The legacy sheet then stays open, because its own dismissal is requested while
    /// the form is still animating away; close it when that happens.
    @discardableResult
    func createNewList(named name: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        createNewList(file: file, line: line)
            .typeName(name, file: file, line: line)
            .tapCreate(file: file, line: line)
            .assertDismissed(file: file, line: line)
        if sheetView.waitForNonExistence(timeout: 3) {
            return self
        }
        return close(file: file, line: line)
    }

    @discardableResult
    func close(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.tapButton(withIdentifier: AccessibilityIdentifiers.AddToReadingList.closeButton, timeout: 10, file: file, line: line)
        return assertDismissed(file: file, line: line)
    }
}

private extension AddToReadingListRobot {
    var sheetView: XCUIElement {
        base.app.otherElements[AccessibilityIdentifiers.AddToReadingList.view]
    }

    func readingListCell(_ name: String) -> XCUIElement {
        sheetView.descendants(matching: .any).matching(identifier: AccessibilityIdentifiers.Saved.readingListCell(name)).firstMatch
    }
}
