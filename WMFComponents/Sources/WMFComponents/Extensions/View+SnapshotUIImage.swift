import UIKit
import SwiftUI

extension View {
    /// Captures a snapshot of the SwiftUI view as a UIImage with a given size.
    /// - Parameter size: The desired size for the snapshot
    /// - Returns: A snapshot of the SwiftUI view as a UIImage.
    func snapshot(with size: CGSize) -> UIImage {
        // Create a UIHostingController hosting the SwiftUI view.
        let controller = UIHostingController(rootView: self.frame(width: size.width, height: size.height))
        let view = controller.view
        view?.bounds = CGRect(origin: .zero, size: size)
        view?.backgroundColor = .clear
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            view?.drawHierarchy(in: view!.bounds, afterScreenUpdates: true)
        }
    }
}
