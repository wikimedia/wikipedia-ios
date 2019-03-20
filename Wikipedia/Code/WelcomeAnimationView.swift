import UIKit

class WelcomeAnimationView: UIView {
    open func animate() {

    }

    init(staticImage: UIImage) {
        super.init(frame: .zero)
        let imageView = UIImageView(image: staticImage)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        wmf_addSubviewWithConstraintsToEdges(imageView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
