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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        autoresizingMask = .flexibleHeight
    }
    
    override var intrinsicContentSize: CGSize {
        let superSize = super.intrinsicContentSize
        return CGSize(width: superSize.width, height: heightConstraint.constant)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        beKindView.configure(iconName: "heart-icon", title: CommonStrings.talkPageNewBannerTitle, subtitle: CommonStrings.talkPageNewBannerSubtitle)
        heightConstraint.constant = beKindView.sizeThatFits(bounds.size, apply: true).height
    }

    func apply(theme: Theme) {
        backgroundColor = theme.colors.hintBackground
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
            invalidateIntrinsicContentSize()
        }
        
    }
}
