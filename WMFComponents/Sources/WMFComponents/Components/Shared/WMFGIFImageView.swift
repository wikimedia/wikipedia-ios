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
            
            // Encode GIF as base64 to safely embed it in HTML
            let base64String = gifData.base64EncodedString()
            
            let html = """
            <html>
              <head>
                <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
                <style>
                  html, body {
                    margin: 0;
                    padding: 0;
                    background: transparent;
                  }
                  img {
                    width: 100%;
                    height: auto;
                    display: block;
                  }
                </style>
              </head>
              <body>
                <img src="data:image/gif;base64,\(base64String)" />
              </body>
            </html>
            """
            
            webview.loadHTMLString(html, baseURL: nil)
        } else {
            debugPrint("Error: Could not find or load gif: \(name).")
        }
        
        return webview
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        
    }
}
