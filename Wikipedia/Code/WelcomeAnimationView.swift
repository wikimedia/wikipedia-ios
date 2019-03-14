import UIKit

class WelcomeAnimationView: UIView {

    open func animate() {

    }

    init(staticImage: UIImage) {
        super.init(frame: .zero)
        let imageView = UIImageView(image: staticImage)
        imageView.sizeToFit()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        wmf_addSubviewWithConstraintsToEdges(imageView)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
