import UIKit

public class OnThisDayExploreCollectionViewCell: OnThisDayCollectionViewCell {
    private var topGradientView: WMFGradientView = WMFGradientView()
    private var bottomGradientView: WMFGradientView = WMFGradientView()
    var isFirst: Bool = false
    var isLast: Bool = false

    override public func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        if apply {
            let topGradientHeight: CGFloat = 17
            let bottomGradientHeight: CGFloat = 43
            let topGradientSize = CGSize(width: timelineView.frame.size.width, height: topGradientHeight)
            let bottomGradientSize = CGSize(width: timelineView.frame.size.width, height: bottomGradientHeight)
            topGradientView.frame = CGRect(origin: .zero, size: topGradientSize)
            bottomGradientView.frame = CGRect(origin: CGPoint(x: 0, y: size.height - bottomGradientHeight), size: bottomGradientSize)
            topGradientView.isHidden = !isFirst
            bottomGradientView.isHidden = !isLast
        }
        return super.sizeThatFits(size, apply: apply)
    }

    override open func setup() {
        super.setup()
        timelineView.addSubview(topGradientView)
        timelineView.addSubview(bottomGradientView)
        topGradientView.startPoint = CGPoint(x: 0.5, y: 0)
        topGradientView.endPoint = CGPoint(x: 0.5, y: 1)
        bottomGradientView.startPoint = CGPoint(x: 0.5, y: 0)
        bottomGradientView.endPoint = CGPoint(x: 0.5, y: 0.8)
    }
    
    private func updateGradients() {
        let opaque = isSelectedOrHighlighted ? theme.colors.selectedCardBackground : theme.colors.cardBackground
        let clear = opaque.withAlphaComponent(0)
        topGradientView.setStart(opaque, end: clear)
        bottomGradientView.setStart(clear, end: opaque)
    }
    
    public override func updateSelectedOrHighlighted() {
        super.updateSelectedOrHighlighted()
        updateGradients()
    }
    
    public override func apply(theme: Theme) {
        super.apply(theme: theme)
        updateGradients()
        setBackgroundColors(theme.colors.cardBackground, selected: theme.colors.selectedCardBackground)
    }
}
