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

    func testFeaturedContentDecodingToleratesMissingViewHistory() throws {
        // Regression test: the feed API omits view_history for some most-read
        // articles (typically newly trending ones). Decoding must not fail for
        // the whole payload — it previously broke the Featured Article,
        // Picture of the Day, and Top Read widgets together.
        let data = try XCTUnwrap(wmf_bundle().wmf_data(fromContentsOfFile: "FeedDayResponseMissingViewHistory", ofType: "json"))

        let content = try JSONDecoder().decode(WidgetFeaturedContent.self, from: data)

        XCTAssertNotNil(content.featuredArticle, "Today's featured article should decode despite a mostread article without view_history")
        XCTAssertNotNil(content.pictureOfTheDay, "Picture of the day should decode despite a mostread article without view_history")
        let articles = try XCTUnwrap(content.topRead?.elements)
        XCTAssertEqual(articles.count, 2)
        XCTAssertNotNil(articles[0].viewHistory)
        XCTAssertNotNil(articles[0].views)
        XCTAssertNil(articles[1].viewHistory, "article without view_history should decode with nil history")
    }
}
