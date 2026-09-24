import XCTest
import WebKit
@testable import WMF

/// Covers `window.wmf.findInPage.highlightPassages` in `assets/index.js`, which highlights the
/// passages of a semantic search result inside the article.
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

    private func highlight(_ passages: [String], anchor: String?) async throws -> [String] {
        let passagesJSON = try XCTUnwrap(String(data: JSONEncoder().encode(passages), encoding: .utf8))
        let anchorJS = anchor.map { "`\($0)`" } ?? "null"
        let result = try await webView.evaluateJavaScript("window.wmf.findInPage.highlightPassages(\(passagesJSON), \(anchorJS))")
        return try XCTUnwrap(result as? [String])
    }

    private func evaluate<T>(_ script: String) async throws -> T {
        let result = try await webView.evaluateJavaScript(script)
        return try XCTUnwrap(result as? T)
    }

    func testPassageSpanningALinkIsHighlightedInOneRun() async throws {
        let ids = try await highlight(["transmission de l'information est un processus"], anchor: "Définition")

        XCTAssertEqual(ids.count, 3, "One span per text node the passage crosses: the link, the text after it, the text after the reference marker.")
        let highlightedText: String = try await evaluate("[...document.querySelectorAll('.findInPageMatch')].map(span => span.textContent).join('').replace(/\\s+/g, ' ')")
        XCTAssertEqual(highlightedText, "transmission de l’information est un processus")
        let linkText: String = try await evaluate("document.querySelector('a[href=\"./Transmission\"]').textContent")
        XCTAssertEqual(linkText, "transmission", "The link keeps its text and now wraps a highlight span.")
        let spansInsideLinks: Int = try await evaluate("document.querySelectorAll('a .findInPageMatch[data-passage]').length")
        XCTAssertEqual(spansInsideLinks, 1)
        let spansInsideMarkers: Int = try await evaluate("document.querySelectorAll('sup.mw-ref .findInPageMatch').length")
        XCTAssertEqual(spansInsideMarkers, 0, "Reference markers are skipped, not highlighted.")
        let spansInOtherSection: Int = try await evaluate("document.querySelectorAll('section[data-mw-section-id=\"2\"] .findInPageMatch').length")
        XCTAssertEqual(spansInOtherSection, 0, "Only the section of the anchor is searched when it contains the passage.")
    }

    func testFallsBackToTheWholeArticleWhenTheSectionDoesNotHaveThePassage() async throws {
        let ids = try await highlight(["processus complexe aussi"], anchor: "Définition")

        XCTAssertEqual(ids.count, 1)
        let spansInOtherSection: Int = try await evaluate("document.querySelectorAll('section[data-mw-section-id=\"2\"] .findInPageMatch').length")
        XCTAssertEqual(spansInOtherSection, 1)
    }

    func testMissingAnchorSearchesTheWholeArticle() async throws {
        let ids = try await highlight(["processus complexe aussi"], anchor: "Not_there")

        XCTAssertEqual(ids.count, 1)
    }

    func testPassageThatIsNotInTheArticleHighlightsNothing() async throws {
        let ids = try await highlight(["ce texte a été supprimé"], anchor: "Définition")

        XCTAssertEqual(ids, [])
        let spans: Int = try await evaluate("document.querySelectorAll('.findInPageMatch').length")
        XCTAssertEqual(spans, 0)
    }

    func testInvisibleCharactersDoNotBreakTheMatch() async throws {
        let ids = try await highlight(["information invisible"], anchor: "Notes")

        XCTAssertEqual(ids.count, 1)
        let highlightedText: String = try await evaluate("document.querySelector('.findInPageMatch').textContent")
        XCTAssertEqual(highlightedText, "in\u{00AD}for\u{200B}mation \u{200F}invisible", "The article keeps its characters; only the comparison ignores them.")
    }

    func testANewCallReplacesThePreviousHighlight() async throws {
        _ = try await highlight(["est un processus"], anchor: "Définition")
        let ids = try await highlight(["processus complexe aussi"], anchor: "Histoire")

        XCTAssertEqual(ids.count, 1)
        let spans: Int = try await evaluate("document.querySelectorAll('.findInPageMatch').length")
        XCTAssertEqual(spans, 1)
        let paragraph: String = try await evaluate("document.querySelector('section[data-mw-section-id=\"1\"] p').textContent.replace(/\\s+/g, ' ')")
        XCTAssertEqual(paragraph, "La transmission de l’information[3] est un processus complexe.", "The text of the first section is back in one piece.")
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
