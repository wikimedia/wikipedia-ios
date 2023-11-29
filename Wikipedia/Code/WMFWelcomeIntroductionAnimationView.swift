import Foundation

open class WMFWelcomeIntroductionAnimationView : WMFWelcomeAnimationView {

    lazy var image: UIImageView = {
        let imgView = UIImageView(frame: bounds)
        imgView.image = UIImage(named: "ftux-puzzle-globe")
        imgView.contentMode = .scaleAspectFit
        imgView.layer.transform = CATransform3DIdentity
        return imgView
    }()

    override open func addAnimationElementsScaledToCurrentFrameSize() {
        super.addAnimationElementsScaledToCurrentFrameSize()
        removeExistingSubviewsAndSublayers()
        addSubview(image)
    }
}
