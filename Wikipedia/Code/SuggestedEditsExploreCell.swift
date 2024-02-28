import UIKit

class SuggestedEditsExploreCell: CollectionViewCell {
    
    // TODO: Temporary UI
    private let captionLabel: UILabel = UILabel()

    var caption: String? {
        get {
            return captionLabel.text
        }
        set {
            captionLabel.text = newValue
            setNeedsLayout()
        }
    }
    
    override func setup() {
        super.setup()
        captionLabel.numberOfLines = 3
        addSubview(captionLabel)
    }
    
    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        captionLabel.font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
    }
    
    override func reset() {
        super.reset()
        captionLabel.text = nil
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        
        // TODO: maybe set layoutMarginsAdditions
        
        let layoutMargins = calculatedLayoutMargins
        
        let widthToFit = size.width - layoutMargins.right - layoutMargins.left

        let origin = CGPoint(x: layoutMargins.left, y: layoutMargins.top)
        
        let frame = captionLabel.wmf_preferredFrame(at: origin, maximumSize: CGSize(width: widthToFit, height: UIView.noIntrinsicMetric), minimumSize: NoIntrinsicSize, alignedBy: semanticContentAttribute, apply: apply)
        
        let finalHeight = frame.maxY + layoutMargins.bottom
        
        return CGSize(width: size.width, height: finalHeight)
    }
    

}

extension SuggestedEditsExploreCell: Themeable {
    func apply(theme: Theme) {
        captionLabel.textColor = theme.colors.primaryText
    }
}
