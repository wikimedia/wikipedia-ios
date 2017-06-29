import UIKit

@objc(WMFOnThisDayExploreCollectionViewCell)
class OnThisDayExploreCollectionViewCell: OnThisDayCollectionViewCell {

    private lazy var whiteTopAndBottomGradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        let white = UIColor.white.cgColor
        let clear = UIColor(white: 1, alpha: 0).cgColor // https://stackoverflow.com/a/24895385
        layer.colors = [white, clear, clear, white, white]
        layer.locations = [0.0, 0.07, 0.77, 0.97, 1.0]
        layer.startPoint = CGPoint(x: 0.5, y: 0.0)
        layer.endPoint = CGPoint(x: 0.5, y: 1.0)
        return layer
    }()

    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        whiteTopAndBottomGradientLayer.frame = bounds
        return super.sizeThatFits(size, apply: apply)
    }

    override open func setup() {
        super.setup()
        layer.addSublayer(whiteTopAndBottomGradientLayer)
    }
}
