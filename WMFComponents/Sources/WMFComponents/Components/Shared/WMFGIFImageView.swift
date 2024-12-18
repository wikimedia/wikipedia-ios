import SwiftUI
import WebKit

struct WMFGIFImageView: UIViewRepresentable {
    private let name: String
    init(_ name: String) {
        self.name = name
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let webview = WKWebView()
        webview.scrollView.contentInset = .zero
        webview.scrollView.contentInsetAdjustmentBehavior = .never
        webview.scrollView.bounces = false
        webview.isOpaque = false
        webview.backgroundColor = .clear
        webview.scrollView.isScrollEnabled = false
        
        if let url = Bundle.module.url(forResource: name, withExtension: "gif"),
           let gifData = try? Data(contentsOf: url) {
            webview.load(gifData, mimeType: "image/gif", characterEncodingName: "UTF-8", baseURL: url.deletingLastPathComponent())
        } else {
            debugPrint("Error: Could not find or load gif: \(name).")
        }
        
        return webview
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.reload()
    }
}
