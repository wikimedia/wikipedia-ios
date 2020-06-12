import UIKit

class ArticleLocationCollectionViewCell: ArticleCollectionViewCell {
    let compassView: WMFCompassView = WMFCompassView()
    let compassViewDimension: CGFloat = 104
    let distanceLabel: UILabel = UILabel()
    let distanceLabelBackground: UIView = UIView()
    let distanceTextStyle: DynamicTextStyle = .caption1
    var articleLocation: CLLocation?
    var userLocation: CLLocation?
    
    override func setup() {
        super.setup()
        insertSubview(compassView, belowSubview: imageView)
        isImageViewHidden = false
        imageView.layer.cornerRadius = round(0.5*imageViewDimension)
        imageView.layer.masksToBounds = true
        addSubview(distanceLabelBackground)
        addSubview(distanceLabel)
        distanceLabelBackground.layer.cornerRadius = 2.0
        titleLabel.numberOfLines = 0
        descriptionLabel.numberOfLines = 2
        updateDistanceLabelBackgroundBorder()
    }
    
    override func reset() {
        super.reset()
        titleTextStyle = .georgiaTitle3
        descriptionTextStyle = .subheadline
        imageViewDimension = 72
        imageView.image = #imageLiteral(resourceName: "compass-w")
    }
    
    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        distanceLabel.font = UIFont.wmf_font(distanceTextStyle, compatibleWithTraitCollection: traitCollection)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateDistanceLabelBackgroundBorder()
    }

    private func updateDistanceLabelBackgroundBorder() {
        let displayScale = max(1, traitCollection.displayScale)
        distanceLabelBackground.layer.borderWidth = 1.0 / displayScale
    }
    
    override open func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let size = super.sizeThatFits(size, apply: apply)
        let isLTR = articleSemanticContentAttribute != .forceRightToLeft

        let layoutMargins = calculatedLayoutMargins
        
        let minHeight = compassViewDimension
        let hSpaceBetweenCompassAndLabels: CGFloat = 10
        let widthForLabels = size.width - layoutMargins.left - compassViewDimension - hSpaceBetweenCompassAndLabels - layoutMargins.right

        let x = isLTR ? layoutMargins.left + compassViewDimension + hSpaceBetweenCompassAndLabels : layoutMargins.left
       
        var origin = CGPoint(x: x, y: layoutMargins.top)
        
        let titleLabelFrame = titleLabel.wmf_preferredFrame(at: origin, maximumWidth: widthForLabels, alignedBy: articleSemanticContentAttribute, apply: apply)
        origin.y += titleLabelFrame.layoutHeight(with: spacing)
        
        
        if descriptionLabel.wmf_hasAnyNonWhitespaceText {
            let descriptionLabelFrame = descriptionLabel.wmf_preferredFrame(at: origin, maximumWidth: widthForLabels, alignedBy: articleSemanticContentAttribute, apply: apply)
            origin.y += descriptionLabelFrame.layoutHeight(with: spacing)
            descriptionLabel.isHidden = false
        } else {
            descriptionLabel.isHidden = true
        }
        
        let distanceLabelHorizontalPadding: CGFloat = 5
        let distanceLabelVerticalPadding: CGFloat = 5
        let distanceLabelExtraTopMargin: CGFloat = 3
        let distanceLabelFrame = distanceLabel.wmf_preferredFrame(at: CGPoint(x: origin.x + distanceLabelHorizontalPadding, y: origin.y + distanceLabelVerticalPadding + distanceLabelExtraTopMargin), maximumWidth: widthForLabels - 2 * distanceLabelHorizontalPadding, alignedBy: articleSemanticContentAttribute, apply: apply)

        let distanceLabelBackgroundFrame = distanceLabelFrame.inset(by: UIEdgeInsets(top: 0 - distanceLabelVerticalPadding, left: 0 - distanceLabelHorizontalPadding, bottom: 0 - distanceLabelVerticalPadding, right: 0 - distanceLabelHorizontalPadding))

        origin.y += distanceLabelBackgroundFrame.height + distanceLabelExtraTopMargin + spacing

        if apply {
            distanceLabelBackground.frame = distanceLabelBackgroundFrame
        }
        
        origin.y += layoutMargins.bottom
        let height = max(origin.y, minHeight)
        
        if (apply && !isImageViewHidden) {
            let compassViewY = floor(0.5 * (height - compassViewDimension))
            let compassViewX = isLTR ? layoutMargins.left : size.width - layoutMargins.right - compassViewDimension
            compassView.frame = CGRect(x: compassViewX, y: compassViewY, width: compassViewDimension, height: compassViewDimension)
            
            let imageViewY = floor(0.5 * (height - imageViewDimension))
            let imageViewDelta = floor(0.5 * (compassViewDimension - imageViewDimension))
            let imageViewX =  isLTR ? layoutMargins.left + imageViewDelta : size.width - layoutMargins.right - compassViewDimension + imageViewDelta
            imageView.frame = CGRect(x: imageViewX, y: imageViewY, width: imageViewDimension, height: imageViewDimension)
        }
        
        return CGSize(width: size.width, height: height)
    }
    
    public func configureForUnknownDistance() {
        distanceLabel.text = WMFLocalizedString("places-unknown-distance", value: "unknown distance", comment: "Indicates that a place is an unknown distance away").lowercased()
        setNeedsLayout()
    }
    
    var distance: CLLocationDistance = 0 {
        didSet {
            distanceLabel.text = NSString.wmf_localizedString(forDistance: distance)
            setNeedsLayout()
        }
    }
    
    var bearing: CLLocationDegrees = 0 {
        didSet {
            compassView.angleRadians = bearing * .pi / 180
        }
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        imageView.backgroundColor = .green50
        distanceLabel.textColor = theme.colors.secondaryText
        distanceLabelBackground.layer.borderColor = theme.colors.distanceBorder.cgColor
        compassView.lineColor = theme.colors.accent
    }
}

class ArticleLocationExploreCollectionViewCell: ArticleLocationCollectionViewCell {
    override open func apply(theme: Theme) {
        super.apply(theme: theme)
        setBackgroundColors(theme.colors.cardBackground, selected: theme.colors.selectedCardBackground)
    }
}
