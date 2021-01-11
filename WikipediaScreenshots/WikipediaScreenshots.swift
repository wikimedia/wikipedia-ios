    
import XCTest

class WikipediaScreenshots: XCTestCase {
    
    let app = XCUIApplication()

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        app.launch()
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        app.terminate()
    }

    func testScreenshotOnboarding() throws {
        
        let suffix = currentLanguage != nil ? "-\(currentLanguage!)" : ""
        
        let introDescriptionLabel = app.staticTexts.element(matching: .any, identifier: AccessibilityIdentifiers.onboardingIntroDescriptionLabel.rawValue)
        XCTAssertTrue(introDescriptionLabel.waitForExistence(timeout: 5))
        attachScreenshot(name: "onboarding-page-1\(suffix)")
        introDescriptionLabel.swipeLeft()
        
        let exploreDescriptionLabel = app.staticTexts.element(matching: .any, identifier: AccessibilityIdentifiers.onboardingExploreDescriptionLabel.rawValue)
        XCTAssertTrue(exploreDescriptionLabel.waitForExistence(timeout: 5))
        attachScreenshot(name: "onboarding-page-2\(suffix)")
        exploreDescriptionLabel.swipeLeft()
        
        let languageDescriptionLabel = app.staticTexts.element(matching: .any, identifier: AccessibilityIdentifiers.onboardingLanguageDescriptionLabel.rawValue)
        XCTAssertTrue(languageDescriptionLabel.waitForExistence(timeout: 5))
        attachScreenshot(name: "onboarding-page-3\(suffix)")
        languageDescriptionLabel.swipeLeft()
        
        let analyticsDescriptionLabel = app.staticTexts.element(matching: .any, identifier: AccessibilityIdentifiers.onboardingAnalyticsDescriptionLabel.rawValue)
        XCTAssertTrue(analyticsDescriptionLabel.waitForExistence(timeout: 5))
        attachScreenshot(name: "onboarding-page-4\(suffix)")
    }
}

private extension WikipediaScreenshots {
    
    private var currentLanguage: String? {
        let currentLocale = Locale(identifier: Locale.preferredLanguages.first!)
        guard let langCode = currentLocale.languageCode else {
            return nil
        }
        var localeCode = langCode
        if let scriptCode = currentLocale.scriptCode {
            localeCode = "\(langCode)-\(scriptCode)"
        } else if let regionCode = currentLocale.regionCode {
            localeCode = "\(langCode)-\(regionCode)"
        }
        return localeCode
    }
    
    private func attachScreenshot(name: String) {
        let screenshot = app.windows.firstMatch.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
