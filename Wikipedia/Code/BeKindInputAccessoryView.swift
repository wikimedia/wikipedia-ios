import UIKit

class BeKindInputAccessoryView: UIView, Themeable{
    @IBOutlet private weak var beKindView: InfoBannerView!
    @IBOutlet private weak var heightConstraint: NSLayoutConstraint!
    override func awakeFromNib() {
        super.awakeFromNib()
        beKindView.configure(iconName: "heart-icon", title: CommonStrings.talkPageNewBannerTitle, subtitle: CommonStrings.talkPageNewBannerSubtitle)
        heightConstraint.constant = beKindView.sizeThatFits(bounds.size, apply: true).height
    }

    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        beKindView.apply(theme: theme)
    }
}
