import XCTest
@testable import WMF

/// The feed API omits keys instead of sending null, and one missing key used to take every widget
/// down at once (2026-09-17: `image.description` absent on en). These tests pin the contract that
/// sections decode independently and that a bad element is dropped, not the whole section.
class WidgetFeedResilienceTests: XCTestCase {

    // MARK: - Real payloads

    func testImageWithoutDescriptionDecodesEverySection() throws {
        let data = try XCTUnwrap(wmf_bundle().wmf_data(fromContentsOfFile: "FeedDayResponseMissingImageDescription", ofType: "json"))

        let content = try JSONDecoder().decode(WidgetFeaturedContent.self, from: data)

        XCTAssertNotNil(content.featuredArticle)
        XCTAssertNotNil(content.topRead)
        XCTAssertEqual(content.topRead?.elements.count, 3)
        XCTAssertEqual(content.onThisDay?.count, 2)
        let pictureOfTheDay = try XCTUnwrap(content.pictureOfTheDay)
        XCTAssertNil(pictureOfTheDay.description, "the 2026-09-17 payload has no description; it must decode as nil, not fail")
        XCTAssertEqual(pictureOfTheDay.caption(preferringLanguageCode: "en"), "Buddhist śramaṇas performing the traditional lamp-lighting ritual on Prabarana Purnima", "the structured caption stands in for the missing description")
        XCTAssertEqual(pictureOfTheDay.license?.code, "cc-by-sa-4.0")
        XCTAssertTrue(content.sectionDecodingErrors.isEmpty, "\(content.sectionDecodingErrors)")
        XCTAssertTrue(content.droppedElementErrors.isEmpty, "\(content.droppedElementErrors)")
    }

    // MARK: - Section isolation

    func testMalformedSectionIsIsolated() throws {
        // `image` is a string instead of an object, `onthisday` an object instead of an array.
        let json = """
        {
          "tfa": \(featuredArticleJSON),
          "mostread": {"date": "2026-09-16Z", "articles": [\(articleJSON(title: "A", views: 10))]},
          "image": "not an object",
          "onthisday": {"text": "wrong shape"}
        }
        """

        let content = try JSONDecoder().decode(WidgetFeaturedContent.self, from: Data(json.utf8))

        XCTAssertNotNil(content.featuredArticle, "a broken image section must not break the featured article")
        XCTAssertEqual(content.topRead?.elements.count, 1, "a broken image section must not break the top read")
        XCTAssertNil(content.pictureOfTheDay)
        XCTAssertNil(content.onThisDay)
        XCTAssertEqual(Set(content.sectionDecodingErrors.keys), [.pictureOfTheDay, .onThisDay])
        XCTAssertTrue(try XCTUnwrap(content.sectionDecodingErrors[.pictureOfTheDay]).contains("image"), "the error should name the JSON path")
    }

    func testMissingRequiredKeyInsideSectionOnlyDropsThatSection() throws {
        // `tfa` without `content_urls`, which the widget cannot render without.
        let json = """
        {
          "tfa": {"displaytitle": "No link", "lang": "en"},
          "mostread": {"date": "2026-09-16Z", "articles": [\(articleJSON(title: "A", views: 10))]}
        }
        """

        let content = try JSONDecoder().decode(WidgetFeaturedContent.self, from: Data(json.utf8))

        XCTAssertNil(content.featuredArticle)
        XCTAssertEqual(content.topRead?.elements.count, 1)
        XCTAssertEqual(content.sectionDecodingErrors[.featuredArticle], "missing key 'content_urls' at tfa")
    }

    // MARK: - Lossy arrays

    func testTopReadDropsOnlyTheArticleThatFailsToDecode() throws {
        let json = """
        {"date": "2026-09-16Z", "articles": [
          \(articleJSON(title: "First", views: 30)),
          {"displaytitle": "No views, no link"},
          \(articleJSON(title: "Third", views: 10))
        ]}
        """

        let topRead = try JSONDecoder().decode(WidgetTopRead.self, from: Data(json.utf8))

        XCTAssertEqual(topRead.elements.map { $0.displayTitle }, ["First", "Third"])
        XCTAssertEqual(topRead.droppedElementErrors.count, 1)
        XCTAssertTrue(try XCTUnwrap(topRead.droppedElementErrors.first).hasPrefix("[1] missing key"), "\(topRead.droppedElementErrors)")
    }

    func testTopReadDroppedElementsSurfaceOnTheContent() throws {
        let json = """
        {"mostread": {"date": "2026-09-16Z", "articles": [\(articleJSON(title: "A", views: 10)), {"views": "ten"}]}}
        """

        let content = try JSONDecoder().decode(WidgetFeaturedContent.self, from: Data(json.utf8))

        XCTAssertEqual(content.topRead?.elements.count, 1)
        XCTAssertEqual(content.droppedElementErrors[.topRead]?.count, 1)
    }

    func testOnThisDayDropsOnlyTheEventThatFailsToDecode() throws {
        let json = """
        {"onthisday": [
          {"text": "Good event", "year": 1990, "pages": []},
          {"text": "No year"},
          {"text": "Bad page is dropped, event kept", "year": 2001, "pages": [{"displaytitle": "No link"}]}
        ]}
        """

        let content = try JSONDecoder().decode(WidgetFeaturedContent.self, from: Data(json.utf8))

        XCTAssertEqual(content.onThisDay?.map { $0.text }, ["Good event", "Bad page is dropped, event kept"])
        XCTAssertEqual(content.onThisDay?.last?.pages.count, 0)
        XCTAssertEqual(content.droppedElementErrors[.onThisDay]?.count, 1)
    }

    // MARK: - Picture of the day caption

    func testCaptionPrefersDescriptionThenLanguageThenEnglishThenAny() throws {
        let withDescription = try pictureOfTheDay(description: "From the feed", captions: ["de": "Deutsch", "en": "English"])
        XCTAssertEqual(withDescription.caption(preferringLanguageCode: "de"), "From the feed")

        let withoutDescription = try pictureOfTheDay(description: nil, captions: ["de": "Deutsch", "en": "English", "pt": "Português"])
        XCTAssertEqual(withoutDescription.caption(preferringLanguageCode: "de"), "Deutsch")
        XCTAssertEqual(withoutDescription.caption(preferringLanguageCode: "ja"), "English", "falls back to English when the wiki language has no caption")
        XCTAssertEqual(withoutDescription.caption(preferringLanguageCode: nil), "English")

        let onlyOther = try pictureOfTheDay(description: nil, captions: ["zh-hant": "白冠雞", "de": "Bleßhuhn"])
        XCTAssertEqual(onlyOther.caption(preferringLanguageCode: "en"), "Bleßhuhn", "any caption beats none, in a stable order")

        let nothing = try pictureOfTheDay(description: nil, captions: nil)
        XCTAssertNil(nothing.caption(preferringLanguageCode: "en"))
    }

    // MARK: - Optional fields the widgets do not need

    func testArticleWithoutExtractAndTimestampStillDecodes() throws {
        let json = """
        {"views": 5, "displaytitle": "Bare", "content_urls": {"desktop": {"page": "https://en.wikipedia.org/wiki/Bare"}}}
        """

        let article = try JSONDecoder().decode(WidgetTopRead.Article.self, from: Data(json.utf8))

        XCTAssertEqual(article.displayTitle, "Bare")
        XCTAssertNil(article.extract)
        XCTAssertNil(article.timestamp)
        XCTAssertFalse(article.isRTL, "no direction means left to right")
    }

    // MARK: - Cache merge and stale sections

    func testMergingCarriesOverMissingSectionsAndMarksThemStale() throws {
        let cached = try JSONDecoder().decode(WidgetFeaturedContent.self, from: Data("""
        {"tfa": \(featuredArticleJSON), "image": \(pictureOfTheDayJSON), "mostread": {"date": "2026-09-15Z", "articles": []}}
        """.utf8))
        let fresh = try JSONDecoder().decode(WidgetFeaturedContent.self, from: Data("""
        {"mostread": {"date": "2026-09-16Z", "articles": []}}
        """.utf8))

        let merged = WidgetFeaturedContent.merging(fresh: fresh, withCached: cached)

        XCTAssertEqual(merged.topRead?.dateString, "2026-09-16Z", "fresh sections win")
        XCTAssertNotNil(merged.featuredArticle)
        XCTAssertNotNil(merged.pictureOfTheDay)
        XCTAssertEqual(Set(merged.staleSections), [.featuredArticle, .pictureOfTheDay])
        XCTAssertTrue(merged.isStale(.featuredArticle))
        XCTAssertFalse(merged.isStale(.topRead))
    }

    func testMergingWithoutCacheChangesNothing() throws {
        let fresh = try JSONDecoder().decode(WidgetFeaturedContent.self, from: Data("{\"tfa\": \(featuredArticleJSON)}".utf8))

        let merged = WidgetFeaturedContent.merging(fresh: fresh, withCached: nil)

        XCTAssertTrue(merged.staleSections.isEmpty)
        XCTAssertNotNil(merged.featuredArticle)
    }

    func testStaleSectionsSurviveTheCacheRoundTripButRuntimeFlagsDoNot() throws {
        var content = try JSONDecoder().decode(WidgetFeaturedContent.self, from: Data("{\"tfa\": \(featuredArticleJSON), \"image\": \"broken\"}".utf8))
        content.staleSections = [.featuredArticle]
        content.isFromCacheFallback = true
        content.featuredArticle?.isFromCacheFallback = true
        XCTAssertFalse(content.sectionDecodingErrors.isEmpty)

        let roundTripped = try JSONDecoder().decode(WidgetFeaturedContent.self, from: JSONEncoder().encode(content))

        XCTAssertEqual(roundTripped.staleSections, [.featuredArticle], "stale sections are part of the cache")
        XCTAssertFalse(roundTripped.isFromCacheFallback, "fallback flag is runtime-only")
        XCTAssertEqual(roundTripped.featuredArticle?.isFromCacheFallback, false, "fallback flag is runtime-only")
        XCTAssertTrue(roundTripped.sectionDecodingErrors.isEmpty, "decoding errors are runtime-only")
    }

    // MARK: - Diagnostics

    func testDiagnosticsDescribePartialSuccess() throws {
        let content = try JSONDecoder().decode(WidgetFeaturedContent.self, from: Data("""
        {"tfa": \(featuredArticleJSON), "image": "broken", "mostread": {"date": "2026-09-16Z", "articles": [{"views": 1}]}}
        """.utf8))

        let diagnostics = WidgetFetchDiagnostics(date: Date(), url: "https://en.wikipedia.org/api/rest_v1/feed/featured/2026/09/17", httpStatusCode: 200, content: content)

        XCTAssertEqual(diagnostics.outcome, .partialSuccess)
        XCTAssertEqual(diagnostics.decodedSections, ["tfa", "mostread"])
        XCTAssertEqual(diagnostics.sectionErrors.keys.sorted(), ["image"])
        XCTAssertEqual(diagnostics.droppedElementErrors["mostread"]?.count, 1)
        XCTAssertTrue(diagnostics.summaryLines.contains { $0.hasPrefix("image: ") })

        let roundTripped = try JSONDecoder().decode(WidgetFetchDiagnostics.self, from: JSONEncoder().encode(diagnostics))
        XCTAssertEqual(roundTripped.outcome, .partialSuccess)
    }

    func testDiagnosticsDescribeCleanSuccess() throws {
        let content = try JSONDecoder().decode(WidgetFeaturedContent.self, from: Data("{\"tfa\": \(featuredArticleJSON)}".utf8))

        let diagnostics = WidgetFetchDiagnostics(date: Date(), url: "https://example.org", httpStatusCode: 200, content: content)

        XCTAssertEqual(diagnostics.outcome, .success)
        XCTAssertEqual(diagnostics.decodedSections, ["tfa"])
    }

    // MARK: - Helpers

    private var featuredArticleJSON: String {
        return """
        {"displaytitle": "Featured", "lang": "en", "dir": "ltr", "extract": "Text", "content_urls": {"desktop": {"page": "https://en.wikipedia.org/wiki/Featured"}}}
        """
    }

    private var pictureOfTheDayJSON: String {
        return """
        {"title": "File:Example.jpg", "thumbnail": {"source": "https://upload.wikimedia.org/a.jpg", "width": 10, "height": 10}}
        """
    }

    private func pictureOfTheDay(description: String?, captions: [String: String]?) throws -> WidgetPictureOfTheDay {
        var object: [String: Any] = ["title": "File:Example.jpg"]
        if let description = description {
            object["description"] = ["text": description, "html": description, "lang": "en"]
        }
        if let captions = captions {
            object["structured"] = ["captions": captions]
        }
        let data = try JSONSerialization.data(withJSONObject: object)
        return try JSONDecoder().decode(WidgetPictureOfTheDay.self, from: data)
    }

    private func articleJSON(title: String, views: Int) -> String {
        return """
        {"views": \(views), "displaytitle": "\(title)", "content_urls": {"desktop": {"page": "https://en.wikipedia.org/wiki/\(title)"}}}
        """
    }
}
