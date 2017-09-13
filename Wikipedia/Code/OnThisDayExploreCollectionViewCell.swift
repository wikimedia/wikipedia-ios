import UIKit

@objc(WMFOnThisDayExploreCollectionViewCell)
public class OnThisDayExploreCollectionViewCell: OnThisDayCollectionViewCell {
    fileprivate var topGradientView: WMFGradientView = WMFGradientView()
    fileprivate var bottomGradientView: WMFGradientView = WMFGradientView()
    
    override public func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        if (apply) {
            let topGradientHeight: CGFloat = 17
            let bottomGradientHeight: CGFloat = 53
            let topGradientSize = CGSize(width: size.width, height: topGradientHeight)
            let bottomGradientSize = CGSize(width: size.width, height: bottomGradientHeight)
            topGradientView.frame = CGRect(origin: .zero, size: topGradientSize)
            bottomGradientView.frame = CGRect(origin: CGPoint(x: 0, y: size.height - bottomGradientHeight), size: bottomGradientSize)
        }
        return super.sizeThatFits(size, apply: apply)
    }

    override open func setup() {
        super.setup()
        addSubview(topGradientView)
        addSubview(bottomGradientView)
        topGradientView.startPoint = CGPoint(x: 0.5, y: 0)
        topGradientView.endPoint = CGPoint(x: 0.5, y: 1)
        bottomGradientView.startPoint = CGPoint(x: 0.5, y: 0)
        bottomGradientView.endPoint = CGPoint(x: 0.5, y: 0.8)
    }

    public override func apply(theme: Theme) {
        super.apply(theme: theme)
        let opaque = theme.colors.paperBackground
        let clear = opaque.withAlphaComponent(0)
        topGradientView.setStart(opaque, end: clear)
        bottomGradientView.setStart(clear, end: opaque)
    }
}
