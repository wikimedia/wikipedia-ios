import UIKit

protocol BeKindInputAccessoryViewDelegate: class {
    func didUpdateHeight(view: BeKindInputAccessoryView)
}

class BeKindInputAccessoryView: UIView, Themeable{
    @IBOutlet private weak var beKindView: InfoBannerView!
    @IBOutlet private weak var heightConstraint: NSLayoutConstraint!
    
    weak var delegate: BeKindInputAccessoryViewDelegate?
    
    var height: CGFloat {
        return heightConstraint.constant
    }
    
    var containerHeight: CGFloat?
    
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
        
        if let containerHeight = containerHeight {
            beKindView.isDynamicFont = traitCollection.verticalSizeClass == .regular && containerHeight >= 600
        }
        
        let heightThatFits = beKindView.sizeThatFits(bounds.size, apply: true).height
        if heightConstraint.constant != heightThatFits {
            heightConstraint.constant = heightThatFits
            delegate?.didUpdateHeight(view: self)
        }
        
    }
}
