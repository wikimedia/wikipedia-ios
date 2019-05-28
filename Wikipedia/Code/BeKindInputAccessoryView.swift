import UIKit

class BeKindInputAccessoryView: UIView, Themeable{
    @IBOutlet private weak var beKindView: InfoBannerView!
    @IBOutlet private weak var heightConstraint: NSLayoutConstraint!
    
    var height: CGFloat {
        return heightConstraint.constant
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        beKindView.configure(iconName: "heart-icon", title: CommonStrings.talkPageNewBannerTitle, subtitle: CommonStrings.talkPageNewBannerSubtitle)
        heightConstraint.constant = beKindView.sizeThatFits(bounds.size, apply: true).height
    }

    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        beKindView.apply(theme: theme)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        heightConstraint.constant = beKindView.sizeThatFits(bounds.size, apply: true).height
    }
}
