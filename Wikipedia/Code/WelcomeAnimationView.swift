import UIKit
import AVFoundation

typealias WelcomeAnimatedImageView = WelcomeAnimationView.AnimatedImageView

final class WelcomeAnimationView: UIView {
    private let sizeReference: CGSize
    private var animatedImageViews: [AnimatedImageView]?
    private var propertyAnimator: UIViewPropertyAnimator?

    final class AnimatedImageView: UIImageView {
        let start: CGPoint
        let destination: CGPoint?
        var normalizedDestination: CGPoint?
        let insertBelow: Bool
        let sizeReference: CGSize

        init(imageName: String, contentMode: UIView.ContentMode = .scaleAspectFit, start: CGPoint = .zero, destination: CGPoint? = nil, insertBelow: Bool = true, initialAlpha: CGFloat = 0) {
            self.start = start
            self.destination = destination
            self.insertBelow = insertBelow
            let image = UIImage(named: imageName)!
            sizeReference = image.size
            super.init(image: image)
            self.contentMode = contentMode
            self.alpha = initialAlpha
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    private func normalizedPoint(_ point: CGPoint, from aspectRatio: CGSize, to newRect: CGRect) -> CGPoint {
        let rect = AVMakeRect(aspectRatio: aspectRatio, insideRect: newRect)
        let scaledX = rect.width * (point.x / aspectRatio.width)
        let scaledY = rect.height * (point.y / aspectRatio.height)
        return CGPoint(x: rect.origin.x + scaledX, y: rect.origin.y + scaledY)
    }

    private var isAnimating = false
    private var finishedAnimating = false

    func animate() {
        isAnimating = true
        propertyAnimator?.startAnimation()
        propertyAnimator?.addCompletion { position in
            self.finishedAnimating = true
            self.isAnimating = false
        }
    }

    init(staticImageNamed staticImageName: String, contentMode: UIView.ContentMode = .scaleAspectFit, animatedImageViews: [AnimatedImageView]? = nil, propertyAnimator: UIViewPropertyAnimator? = nil) {
        let staticImage = UIImage(named: staticImageName)!
        sizeReference = staticImage.size
        let staticImageView = UIImageView(image: staticImage)
        self.animatedImageViews = animatedImageViews
        self.propertyAnimator = propertyAnimator
        super.init(frame: .zero)
        staticImageView.contentMode = contentMode
        wmf_addSubviewWithConstraintsToEdges(staticImageView)
        animatedImageViews?.forEach { imageView in
            if imageView.insertBelow {
                let subview = subviews.last ?? staticImageView
                insertSubview(imageView, belowSubview: subview)
            } else {
                addSubview(imageView)
            }
        }
    }

    override var bounds: CGRect {
        didSet {
            guard oldValue != bounds else {
                return
            }
            updateLayout()
        }
    }

    private func updateLayout() {
        guard let animatedImageViews = animatedImageViews else {
            return
        }
        for imageView in animatedImageViews {
            imageView.frame.size = size(for: imageView)

            let normalizedZero = normalizedPoint(.zero, from: imageView.sizeReference, to: imageView.bounds)
            let normalizedOrigin = normalizedPoint(imageView.start, from: sizeReference, to: bounds)

            if isAnimating || finishedAnimating, let destination = imageView.destination {
                let normalizedDestination = normalizedPoint(destination, from: sizeReference, to: bounds)
                imageView.frame.origin = CGPoint(x: normalizedDestination.x - normalizedZero.x, y: normalizedDestination.y - normalizedZero.y)
            } else {
                imageView.frame.origin = CGPoint(x: normalizedOrigin.x - normalizedZero.x, y: normalizedOrigin.y - normalizedZero.y)
            }

            if let destination = imageView.destination {
                let normalizedDestination = normalizedPoint(destination, from: sizeReference, to: bounds)
                imageView.normalizedDestination = CGPoint(x: normalizedDestination.x - normalizedZero.x, y: normalizedDestination.y - normalizedZero.y)
            }
        }
    }

    private func size(for imageView: AnimatedImageView) -> CGSize {
        let sizeThatFits = imageView.sizeThatFits(frame.size)

        let widthRatio = sizeThatFits.width / sizeReference.width
        let heightRatio = sizeThatFits.height / sizeReference.height
        let maxRatio = max(widthRatio, heightRatio)

        let width: CGFloat
        let height: CGFloat
        if sizeThatFits.width == sizeThatFits.height {
            width = bounds.width * maxRatio
            height = bounds.height * maxRatio
        } else {
            width = bounds.width * widthRatio
            height = bounds.height * heightRatio
        }
        return CGSize(width: width, height: height)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
