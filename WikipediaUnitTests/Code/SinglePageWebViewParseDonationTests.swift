import XCTest

@testable import Wikipedia

class SinglePageWebViewControllerTests: XCTestCase {

    func testParseThankYouURL_WithAllParametersIncludingRecurring() {
        let urlString = "https://thankyou.wikipedia.org/wiki/Thank_You/en?amount=1.00&country=US&currency=USD&order_id=218642670.1&payment_method=apple&recurring&wmf_medium=WikipediaApp&wmf_source=app_2023_en6C_iOS_control.app.apple&wmf_campaign=iOS"
        guard let url = URL(string: urlString) else {
            XCTFail("Failed to create URL from string")
            return
        }

        let theme = Theme.standard
        let viewController = SinglePageWebViewController(url: url, theme: theme)

        let result = viewController.parseThankYouURL(url)

        XCTAssertEqual(result?.amount, "1.00", "Amount should be 1.00")
        XCTAssertEqual(result?.country, "US", "Country should be US")
        XCTAssertEqual(result?.currency, "USD", "Currency should be USD")
        XCTAssertTrue(((result?.isRecurring) != nil), "isRecurring should be true")
    }

    func testParseThankYouURL_WithoutRecurring() {
        let urlString = "https://thankyou.wikipedia.org/wiki/Thank_You/en?amount=1.00&country=US&currency=USD&order_id=218642670.1&payment_method=apple&wmf_medium=WikipediaApp&wmf_source=app_2023_en6C_iOS_control.app.apple&wmf_campaign=iOS"
        guard let url = URL(string: urlString) else {
            XCTFail("Failed to create URL from string")
            return
        }

        let theme = Theme.standard
        let viewController = SinglePageWebViewController(url: url, theme: theme)

        let result = viewController.parseThankYouURL(url)

        XCTAssertEqual(result?.amount, "1.00", "Amount should be 1.00")
        XCTAssertEqual(result?.country, "US", "Country should be US")
        XCTAssertEqual(result?.currency, "USD", "Currency should be USD")
        XCTAssertFalse(((result?.isRecurring) == nil), "isRecurring should be false")
    }

    func testParseThankYouURL_WithMissingParameters() {
        let urlString = "https://thankyou.wikipedia.org/wiki/Thank_You"
        guard let url = URL(string: urlString) else {
            XCTFail("Failed to create URL from string")
            return
        }

        let theme = Theme.standard
        let viewController = SinglePageWebViewController(url: url, theme: theme)

        let result = viewController.parseThankYouURL(url)

        XCTAssertNil(result?.amount, "Amount should be nil")
        XCTAssertEqual(result?.country, nil, "Country should be nil")
        XCTAssertNil(result?.currency, "Currency should be nil")
        XCTAssertFalse(((result?.isRecurring) != nil), "isRecurring should be false")
    }
}
