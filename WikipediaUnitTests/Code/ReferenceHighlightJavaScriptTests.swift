import XCTest
import WebKit
@testable import Wikipedia

@MainActor
final class ReferenceHighlightJavaScriptTests: XCTestCase {

    private let html = """
    <html><head><title>Article</title></head><body>
    <sup id="cite_ref-x&#39;);document.title=&#39;NEWTITLE&#39;;//_1-0" class="reference">[1]</sup>
    <sup id="cite_ref-Smith2020_3-1" class="reference">[2]</sup>
    </body></html>
    """

    // Keep the delegate alive: WKWebView holds navigationDelegate weakly.
    private var waiter: NavigationWaiter?

    private func loadedWebView() async throws -> WKWebView {
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let waiter = NavigationWaiter()
        self.waiter = waiter
        let loaded = expectation(description: "HTML loaded")
        waiter.onDone = { loaded.fulfill() }
        webView.navigationDelegate = waiter
        // A nil base URL: the injected JS needs no origin, and nothing loads from the network.
        webView.loadHTMLString(html, baseURL: nil)
        await fulfillment(of: [loaded], timeout: 10)
        if let error = waiter.error { throw error }
        return webView
    }

    func testRefIdDoesNotExecute() async throws {
        let webView = try await loadedWebView()
        webView.wmf_highlightLinkID("cite_ref-x');document.title='NEWTITLE';//_1-0")
        try await Task.sleep(nanoseconds: 300_000_000)
        let title = try await webView.evaluateJavaScript("document.title") as? String
        XCTAssertEqual(title, "Article")
    }

    func testPositiveControlHighlightStillWorks() async throws {
        let webView = try await loadedWebView()
        webView.wmf_highlightLinkID("cite_ref-Smith2020_3-1")
        try await Task.sleep(nanoseconds: 300_000_000)
        let has = try await webView.evaluateJavaScript("document.getElementById('cite_ref-Smith2020_3-1').classList.contains('reference-highlight')") as? Bool
        XCTAssertEqual(has, true)
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
