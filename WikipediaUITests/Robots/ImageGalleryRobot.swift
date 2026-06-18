import XCTest
import WMFComponents

/// Represents the full-screen image gallery.
struct ImageGalleryRobot: ScreenshotCapturingRobot {
    let base: UITestRobot
}

// MARK: - Screen state

extension ImageGalleryRobot {
    @discardableResult
    func assertVisible(timeout: TimeInterval = 15, file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(
            base.app.otherElements[AccessibilityIdentifiers.ImageGallery.view],
            timeout: timeout,
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func assertImagePresented(file: StaticString = #filePath, line: UInt = #line) -> Self {
        let unexpectedServerError = base.app.alerts.staticTexts["The app received an unexpected response from the server. Please try again later."]
        XCTAssertFalse(
            unexpectedServerError.waitForExistence(timeout: 2),
            "Expected image gallery not to present the unexpected-response server error.",
            file: file,
            line: line
        )

        let image = base.app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.ImageGallery.image)
            .firstMatch
        base.assertExists(image, timeout: 30, description: "image gallery image", file: file, line: line)
        base.waitForElementToDisappear(
            loadingIndicator,
            timeout: 30,
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func assertShareButtonEnabled(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertVisible(
            shareButton,
            timeout: 15,
            description: "image gallery share button",
            file: file,
            line: line
        )
        XCTAssertTrue(
            shareButton.isEnabled,
            "Expected image gallery share button to be enabled before tapping.",
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func assertAppRunning(file: StaticString = #filePath, line: UInt = #line) -> Self {
        XCTAssertNotEqual(
            base.app.state,
            .notRunning,
            "Expected tapping share not to crash the app.",
            file: file,
            line: line
        )
        return self
    }
}

// MARK: - Actions

extension ImageGalleryRobot {
    @discardableResult
    func tapShareButton(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertVisible(
            shareButton,
            timeout: 15,
            description: "image gallery share button",
            file: file,
            line: line
        )
        shareButton.tap()
        return self
    }
}

// MARK: - Private helpers

private extension ImageGalleryRobot {
    private var loadingIndicator: XCUIElement {
        base.app.activityIndicators[AccessibilityIdentifiers.ImageGallery.loadingIndicator]
    }

    private var shareButton: XCUIElement {
        base.app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.ImageGallery.shareButton)
            .firstMatch
    }
}
