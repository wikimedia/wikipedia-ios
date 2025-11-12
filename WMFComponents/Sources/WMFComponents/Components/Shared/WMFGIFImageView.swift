import SwiftUI
import WebKit
import SDWebImage

struct WMFGIFImageView: UIViewRepresentable {
    let name: String
    
    init(_ name: String) {
        self.name = name
    }

    func makeUIView(context: Context) -> UIView {
        // Container UIView
        let container = UIView()
        container.backgroundColor = .clear

        let imageView = SDAnimatedImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false

        if let url = Bundle.module.url(forResource: name, withExtension: "gif"),
           let data = try? Data(contentsOf: url) {
            imageView.image = SDAnimatedImage(data: data)
        }

        container.addSubview(imageView)

        // Pin imageView to all edges of container
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // nothing to update
    }
}
