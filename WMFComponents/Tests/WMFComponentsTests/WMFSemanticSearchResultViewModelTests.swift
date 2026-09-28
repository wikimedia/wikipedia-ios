import XCTest
import WMFData
import WMFDataTestSupport
@testable import WMFComponents

@MainActor
final class WMFSemanticSearchResultViewModelTests: XCTestCase {

    private let fixture = WMFDataTestFixture()
    private let localizedStrings = WMFSemanticSearchResultViewModel.LocalizedStrings(
        readInArticleTitle: "Read in article",
        contributorsFormat: "%1$d contributors",
        referencesFormat: "%1$d references",
        lastUpdatedFormat: "Last update %1$@")

    override func setUp() async throws {
        try await super.setUp()
        await fixture.setUp()
    }

    override func tearDown() async throws {
        await fixture.tearDown()
        try await super.tearDown()
    }

    private func makeResult(snippetHTML: String = "a <span class=\"searchmatch\">match</span> here", sectionTitle: String? = nil, thumbnailURL: URL? = nil) -> WMFSemanticSearchResult {
        WMFSemanticSearchResult(pageID: 1, title: "Communication", snippetHTML: snippetHTML, sectionTitle: sectionTitle, redirectTitle: nil, thumbnailURL: thumbnailURL)
    }

    private func makeViewModel(result: WMFSemanticSearchResult? = nil, languageCode: String = "fr", readInArticleAction: @escaping @MainActor @Sendable (WMFSemanticSearchResult) -> Void = { _ in }) -> WMFSemanticSearchResultViewModel {
        WMFSemanticSearchResultViewModel(
            result: result ?? makeResult(),
            project: .wikipedia(WMFLanguage(languageCode: languageCode, languageVariantCode: nil)),
            localizedStrings: localizedStrings,
            readInArticleAction: readInArticleAction)
    }

    /// Configures the service, then resets the shared data controllers, in the same order as
    /// `WMFDataTestFixture.withConfiguredEnvironment`.
    private func loadDetails(of viewModel: WMFSemanticSearchResultViewModel, with service: WMFMockAttributionService) async {
        WMFDataEnvironment.current.basicService = service
        await fixture.resetWMFDataTestState()

        viewModel.loadDetailsIfNeeded()
        for _ in 0..<50 where viewModel.attribution == nil {
            try? await Task.sleep(for: .milliseconds(20))
        }
    }

    // MARK: - Presentation

    func testQuotationMarkFollowsTheSearchLanguage() {
        XCTAssertEqual(makeViewModel(languageCode: "fr").quotationMark, "«")
        XCTAssertEqual(makeViewModel(languageCode: "ar").quotationMark, "❝")
        XCTAssertEqual(makeViewModel(languageCode: "ja").quotationMark, "『")
        XCTAssertEqual(makeViewModel(languageCode: "en").quotationMark, "❝", "Other languages use the default mark.")
    }

    func testLayoutDirectionFollowsTheSearchLanguage() {
        XCTAssertTrue(makeViewModel(languageCode: "ar").isRightToLeft)
        XCTAssertFalse(makeViewModel(languageCode: "fr").isRightToLeft)
    }

    func testArticlePathJoinsTheTitleAndTheSection() {
        XCTAssertEqual(makeViewModel(result: makeResult(sectionTitle: nil)).articlePath, "Communication")
        XCTAssertEqual(makeViewModel(result: makeResult(sectionTitle: "")).articlePath, "Communication")
        XCTAssertEqual(makeViewModel(result: makeResult(sectionTitle: "Histoire")).articlePath, "Communication | Histoire")
    }

    func testPassageTextIsThePlainSnippet() {
        let viewModel = makeViewModel(result: makeResult(snippetHTML: "l&#039;<span class=\"searchmatch\">Union</span>  <a href=\"/wiki/X\">européenne</a>"))

        XCTAssertEqual(viewModel.passageText, "l'Union européenne")
    }

    func testAttributedPassageHighlightsTheMatch() {
        let viewModel = makeViewModel()

        let passage = NSAttributedString(viewModel.attributedPassage(font: .systemFont(ofSize: 16), textColor: .black, highlightColor: .yellow, highlightTextColor: .darkGray, linkColor: .blue))

        XCTAssertEqual(passage.string, "a match here")
        var highlightRange = NSRange()
        XCTAssertEqual(passage.attribute(.backgroundColor, at: 2, effectiveRange: &highlightRange) as? UIColor, .yellow)
        XCTAssertEqual(highlightRange, NSRange(location: 2, length: 5))
        XCTAssertEqual(passage.attribute(.foregroundColor, at: 2, effectiveRange: nil) as? UIColor, .darkGray)
        XCTAssertEqual(passage.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor, .black)
    }

    func testPassageShowsLinksAsAnIndicationOnly() {
        let html = "the <span class=\"searchmatch\"><a href=\"/wiki/Transmission\">transmission</a> of information</span>: a <a href=\"/wiki/Message\">message</a>.<sup><a href=\"#cite_note-3\">[3]</a></sup>"
        let viewModel = makeViewModel(result: makeResult(snippetHTML: html))
        let font = UIFont.systemFont(ofSize: 16)
        let (text, highlightText, highlight, link) = (UIColor.black, UIColor.darkGray, UIColor.yellow, UIColor.blue)

        let passage = NSAttributedString(viewModel.attributedPassage(font: font, textColor: text, highlightColor: highlight, highlightTextColor: highlightText, linkColor: link))

        XCTAssertEqual(passage.string, "the transmission of information: a message.[3]")
        XCTAssertNil(passage.attribute(.link, at: 4, effectiveRange: nil), "Links are an indication only, not tappable.")
        XCTAssertEqual(passage.attribute(.foregroundColor, at: 4, effectiveRange: nil) as? UIColor, highlightText, "Inside the highlight the link keeps the highlight text color.")
        XCTAssertEqual(passage.attribute(.underlineStyle, at: 4, effectiveRange: nil) as? Int, NSUnderlineStyle.single.rawValue, "Inside the highlight the link is underlined.")
        XCTAssertEqual(passage.attribute(.foregroundColor, at: 35, effectiveRange: nil) as? UIColor, link, "Outside the highlight the link is in the link color.")
        XCTAssertNil(passage.attribute(.underlineStyle, at: 35, effectiveRange: nil))
        XCTAssertEqual(passage.attribute(.foregroundColor, at: 43, effectiveRange: nil) as? UIColor, text, "Reference markers stay in the text color.")
        XCTAssertLessThan((passage.attribute(.font, at: 43, effectiveRange: nil) as? UIFont)?.pointSize ?? 100, font.pointSize)
    }

    func testQuotationMarkImageFitsTheAscenderAndIsCached() {
        let viewModel = makeViewModel()
        let font = UIFont.systemFont(ofSize: 16)

        let image = viewModel.quotationMarkImage(font: font, color: .black)

        XCTAssertEqual(image.size.height, font.ascender, accuracy: 0.5, "The renderer rounds the size to the pixel grid.")
        XCTAssertGreaterThan(image.size.width, 0)
        XCTAssertTrue(viewModel.quotationMarkImage(font: font, color: .black) === image, "The same font and color reuse the image.")
        XCTAssertFalse(viewModel.quotationMarkImage(font: font, color: .red) === image)
    }

    // MARK: - Actions

    func testReadInArticleForwardsTheResult() {
        var opened: [WMFSemanticSearchResult] = []
        let result = makeResult()
        let viewModel = makeViewModel(result: result, readInArticleAction: { opened.append($0) })

        viewModel.readInArticle()

        XCTAssertEqual(opened, [result])
    }

    // MARK: - Details

    func testLoadDetailsFillsTheAttributionAndTheThumbnail() async {
        let thumbnailURL = URL(string: "https://upload.wikimedia.org/thumb.png")!
        let viewModel = makeViewModel(result: makeResult(thumbnailURL: thumbnailURL))
        let service = WMFMockAttributionService(contributorCount: 12, referenceCount: 2, lastUpdated: "2026-09-03T06:29:36Z", imageData: Self.onePixelPNG)

        await loadDetails(of: viewModel, with: service)

        XCTAssertEqual(viewModel.attribution, WMFSemanticSearchAttribution(contributorCount: 12, referenceCount: 2, lastUpdated: ISO8601DateFormatter().date(from: "2026-09-03T06:29:36Z")))
        XCTAssertEqual(viewModel.contributorsText, "12 contributors")
        XCTAssertEqual(viewModel.referencesText, "2 references")
        XCTAssertNil(viewModel.lastUpdatedText, "The date shows only where the reference count is missing.")
        XCTAssertNotNil(viewModel.thumbnail)
    }

    func testLastUpdatedShowsOnlyWithoutReferences() async {
        let viewModel = makeViewModel()
        let service = WMFMockAttributionService(contributorCount: nil, referenceCount: nil, lastUpdated: "2026-09-03T06:29:36Z", imageData: nil)
        let date = ISO8601DateFormatter().date(from: "2026-09-03T06:29:36Z")!

        await loadDetails(of: viewModel, with: service)

        XCTAssertNil(viewModel.contributorsText)
        XCTAssertNil(viewModel.referencesText)
        XCTAssertEqual(viewModel.lastUpdatedText, "Last update \(DateFormatter.monthYearNumericFormatter.string(from: date))")
        XCTAssertFalse(viewModel.lastUpdatedText?.contains("03") ?? true, "Only the month and the year show, not the day.")
        XCTAssertEqual(viewModel.lastUpdatedAccessibilityText, "Last update \(DateFormatter.monthYearSpelledOutFormatter.string(from: date))")
        XCTAssertNil(viewModel.thumbnail, "No thumbnail URL, no request.")
    }

    func testLoadDetailsRequestsOnce() async {
        let viewModel = makeViewModel()
        let service = WMFMockAttributionService(contributorCount: 1, referenceCount: 1, lastUpdated: nil, imageData: nil)

        await loadDetails(of: viewModel, with: service)
        viewModel.loadDetailsIfNeeded()
        try? await Task.sleep(for: .milliseconds(50))

        XCTAssertEqual(service.attributionRequestCount, 1)
    }

    private static let onePixelPNG: Data = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).pngData { context in
        UIColor.black.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
    }
}

/// Answers the attribution request with the given signals and any other request with `imageData`.
private final class WMFMockAttributionService: WMFService {

    private let contributorCount: Int?
    private let referenceCount: Int?
    private let lastUpdated: String?
    private let imageData: Data?
    private let lock = NSLock()
    private var _attributionRequestCount = 0

    var attributionRequestCount: Int {
        lock.withLock { _attributionRequestCount }
    }

    init(contributorCount: Int?, referenceCount: Int?, lastUpdated: String?, imageData: Data?) {
        self.contributorCount = contributorCount
        self.referenceCount = referenceCount
        self.lastUpdated = lastUpdated
        self.imageData = imageData
    }

    private var attributionJSON: Data {
        let signals: [String: Any] = [
            "contributor_counts": contributorCount ?? NSNull(),
            "reference_count": referenceCount ?? NSNull(),
            "last_updated": lastUpdated ?? NSNull()
        ]
        return try! JSONSerialization.data(withJSONObject: ["trust_and_relevance": signals])
    }

    private func isAttributionRequest<R: WMFServiceRequest>(_ request: R) -> Bool {
        request.url?.path.contains("/attribution/") == true
    }

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<Data, any Error>) -> Void) {
        if let imageData, !isAttributionRequest(request) {
            completion(.success(imageData))
        } else {
            completion(.failure(URLError(.fileDoesNotExist)))
        }
    }

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<[String: Any]?, Error>) -> Void) {
        completion(.failure(URLError(.unsupportedURL)))
    }

    func performDecodableGET<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        guard isAttributionRequest(request) else {
            return completion(.failure(URLError(.unsupportedURL)))
        }
        lock.withLock { _attributionRequestCount += 1 }
        completion(Result { try JSONDecoder().decode(T.self, from: attributionJSON) })
    }

    func performDecodablePOST<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        completion(.failure(URLError(.unsupportedURL)))
    }

    func clearCachedData() {}
}
