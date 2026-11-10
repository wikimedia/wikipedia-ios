import UIKit
import WebKit

@MainActor
final class WikiRunViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate {

    private struct Snapshot: Codable {
        let version: Int
        let values: [String: String]
    }

    private final class SnapshotStore: @unchecked Sendable {
        private let fileURL: URL
        private let queue = DispatchQueue(label: "org.wikimedia.wikirun.snapshot")

        init() {
            let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("WikiRun", isDirectory: true)
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            fileURL = directory.appendingPathComponent("state.json")
        }

        func load(completion: @escaping (Snapshot?) -> Void) {
            queue.async {
                let snapshot = (try? Data(contentsOf: self.fileURL))
                    .flatMap { try? JSONDecoder().decode(Snapshot.self, from: $0) }
                DispatchQueue.main.async { completion(snapshot) }
            }
        }

        func save(values: [String: String], completion: @escaping (Bool) -> Void) {
            queue.async {
                var saved = true
                do {
                    try JSONEncoder().encode(Snapshot(version: 1, values: values))
                        .write(to: self.fileURL, options: .atomic)
                } catch {
                    saved = false
                }
                DispatchQueue.main.async { completion(saved) }
            }
        }
    }

    private final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
        weak var delegate: WKScriptMessageHandler?

        init(delegate: WKScriptMessageHandler) {
            self.delegate = delegate
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            delegate?.userContentController(userContentController, didReceive: message)
        }
    }

    private let snapshotStore = SnapshotStore()
    private let gameURL: URL?

    /// Set by the presenter: opens a Wikipedia article over the game, so back returns to it.
    var onOpenArticle: ((URL) -> Void)?

    private lazy var webView: WKWebView = {
        let controller = WKUserContentController()
        controller.add(WeakScriptMessageHandler(delegate: self), name: "wikirun")
        controller.addUserScript(WKUserScript(
            source: "window.__wikiRunEmbed = true;",
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        ))
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = controller
        configuration.applicationNameForUserAgent = "WikipediaApp"
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = self
        view.uiDelegate = self
        // CSS cannot stop the scroll view itself from rubber-banding.
        view.scrollView.bounces = false
#if DEBUG
        view.isInspectable = true
#endif
        return view
    }()

    init() {
        let configuredURL = Bundle.main.object(forInfoDictionaryKey: "WikiRunBaseURL") as? String
        let productionURL = URL(string: "https://wikirun-game.toolforge.org")
        if let candidate = URL(string: configuredURL ?? ""),
           ["http", "https"].contains(candidate.scheme?.lowercased() ?? ""),
           candidate.host != nil {
            gameURL = candidate
        } else {
            gameURL = productionURL
        }
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { [weak self] (viewController: Self, _: UITraitCollection) in
            guard let self else { return }
            let isDark = viewController.traitCollection.userInterfaceStyle == .dark
            self.webView.evaluateJavaScript("window.__wikiRunSetDarkMode?.(\(isDark))")
        }

        guard let gameURL else {
            assertionFailure("WikiRun base URL is not a valid URL")
            return
        }
        var components = URLComponents(url: gameURL, resolvingAgainstBaseURL: false)
        var queryItems = components?.queryItems ?? []
        queryItems.removeAll { $0.name == "embed" }
        queryItems.append(URLQueryItem(name: "embed", value: "1"))
        components?.queryItems = queryItems
        guard let url = components?.url else { return }
        webView.load(URLRequest(url: url))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // The game draws its own chrome; the bar comes back when an article is pushed.
        navigationController?.setNavigationBarHidden(true, animated: animated)
        // Articles enable bar hiding on swipe; leaving it on would re-show the bar over the game.
        navigationController?.hidesBarsOnSwipe = false
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "wikirun",
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
            snapshotStore.load { [weak self] snapshot in
                guard let self else { return }
                let snapshotValue: Any = snapshot.map {
                    ["version": $0.version, "values": $0.values] as [String: Any]
                } ?? NSNull()
                self.reply(id: id, payload: [
                    "snapshot": snapshotValue,
                    "darkMode": self.traitCollection.userInterfaceStyle == .dark
                ])
            }
        case "saveSnapshot":
            guard (payload["version"] as? Int) == 1,
                  let values = payload["values"] as? [String: String] else {
                reply(id: id, error: "Invalid WikiRun snapshot")
                return
            }
            snapshotStore.save(values: values) { [weak self] saved in
                guard let self else { return }
                if saved {
                    self.reply(id: id, payload: ["saved": true])
                } else {
                    self.reply(id: id, error: "Could not save WikiRun progress")
                }
            }
        case "openLink":
            if let url = safeWebURL(payload["url"] as? String) { UIApplication.shared.open(url) }
        case "openArticle":
            if let url = safeWebURL(payload["url"] as? String) { openArticle(url) }
        case "share":
            share(payload: payload)
        case "close":
            dismiss(animated: true)
        default:
            reply(id: id, error: "Unsupported WikiRun bridge request")
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        if isSameOrigin(url) || url.scheme == "about" {
            decisionHandler(.allow)
        } else if let externalURL = safeWebURL(url.absoluteString) {
            UIApplication.shared.open(externalURL)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.cancel)
        }
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url, let externalURL = safeWebURL(url.absoluteString) {
            UIApplication.shared.open(externalURL)
        }
        return nil
    }

    /// Opens an article the game asked for by message, so the game decides what is encyclopedic
    /// content; anchors rendered inside the game keep going to the system browser.
    private func openArticle(_ url: URL) {
        if let onOpenArticle, LinkCoordinator.destination(for: url) == .article {
            onOpenArticle(url)
        } else {
            UIApplication.shared.open(url)
        }
    }

    private func reply(id: String, payload: Any? = nil, error: String? = nil) {
        var response: [String: Any] = ["id": id]
        if let payload { response["payload"] = payload }
        if let error { response["error"] = error }
        guard let responseData = try? JSONSerialization.data(withJSONObject: response),
              let responseJSON = String(data: responseData, encoding: .utf8),
              let argumentData = try? JSONEncoder().encode(responseJSON),
              let argument = String(data: argumentData, encoding: .utf8) else { return }
        webView.evaluateJavaScript("window.__wikiRunReceive?.(\(argument))")
    }

    private func share(payload: [String: Any]) {
        var items: [Any] = []
        if let text = payload["text"] as? String { items.append(text) }
        if let url = safeWebURL(payload["url"] as? String) { items.append(url) }
        guard !items.isEmpty else { return }
        let activity = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let popover = activity.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = view.bounds
            popover.permittedArrowDirections = []
        }
        present(activity, animated: true)
    }

    private func safeWebURL(_ string: String?) -> URL? {
        guard let string, let url = URL(string: string), ["http", "https"].contains(url.scheme?.lowercased() ?? "") else { return nil }
        return url
    }

    private func isSameOrigin(_ url: URL?) -> Bool {
        guard let url, let gameURL else { return false }
        return url.scheme?.lowercased() == gameURL.scheme?.lowercased()
            && url.host?.lowercased() == gameURL.host?.lowercased()
            && url.port == gameURL.port
    }
}
