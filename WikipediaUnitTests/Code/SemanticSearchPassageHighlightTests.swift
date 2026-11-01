import XCTest
import WebKit
@testable import WMF

/// Covers `window.wmf.utilities.whenSectionsAreShown` in `assets/index.js`, which the semantic
/// search waits for before it highlights a passage. The passage matching itself is
/// `pcs.c1.Highlight` in the Page Content Service, and is tested there.
@MainActor
final class SemanticSearchPassageHighlightTests: XCTestCase {

    private static let articleHTML = """
    <section data-mw-section-id="1"><h2 id="Définition">Définition</h2>
    <p>La <a href="./Transmission">transmission</a> de l’information<sup class="mw-ref" id="cite_ref-3"><a href="#cite_note-3">[3]</a></sup> est un
      processus <b>complexe</b>.</p></section>
    <section data-mw-section-id="2"><h2 id="Histoire">Histoire</h2>
    <p>La transmission de l'information est un processus complexe aussi.</p></section>
    <section data-mw-section-id="3"><h2 id="Notes">Notes</h2>
    <p>Une in\u{00AD}for\u{200B}mation \u{200F}invisible.</p></section>
    """

    private var webView: WKWebView!
    private var navigationDelegate: LoadDelegate!

    override func setUp() async throws {
        try await super.setUp()
        let scriptURL = try XCTUnwrap(Bundle.wmf.url(forResource: "index", withExtension: "js", subdirectory: "assets"))
        let script = try String(contentsOf: scriptURL, encoding: .utf8)
        let html = "<html><body>\(Self.articleHTML)<script>\(script)</script></body></html>"

        navigationDelegate = LoadDelegate()
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        webView.navigationDelegate = navigationDelegate
        webView.loadHTMLString(html, baseURL: nil)
        await navigationDelegate.waitForLoad()
    }

    override func tearDown() async throws {
        webView = nil
        navigationDelegate = nil
        try await super.tearDown()
    }

    private func callAsync<T>(_ functionBody: String) async throws -> T {
        let result = try await webView.callAsyncJavaScript(functionBody, contentWorld: .page)
        return try XCTUnwrap(result as? T)
    }

    // MARK: - whenSectionsAreShown

    func testResolvesRightAwayWhenTheSectionsAreShown() async throws {
        let resolved: Bool = try await callAsync("await window.wmf.utilities.whenSectionsAreShown(); return true")

        XCTAssertTrue(resolved)
    }

    func testWaitsForTheSectionsToBeShown() async throws {
        let heights: [Double] = try await callAsync("""
        const section = document.getElementById('Histoire').closest('section')
        section.style.minHeight = '2000px'
        section.style.display = 'none'
        const promise = window.wmf.utilities.whenSectionsAreShown()
        const heightWhileHidden = document.documentElement.scrollHeight
        section.style.display = ''
        window.dispatchEvent(new CustomEvent('onBodyEnd'))
        await promise
        return [heightWhileHidden, document.documentElement.scrollHeight]
        """)

        XCTAssertEqual(heights.count, 2)
        XCTAssertLessThan(heights[0], 2000, "While the section is hidden, the page is as tall as the view.")
        XCTAssertGreaterThanOrEqual(heights[1], 2000, "The promise resolves once the sections are shown.")
    }
}

private final class LoadDelegate: NSObject, WKNavigationDelegate {

    private var continuation: CheckedContinuation<Void, Never>?
    private var didLoad = false

    func waitForLoad() async {
        if didLoad { return }
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        didLoad = true
        continuation?.resume()
        continuation = nil
    }
}
