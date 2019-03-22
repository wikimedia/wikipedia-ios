import UIKit

final class WelcomeAnimationView: UIView {
    private var imageModels: [ImageModel]?

    struct ImageModel {
        let name: String
        let unitSize: CGSize
        let unitDestination: CGPoint
        let delay: Double
        let duration: Double
        let initialOpacity: Float
    }

    struct ImageViewAndModel {
        let imageView: UIImageView
        let model: ImageModel
    }


    private lazy var imageViewsAndModels: [ImageViewAndModel]? = {
        guard let imageModels = imageModels else {
            return nil
        }
        return imageModels.map { imageModel in
            let imageView = UIImageView()
            imageView.image = UIImage(named: imageModel.name)
            imageView.contentMode = UIView.ContentMode.scaleAspectFit
            imageView.layer.opacity = imageModel.initialOpacity
            return ImageViewAndModel(imageView: imageView, model: imageModel)
        }
    }()

    open func animate() {

    }

    init(staticImage: UIImage) {
        super.init(frame: .zero)
        let imageView = UIImageView(image: staticImage)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        wmf_addSubviewWithConstraintsToEdges(imageView)
    }

    init(imageModels: [ImageModel]) {
        self.imageModels = imageModels
        super.init(frame: .zero)
    }

    private func addAnimationElementsScaledToCurrentFrameSize() {
        guard let imageViewsAndModels = imageViewsAndModels else {
            return
        }
        imageViewsAndModels.forEach { imageViewAndModel in
            addSubview(imageViewAndModel.imageView)
            // Start all images in the center. imageModel unitDestination assumes center origin.
            imageViewAndModel.imageView.center = CGPoint(x: bounds.midX, y: bounds.midY)
            // Denormalize unitSize using a scalar (NOT a CGSize - so aspect ratio remains constant)
            imageViewAndModel.imageView.frame.size = imageViewAndModel.model.unitSize.wmf_denormalizeUsingReference(frame.size.width)
        }
        /*
         isUserInteractionEnabled = true
         addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapGestureRecognizer(_:))))
         */
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
