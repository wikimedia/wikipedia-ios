import XCTest

final class WKSourceEditorUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testSourceEditorInputViewSwitching() throws {
        let app = XCUIApplication()
        app.launchArguments += ProcessInfo().arguments
        app.launch()

        let entryButton = app.buttons["Source Editor Entry Button"]
        entryButton.tap()

        let textView = app.textViews["Source Editor TextView"]
        textView.tap()
        textView.typeText("Hello World!")

        XCTAssertFalse(app.isDisplayingInputView)
        XCTAssertTrue(app.isDisplayingExpandingToolbar)
        XCTAssertFalse(app.isDisplayingHighlightingToolbar)
        XCTAssertFalse(app.isDisplayingFindAndReplaceToolbar)

        let initialAttachment = XCTAttachment(screenshot: app.screenshot())
        initialAttachment.name = ScreenshotNames.initial.rawValue
        add(initialAttachment)

        textView.doubleTap()

        XCTAssertFalse(app.isDisplayingInputView)
        XCTAssertFalse(app.isDisplayingExpandingToolbar)
        XCTAssertTrue(app.isDisplayingHighlightingToolbar)
        XCTAssertFalse(app.isDisplayingFindAndReplaceToolbar)

        let highlightAttachment = XCTAttachment(screenshot: app.screenshot())
        highlightAttachment.name = ScreenshotNames.highlighted.rawValue
        add(highlightAttachment)

        app.buttons["Source Editor Show More Button"].tap()

        XCTAssertTrue(app.isDisplayingInputView)
        XCTAssertFalse(app.isDisplayingExpandingToolbar)
        XCTAssertFalse(app.isDisplayingHighlightingToolbar)
        XCTAssertFalse(app.isDisplayingFindAndReplaceToolbar)

        app.buttons["Source Editor Close Button"].tap()

        textView.typeText("Adding text to remove selection.")

        app.buttons["Source Editor Format Text Button"].tap()

        XCTAssertTrue(app.isDisplayingInputView)
        XCTAssertFalse(app.isDisplayingExpandingToolbar)
        XCTAssertFalse(app.isDisplayingHighlightingToolbar)
        XCTAssertFalse(app.isDisplayingFindAndReplaceToolbar)

        let mainInputViewAttachment = XCTAttachment(screenshot: app.screenshot())
        mainInputViewAttachment.name = ScreenshotNames.main.rawValue
        add(mainInputViewAttachment)

        app.buttons["Source Editor Close Button"].tap()

        app.buttons["Source Editor Find Button"].tap()

        let findAttachment = XCTAttachment(screenshot: app.screenshot())
        findAttachment.name = ScreenshotNames.find.rawValue
        add(findAttachment)
    }
}

extension XCUIApplication {
    var isDisplayingExpandingToolbar: Bool {
        return otherElements["Source Editor Expanding Toolbar"].exists
    }

    var isDisplayingHighlightingToolbar: Bool {
        return otherElements["Source Editor Highlight Toolbar"].exists
    }

    var isDisplayingFindAndReplaceToolbar: Bool {
        return otherElements["Source Editor Find Toolbar"].exists
    }

    var isDisplayingInputView: Bool {
        return otherElements[ "Source Editor Input View"].exists
    }
}

private enum ScreenshotNames: String {
    case initial = "Source Editor Initial"
    case highlighted = "Source Editor Highlighted"
    case main = "Source Editor Main Input View 1"
    case headerSelect1 = "Source Editor Header Select Input View 1"
    case headerSelect2 = "Source Editor Header Select Input View 2"
    case find = "Source Editor Find"
}
