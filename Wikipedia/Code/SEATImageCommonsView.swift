import Foundation
import SwiftUI
import Components

struct SEATImageCommonsView: UIViewControllerRepresentable {
    
    typealias UIViewControllerType = SinglePageWebViewController
    
    @ObservedObject private var appEnvironment = WKAppEnvironment.current

    private var theme: WKTheme {
        appEnvironment.theme
    }

    let commonsURL: URL
    
    func makeUIViewController(context: Context) -> SinglePageWebViewController {
        return SinglePageWebViewController(url: commonsURL, theme: WKTheme.theme(from: theme), doesUseSimpleNavigationBar: true, campaignArticleURL: nil, campaignBannerID: nil)
    }

    func updateUIViewController(_ uiViewController: SinglePageWebViewController, context: Context) {
 
    }
}
