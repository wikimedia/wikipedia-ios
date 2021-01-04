import Foundation

public struct ImageModel {
    let name: String
    let unitSize: CGSize
    let unitDestination: CGPoint
    let delay: Double
    let duration: Double
    let initialOpacity: Float
}

public struct ImageViewAndModel {
    let model: ImageModel
    let imageView: UIImageView
}

open class WMFWelcomeAnimationBackgroundView: WMFWelcomeAnimationView {

    private(set) var imageModels:[ImageModel]? = nil

    private lazy var imageViewsAndModels: [ImageViewAndModel]? = {
        guard let imageModels = imageModels else {
            assertionFailure("Expected models")
            return nil
        }
        return imageModels.map{ (model) in
            let imgView = UIImageView()
            imgView.image = UIImage(named: model.name)
            imgView.contentMode = UIView.ContentMode.scaleAspectFit
            imgView.layer.opacity = model.initialOpacity
            return ImageViewAndModel.init(model: model, imageView: imgView)
        }
    }()
    
    override open func addAnimationElementsScaledToCurrentFrameSize(){
        super.addAnimationElementsScaledToCurrentFrameSize()
        removeExistingSubviewsAndSublayers()
        guard let imageViewsAndModels = imageViewsAndModels else {
            return
        }
        imageViewsAndModels.forEach{ (imageViewAndModel) in
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
    /*
     @objc func handleTapGestureRecognizer(_ gestureRecognizer: UITapGestureRecognizer) {
         // print unit coords for easy re-positioning
         let point = gestureRecognizer.location(in: self)
         let unitDestination = CGPoint(x: (point.x - (bounds.size.width * 0.5)) / bounds.size.width, y: (point.y - (bounds.size.height * 0.5)) / bounds.size.height)
         DDLogDebug("unitDestination \(unitDestination)")
     
         // preview the item at the tap location
         let imageViewAndModel = imageViewsAndModels![0] // <-- Adjust to pick which image is being tweaked.
         imageViewAndModel.imageView.layer.removeAllAnimations()
         let dest = unitDestination.wmf_denormalizeUsingSize(frame.size)
         let tx = CATransform3DMakeAffineTransform(CGAffineTransform(translationX: dest.x, y: dest.y))
         imageViewAndModel.imageView.layer.transform = tx
         imageViewAndModel.imageView.layer.opacity = 1.0
     
         guard let image = imageViewAndModel.imageView.image else {
             return
         }
         let imageUnitSize = CGSize(width: image.size.width / bounds.size.width, height: image.size.height / bounds.size.width) // "bounds.size.width" for both cases is deliberate here
         DDLogDebug("unitSize \(imageUnitSize)")
     }
    */
    override open func beginAnimations() {
        super.beginAnimations()
        CATransaction.begin()
        guard let imageViewsAndModels = imageViewsAndModels else {
            return
        }
        imageViewsAndModels.forEach{ (imageViewAndModel) in
            let dest = imageViewAndModel.model.unitDestination.wmf_denormalizeUsingSize(frame.size)
            let tx = CATransform3DMakeTranslation(dest.x, dest.y, 1.0)
            imageViewAndModel.imageView.layer.wmf_animateToOpacity(1.0, transform: tx, delay: imageViewAndModel.model.delay, duration: imageViewAndModel.model.duration)
        }
        CATransaction.commit()
    }
}
