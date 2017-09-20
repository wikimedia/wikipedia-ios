import Foundation

// TODO:
// - probably make a "WMFWelcomeAnimationBackgroundView" which inherits from WMFWelcomeAnimationView and contains this logic
// - then simply have sub-classes overrid imageModels array
// - use structs instead of tuples
// - move the tap utility for easily getting/tweaking unitSize and unitDestination somewhere that makes sense

typealias imageModel = (name: String, unitSize: CGSize, unitDestination: CGPoint, delay: Double, duration: Double, initialOpacity: Float)
typealias imageTuple = (model: imageModel, imageView: UIImageView)

extension WMFWelcomeAnimationView {
    func imageTuples(imageModels: [imageModel]) -> [imageTuple] {
        return imageModels.map{ (model) in
            let imgView = UIImageView()
            imgView.image = UIImage(named: model.name)
            imgView.contentMode = UIViewContentMode.scaleAspectFit
            imgView.layer.opacity = model.initialOpacity
            return (model: model, imageView: imgView)
        }
    }
}

open class WMFWelcomeExplorationAnimationBackgroundView : WMFWelcomeAnimationView {
    let imageModels:[imageModel] = [
        (name: "ftux-background-globe", unitSize: CGSize(width: 0.071875, height: 0.071875), unitDestination:CGPoint(x: 0.265625, y: -0.32621), delay: 0.8, duration: 1.3, initialOpacity: 0.0),
        (name: "ftux-background-map-dot", unitSize: CGSize(width: 0.0625, height: 0.071875), unitDestination:CGPoint(x: 0.2015625, y: 0.286585), delay: 1.0, duration: 1.4, initialOpacity: 0.0),
        (name: "ftux-background-calendar", unitSize: CGSize(width: 0.0625, height: 0.071875), unitDestination:CGPoint(x: -0.3140625, y: -0.417682), delay: 1.2, duration: 1.5, initialOpacity: 0.0),
        
        (name: "ftux-background-plus", unitSize: CGSize(width: 0.03125, height: 0.060975), unitDestination:CGPoint(x: 0.2015625, y: -0.49085), delay: 1.1, duration: 1.5, initialOpacity: 0.0),
        (name: "ftux-background-plus", unitSize: CGSize(width: 0.03125, height: 0.060975), unitDestination:CGPoint(x: 0.284375, y: 0.10670), delay: 0.5, duration: 1.3, initialOpacity: 0.0),
        (name: "ftux-background-plus", unitSize: CGSize(width: 0.03125, height: 0.060975), unitDestination:CGPoint(x: -0.303125, y: 0.051829), delay: 0.9, duration: 1.5, initialOpacity: 0.0),
        
        (name: "ftux-background-circle", unitSize: CGSize(width: 0.040625, height: 0.079268), unitDestination:CGPoint(x: 0.3359375, y: -0.100609), delay: 1.1, duration: 1.4, initialOpacity: 0.0),
        (name: "ftux-background-circle", unitSize: CGSize(width: 0.040625, height: 0.079268), unitDestination:CGPoint(x: -0.275, y: 0.34756), delay: 0.6, duration: 1.5, initialOpacity: 0.0),
        (name: "ftux-background-circle", unitSize: CGSize(width: 0.040625, height: 0.079268), unitDestination:CGPoint(x: -0.3984375, y: -0.155487), delay: 0.8, duration: 1.2, initialOpacity: 0.0)
    ]
    
    lazy var lazyImageTuples: [imageTuple] = imageTuples(imageModels: imageModels)
    
    override open func addAnimationElementsScaledToCurrentFrameSize(){
        removeExistingSubviewsAndSublayers()
        lazyImageTuples.forEach{ (tuple) in
            addSubview(tuple.imageView)
            // Start all images in the center. imageModel unitDestination assumes center origin.
            tuple.imageView.center = CGPoint(x: bounds.midX, y: bounds.midY);
            // Denormalize unitSize using a scalar (NOT a CGSize - so aspect ratio remains constant)
            tuple.imageView.frame.size = tuple.model.unitSize.wmf_denormalizeUsingReference(frame.size.width)
        }
        /*
        isUserInteractionEnabled = true
        let tapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGestureRecognizer(_:)))
        addGestureRecognizer(tapGestureRecognizer)
        */
    }
    
    /*
    @objc func handleTapGestureRecognizer(_ gestureRecognizer: UITapGestureRecognizer) {
        // print unit coords for easy re-positioning
        let point = gestureRecognizer.location(in: self)
        let unitDestination = CGPoint(x: (point.x - (bounds.size.width * 0.5)) / bounds.size.width, y: (point.y - (bounds.size.height * 0.5)) / bounds.size.height)
        print("unitDestination \(unitDestination)")

        // preview the item at the tap location
        let tuple = lazyImageTuples[0] // <-- Adjust to pick which image is being tweaked.
        tuple.imageView.layer.removeAllAnimations()
        let dest = unitDestination.wmf_denormalizeUsingSize(frame.size)
        let tx = CATransform3DMakeAffineTransform(CGAffineTransform(translationX: dest.x, y: dest.y))
        tuple.imageView.layer.transform = tx
        tuple.imageView.layer.opacity = 1.0

        guard let image = tuple.imageView.image else {return}
        let imageUnitSize = CGSize(width: image.size.width / bounds.size.width, height: image.size.height / bounds.size.width) // "bounds.size.width" for both cases is deliberate here
        print("unitSize \(imageUnitSize)")
    }
    */
    
    override open func beginAnimations() {
        CATransaction.begin()
        lazyImageTuples.forEach{ (tuple) in
            let dest = tuple.model.unitDestination.wmf_denormalizeUsingSize(frame.size)
            let tx = CATransform3DMakeTranslation(dest.x, dest.y, 1.0)
            tuple.imageView.layer.wmf_animateToOpacity(1.0, transform: tx, delay: tuple.model.delay, duration: tuple.model.duration)
        }
        CATransaction.commit()
    }
}
