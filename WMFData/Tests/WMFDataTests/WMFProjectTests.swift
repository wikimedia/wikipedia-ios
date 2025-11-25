import XCTest
@testable import WMFData

final class WMFProjectTests: XCTestCase {
    
    override func setUp() async throws {
        
    }
    
    func testTranslatedHelperLinks() throws {
        let language = WMFLanguage(languageCode: "es", languageVariantCode: nil)
        let url = WMFProject.mediawiki.translatedHelpURL(pathComponents: ["Wikimedia Apps", "Wikipedia Year in Review", "Frequently Asked Questions"], section: "Frequently asked questions", language: language)
        XCTAssertEqual(url?.absoluteString, "https://www.mediawiki.org/wiki/Special:MyLanguage/Wikimedia_Apps/Wikipedia_Year_in_Review/Frequently_Asked_Questions?uselang=es#Frequently_asked_questions")
    }
}
