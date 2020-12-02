import UIKit

protocol ArticleLocationAuthorizationCollectionViewCellDelegate: class {
    func articleLocationAuthorizationCollectionViewCellDidTapAuthorize(_ cell: ArticleLocationAuthorizationCollectionViewCell)
}

class ArticleLocationAuthorizationCollectionViewCell: ArticleLocationExploreCollectionViewCell {
    let authorizeButton: UIButton = UIButton()
    let authorizeDescriptionLabel: UILabel = UILabel()
    weak var authorizationDelegate: ArticleLocationAuthorizationCollectionViewCellDelegate?
    
    override func setup() {
        super.setup()
        authorizeButton.layer.cornerRadius = 5
        authorizeButton.titleLabel?.numberOfLines = 2
        authorizeButton.titleLabel?.textAlignment = .center
        authorizeButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        authorizeButton.addTarget(self, action: #selector(authorizeButtonPressed(_:)), for: .touchUpInside)
        addSubview(authorizeButton)
        
        authorizeDescriptionLabel.textAlignment = .natural
        authorizeDescriptionLabel.numberOfLines = 0
        addSubview(authorizeDescriptionLabel)
    }

    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        authorizeButton.titleLabel?.font = UIFont.wmf_font(.semiboldSubheadline, compatibleWithTraitCollection: traitCollection)
        authorizeDescriptionLabel.font = UIFont.wmf_font(.footnote, compatibleWithTraitCollection: traitCollection)
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let size = super.sizeThatFits(size, apply: apply)
        var origin = CGPoint(x: layoutMargins.left, y: size.height + (spacing * 3))
        let widthForLabels = size.width - layoutMargins.left - layoutMargins.right
        let authorizeSpacing = 3 * spacing
        let horizontalAlignment: HorizontalAlignment = isDeviceRTL ? .right : .left
        origin.y += authorizeButton.wmf_preferredHeight(at: origin, maximumWidth: widthForLabels, minimumWidth: widthForLabels, horizontalAlignment: .center, spacing: authorizeSpacing, apply: apply)
        origin.y += authorizeDescriptionLabel.wmf_preferredHeight(at: origin, maximumWidth: widthForLabels, horizontalAlignment: horizontalAlignment, spacing: authorizeSpacing, apply: apply)
        return CGSize(width: size.width, height: origin.y + layoutMargins.bottom)
    }

    public func updateForLocationEnabled() {
        authorizeButton.setTitle(WMFLocalizedString("places-location-enabled", value: "Location enabled", comment: "Title for button informing user that they successfully enabled location services"), for: .normal)
        authorizeButton.removeTarget(self, action: #selector(authorizeButtonPressed(_:)), for: .touchUpInside)
        authorizeButton.isEnabled = false
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        authorizeButton.backgroundColor = theme.colors.cardButtonBackground
        authorizeButton.setTitleColor(theme.colors.link, for: .normal)
        authorizeButton.setTitleColor(theme.colors.secondaryText, for: .disabled)
        authorizeDescriptionLabel.textColor = theme.colors.secondaryText
        backgroundView?.backgroundColor = theme.colors.cardBackground
    }
    
    @objc public func authorizeButtonPressed(_ sender: Any?) {
        authorizationDelegate?.articleLocationAuthorizationCollectionViewCellDidTapAuthorize(self)
    }
    
    override var isSwipeEnabled: Bool {
        return false
    }
}
