import XCTest
import WebKit
@testable import Wikipedia

/// Covers `ArticleWebMessagingController.prepareForScrollToAnchorScript`, which checks that the
/// page has the anchor before it asks the Page Content Service to scroll to it. The Page Content
/// Service does nothing for an anchor that is not in the page, so the check is what lets the
/// article show up when a link points to a section that does not exist.
@MainActor
final class ScrollToAnchorPreparationTests: XCTestCase {

    private static let pageContentServiceStub = """
    <script>
    window.pcs = { c1: { Page: { prepareForScrollToAnchor: (anchor, options) => {
        window.preparedAnchor = anchor
        window.preparedHighlight = options.highlight
    } } } }
    </script>
    """

    // The second id is stored encoded, like `HTMLUtilities.encodeUnsafeId` of the Page Content Service stores it.
    private static let sections = """
    <section><h2 id="História">História</h2></section>
    <section><h2 id="Côte_d%27Ivoire">Côte d'Ivoire</h2></section>
    """

    // Keep the delegate alive: WKWebView holds navigationDelegate weakly.
    private var waiter: NavigationWaiter?

    private func loadedWebView(withPageContentService: Bool = true) async throws -> WKWebView {
        let html = "<html><head><title>Article</title></head><body>\(Self.sections)\(withPageContentService ? Self.pageContentServiceStub : "")</body></html>"
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let waiter = NavigationWaiter()
        self.waiter = waiter
        let loaded = expectation(description: "HTML loaded")
        waiter.onDone = { loaded.fulfill() }
        webView.navigationDelegate = waiter
        webView.loadHTMLString(html, baseURL: nil)
        await fulfillment(of: [loaded], timeout: 10)
        if let error = waiter.error { throw error }
        return webView
    }

    private func prepareForScroll(to anchor: String, in webView: WKWebView) async -> Result<Void, Error> {
        await withCheckedContinuation { continuation in
            let arguments: [String: Any] = ["anchor": anchor, "highlight": true]
            webView.callAsyncJavaScript(ArticleWebMessagingController.prepareForScrollToAnchorScript, arguments: arguments, in: nil, in: .page) { result in
                continuation.resume(returning: ArticleWebMessagingController.scrollToAnchorPreparationResult(of: result))
            }
        }
    }

    func testAnchorInThePageIsPrepared() async throws {
        let webView = try await loadedWebView()
        let result = await prepareForScroll(to: "História", in: webView)
        guard case .success = result else {
            return XCTFail("Expected a success, got \(result)")
        }
        let preparedAnchor = try await webView.evaluateJavaScript("window.preparedAnchor") as? String
        XCTAssertEqual(preparedAnchor, "História")
        let preparedHighlight = try await webView.evaluateJavaScript("window.preparedHighlight") as? Bool
        XCTAssertEqual(preparedHighlight, true)
    }

    func testAnchorStoredEncodedIsPrepared() async throws {
        let webView = try await loadedWebView()
        let result = await prepareForScroll(to: "Côte_d'Ivoire", in: webView)
        guard case .success = result else {
            return XCTFail("Expected a success, got \(result)")
        }
        // The Page Content Service gets the anchor as it is. It encodes the id itself.
        let preparedAnchor = try await webView.evaluateJavaScript("window.preparedAnchor") as? String
        XCTAssertEqual(preparedAnchor, "Côte_d'Ivoire")
    }

    func testAnchorNotInThePageIsNotFound() async throws {
        let webView = try await loadedWebView()
        let result = await prepareForScroll(to: "Secao_que_nao_existe", in: webView)
        guard case .failure(let error as ArticleWebMessagingController.ScrollToAnchorPreparationError) = result else {
            return XCTFail("Expected anchorNotFound, got \(result)")
        }
        XCTAssertEqual(error, .anchorNotFound)
        let preparedAnchor = try await webView.evaluateJavaScript("window.preparedAnchor === undefined") as? Bool
        XCTAssertEqual(preparedAnchor, true, "The Page Content Service must not be called for an anchor that is not in the page.")
    }

    func testMissingPageScriptFailsWithoutNotFound() async throws {
        let webView = try await loadedWebView(withPageContentService: false)
        let result = await prepareForScroll(to: "História", in: webView)
        guard case .failure(let error) = result else {
            return XCTFail("Expected a failure, got \(result)")
        }
        XCTAssertFalse(error is ArticleWebMessagingController.ScrollToAnchorPreparationError, "A page script that is not ready is a retryable failure, not a missing anchor.")
    }

    func testLoadingPageIsRetryable() {
        let result = ArticleWebMessagingController.scrollToAnchorPreparationResult(of: .success("loading"))
        guard case .failure(let error as ArticleWebMessagingController.ScrollToAnchorPreparationError) = result else {
            return XCTFail("Expected pageIsLoading, got \(result)")
        }
        XCTAssertEqual(error, .pageIsLoading)
    }
}

@MainActor
private final class NavigationWaiter: NSObject, WKNavigationDelegate {
    var onDone: (() -> Void)?
    private(set) var error: Error?
    private func finish(_ error: Error?) {
        self.error = error
        onDone?()
        onDone = nil
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { finish(nil) }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { finish(error) }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { finish(error) }
}
