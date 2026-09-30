import SwiftUI
import UIKit

/// Hosts an app-side UIViewController (the legacy Explore feed) inside the Home view's Community tab
/// while the native SwiftUI community feed is under development. The provider is expected to cache and
/// return the same instance across calls so state (e.g. scroll position) survives tab switches.
struct WMFHomeEmbeddedCommunityView: UIViewControllerRepresentable {

    let makeViewController: () -> UIViewController

    func makeUIViewController(context: Context) -> UIViewController {
        makeViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}
