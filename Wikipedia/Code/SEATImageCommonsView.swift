import Foundation
import SwiftUI
import Components

struct SEATImageDetailsView: UIViewControllerRepresentable {
    
    typealias UIViewControllerType = SinglePageWebViewController
    
    @ObservedObject private var appEnvironment = WKAppEnvironment.current

    private var theme: WKTheme {
        appEnvironment.theme
    }

    let imageDetailsURL: URL
    
    func makeUIViewController(context: Context) -> SinglePageWebViewController {
        return SinglePageWebViewController(url: imageDetailsURL, theme: WKTheme.theme(from: theme), doesUseSimpleNavigationBar: true, campaignArticleURL: nil, campaignBannerID: nil)
    }

    func updateUIViewController(_ uiViewController: SinglePageWebViewController, context: Context) {
 
    }
}
