import XCTest
import WMFData
import WMFDataMocks
import WMFDataTestSupport
@testable import WMFComponents

@MainActor
final class WMFSemanticSearchResultsViewModelTests: XCTestCase {

    private let fixture = WMFDataTestFixture()
    private let project = WMFProject.wikipedia(WMFLanguage(languageCode: "fr", languageVariantCode: nil))

    override func setUp() async throws {
        try await super.setUp()
        await fixture.setUp()
    }

    override func tearDown() async throws {
        await fixture.tearDown()
        try await super.tearDown()
    }

    /// Configures the service, then resets the shared data controllers, in the same order as
    /// `WMFDataTestFixture.withConfiguredEnvironment`.
    private func makeViewModel(service: WMFService?, opened: (@MainActor @Sendable (WMFSemanticSearchResult) -> Void)? = nil, closed: (@MainActor @Sendable () -> Void)? = nil) async -> WMFSemanticSearchResultsViewModel {
        WMFDataEnvironment.current.basicService = service
        await fixture.resetWMFDataTestState()
        return WMFSemanticSearchResultsViewModel(
            query: "qu'est-ce que la communication",
            project: project,
            readInArticleAction: { opened?($0) },
            closeAction: { closed?() })
    }

    private func waitUntilLoaded(_ viewModel: WMFSemanticSearchResultsViewModel) async {
        for _ in 0..<50 where viewModel.state == .loading {
            try? await Task.sleep(for: .milliseconds(20))
        }
    }

    func testLoadShowsTheResultsInRankOrder() async {
        let viewModel = await makeViewModel(service: WMFMockBasicService())

        viewModel.load()
        await waitUntilLoaded(viewModel)

        XCTAssertEqual(viewModel.state, .results)
        XCTAssertEqual(viewModel.results.map(\.result.title), ["Complexité de la communication", "Communication", "Communication animale"])
        XCTAssertEqual(viewModel.languageCode, "fr")
    }

    func testResultRowsParseTheSnippet() async {
        let viewModel = await makeViewModel(service: WMFMockBasicService())

        viewModel.load()
        await waitUntilLoaded(viewModel)

        let first = viewModel.results[0]
        XCTAssertTrue(first.passageText.hasPrefix("La complexité de la communication"))
        let passage = NSAttributedString(first.attributedPassage(font: .systemFont(ofSize: 16), textColor: .black, highlightColor: .yellow, highlightTextColor: .black, linkColor: .blue))
        var highlightRuns = 0
        passage.enumerateAttribute(.backgroundColor, in: NSRange(location: 0, length: passage.length)) { value, _, _ in
            if value != nil { highlightRuns += 1 }
        }
        XCTAssertEqual(highlightRuns, 1)
        XCTAssertEqual(first.articlePath, "Complexité de la communication")
        XCTAssertEqual(viewModel.results[2].articlePath, "Communication animale | Différence entre communication et information")
    }

    func testRateLimitBecomesItsOwnErrorState() async {
        let viewModel = await makeViewModel(service: WMFMockFailingService(statusCode: 429))

        viewModel.load()
        await waitUntilLoaded(viewModel)

        guard case .error(let errorViewModel) = viewModel.state else {
            return XCTFail("Expected the error state, got \(viewModel.state)")
        }
        XCTAssertEqual(errorViewModel.localizedStrings.title, viewModel.rateLimitedErrorTitle)
        XCTAssertEqual(errorViewModel.localizedStrings.buttonTitle, viewModel.retryTitle)
    }

    func testMissingServiceIsAGeneralError() async {
        let viewModel = await makeViewModel(service: nil)

        viewModel.load()
        await waitUntilLoaded(viewModel)

        guard case .error(let errorViewModel) = viewModel.state else {
            return XCTFail("Expected the error state, got \(viewModel.state)")
        }
        XCTAssertEqual(errorViewModel.localizedStrings.title, viewModel.generalErrorTitle)
    }

    func testResultsAreCappedAtEight() async {
        let viewModel = await makeViewModel(service: WMFMockBasicService())

        viewModel.load()
        await waitUntilLoaded(viewModel)
        XCTAssertEqual(viewModel.results.count, 3)

        // The mock answers every page with the same three results and a next offset.
        for expectedCount in [6, 8] {
            viewModel.loadMoreIfNeeded(after: viewModel.results[viewModel.results.count - 1])
            for _ in 0..<50 where viewModel.isLoadingMore {
                try? await Task.sleep(for: .milliseconds(20))
            }
            XCTAssertEqual(viewModel.results.count, expectedCount)
        }

        viewModel.loadMoreIfNeeded(after: viewModel.results[7])
        XCTAssertFalse(viewModel.isLoadingMore, "Nothing loads past the cap.")
        XCTAssertEqual(viewModel.results.count, WMFSemanticSearchResultsViewModel.maximumResultCount)
    }

    func testCancelKeepsTheLoadingState() async {
        let viewModel = await makeViewModel(service: WMFMockBasicService())

        viewModel.load()
        viewModel.cancel()
        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertEqual(viewModel.state, .loading)
        XCTAssertTrue(viewModel.results.isEmpty)
    }

    func testActionsForwardTheResultAndTheClose() async {
        var opened: [String] = []
        var closeCount = 0
        let viewModel = await makeViewModel(service: WMFMockBasicService(), opened: { opened.append($0.title) }, closed: { closeCount += 1 })

        viewModel.load()
        await waitUntilLoaded(viewModel)
        viewModel.results[1].readInArticle()
        viewModel.close()

        XCTAssertEqual(opened, ["Communication"])
        XCTAssertEqual(closeCount, 1)
    }
}

private final class WMFMockFailingService: WMFService {

    private let statusCode: Int

    init(statusCode: Int) {
        self.statusCode = statusCode
    }

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<Data, any Error>) -> Void) {
        completion(.failure(WMFServiceError.invalidHttpResponse(statusCode)))
    }

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<[String: Any]?, Error>) -> Void) {
        completion(.failure(WMFServiceError.invalidHttpResponse(statusCode)))
    }

    func performDecodableGET<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        completion(.failure(WMFServiceError.invalidHttpResponse(statusCode)))
    }

    func performDecodablePOST<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        completion(.failure(WMFServiceError.invalidHttpResponse(statusCode)))
    }

    func clearCachedData() {}
}
