import SwiftUI
import WebKit

/// Hosts the WikiRun web game and translates its bridge messages into view model calls.
struct WMFWikiRunWebView: UIViewRepresentable {

    @ObservedObject var viewModel: WMFWikiRunViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    func makeUIView(context: Context) -> WKWebView {
        let userContentController = WKUserContentController()
        userContentController.add(context.coordinator, name: Coordinator.messageHandlerName)
        userContentController.addUserScript(WKUserScript(
            source: "window.__wikiRunEmbed = true;",
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        ))

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        configuration.applicationNameForUserAgent = "WikipediaApp"

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        // CSS cannot stop the scroll view itself from rubber-banding.
        webView.scrollView.bounces = false
#if DEBUG
        webView.isInspectable = true
#endif
        context.coordinator.webView = webView
        webView.load(URLRequest(url: viewModel.gameURL))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.pushDarkModeIfNeeded(viewModel.isDarkMode)
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        // The web view retains its message handlers, so release ours here to break that cycle.
        webView.configuration.userContentController.removeScriptMessageHandler(forName: Coordinator.messageHandlerName)
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
    }

    @MainActor
    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate {

        static let messageHandlerName = "wikirun"

        private static let invalidSnapshotError = "Invalid WikiRun snapshot"
        private static let saveFailedError = "Could not save WikiRun progress"
        private static let unsupportedRequestError = "Unsupported WikiRun bridge request"

        private let viewModel: WMFWikiRunViewModel
        weak var webView: WKWebView?
        private var lastPushedDarkMode: Bool?

        init(viewModel: WMFWikiRunViewModel) {
            self.viewModel = viewModel
        }

        // MARK: - WKScriptMessageHandler

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == Self.messageHandlerName,
                  message.frameInfo.isMainFrame,
                  isSameOrigin(message.frameInfo.request.url),
                  let rawMessage = message.body as? String,
                  let data = rawMessage.data(using: .utf8),
                  let envelope = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let id = envelope["id"] as? String,
                  let type = envelope["type"] as? String else {
                return
            }

            let payload = envelope["payload"] as? [String: Any] ?? [:]
            switch type {
            case "initialize":
                Task {
                    let snapshot = await viewModel.loadSnapshot()
                    let snapshotValue: Any = snapshot.map { ["version": $0.version, "values": $0.values] } ?? NSNull()
                    reply(id: id, payload: ["snapshot": snapshotValue, "darkMode": viewModel.isDarkMode])
                }
            case "saveSnapshot":
                let version = payload["version"] as? Int
                let values = payload["values"] as? [String: String]
                Task {
                    switch await viewModel.saveSnapshot(version: version, values: values) {
                    case .saved:
                        reply(id: id, payload: ["saved": true])
                    case .invalidSnapshot:
                        reply(id: id, error: Self.invalidSnapshotError)
                    case .failed:
                        reply(id: id, error: Self.saveFailedError)
                    }
                }
            case "openLink":
                if let url = safeWebURL(payload["url"] as? String) { viewModel.openLink(url) }
            case "openArticle":
                if let url = safeWebURL(payload["url"] as? String) { viewModel.openArticle(url) }
            case "share":
                viewModel.share(text: payload["text"] as? String, url: safeWebURL(payload["url"] as? String))
            case "close":
                viewModel.close()
            default:
                reply(id: id, error: Self.unsupportedRequestError)
            }
        }

        // MARK: - WKNavigationDelegate

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }
            if isSameOrigin(url) || url.scheme == "about" {
                decisionHandler(.allow)
            } else if let externalURL = safeWebURL(url.absoluteString) {
                viewModel.openLink(externalURL)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.cancel)
            }
        }

        // MARK: - WKUIDelegate

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let url = navigationAction.request.url, let externalURL = safeWebURL(url.absoluteString) {
                viewModel.openLink(externalURL)
            }
            return nil
        }

        // MARK: - Bridge helpers

        func pushDarkModeIfNeeded(_ isDarkMode: Bool) {
            guard let webView, lastPushedDarkMode != isDarkMode else { return }
            lastPushedDarkMode = isDarkMode
            webView.evaluateJavaScript("window.__wikiRunSetDarkMode?(\(isDarkMode))")
        }

        private func reply(id: String, payload: Any? = nil, error: String? = nil) {
            guard let webView else { return }
            var response: [String: Any] = ["id": id]
            if let payload { response["payload"] = payload }
            if let error { response["error"] = error }
            guard let responseData = try? JSONSerialization.data(withJSONObject: response),
                  let responseJSON = String(data: responseData, encoding: .utf8),
                  let argumentData = try? JSONEncoder().encode(responseJSON),
                  let argument = String(data: argumentData, encoding: .utf8) else { return }
            webView.evaluateJavaScript("window.__wikiRunReceive?.(\(argument))")
        }

        private func safeWebURL(_ string: String?) -> URL? {
            guard let string,
                  let url = URL(string: string),
                  ["http", "https"].contains(url.scheme?.lowercased() ?? "") else { return nil }
            return url
        }

        private func isSameOrigin(_ url: URL?) -> Bool {
            guard let url else { return false }
            let gameURL = viewModel.gameURL
            return url.scheme?.lowercased() == gameURL.scheme?.lowercased()
                && url.host?.lowercased() == gameURL.host?.lowercased()
                && url.port == gameURL.port
        }
    }
}
