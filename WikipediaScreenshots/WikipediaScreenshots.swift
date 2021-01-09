    
import XCTest

class WikipediaScreenshots: XCTestCase {
    
    let app = XCUIApplication()

    override func setUpWithError() throws {
        
        continueAfterFailure = false
        app.launch()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        app.terminate()
    }

    func testExample() throws {
        // UI tests must launch the application that they test.
        
        let descriptionLabel = app.staticTexts.element(matching: .any, identifier: AccessilibilityIdentifiers.onboardingIntroDescriptionText.rawValue)
        
        XCTAssertTrue(descriptionLabel.waitForExistence(timeout: 5))
        
        let suffix = currentLanguage != nil ? "-\(currentLanguage!.localeCode)-\(currentLanguage!.langCode)" : ""
        attachScreenshot(name: "onboarding-page-1\(suffix)")

        descriptionLabel.swipeLeft()
 
        attachScreenshot(name: "onboarding-page-2\(suffix)")
    }
}

private extension WikipediaScreenshots {
    
    private var currentLanguage: (langCode: String, localeCode: String)? {
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
        return (langCode, localeCode)
    }
    
    private func attachScreenshot(name: String) {
        let screenshot = app.windows.firstMatch.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
