import XCTest

class WidgetSampleContentTests: XCTestCase {

	func testFeaturedArticleWidgetSampleContentDecoding() throws {
		let sampleContent = WidgetFeaturedContent.previewContent()

		// Confirm JSON payload decodes correctly
		XCTAssertNotNil(sampleContent, "Could not decode Featured Article Widget sample content JSON")

		// Confirm content for display is available
		XCTAssertNotNil(sampleContent?.featuredArticle?.displayTitle, "Featured Article Widget sample display title unavailable")
		XCTAssertNotNil(sampleContent?.featuredArticle?.thumbnailImageSource?.data, "Featured Article Widget sample image unavailable")
		XCTAssertNotNil(sampleContent?.featuredArticle?.contentURL.desktop.page, "Featured Article Widget sample content URL unavailable")
		XCTAssertNotNil(sampleContent?.featuredArticle?.extract, "Featured Article Widget sample extract unavailable")
		XCTAssertNotNil(sampleContent?.featuredArticle?.description, "Featured Article Widget sample description unavailable")
	}

}
