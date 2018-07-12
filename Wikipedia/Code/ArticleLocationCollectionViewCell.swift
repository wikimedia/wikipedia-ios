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
    }
    
    override func reset() {
        super.reset()
        titleTextStyle = .georgiaTitle3
        descriptionTextStyle = .subheadline
        imageViewDimension = 72
    }
    
    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        distanceLabel.font = UIFont.wmf_font(distanceTextStyle, compatibleWithTraitCollection: traitCollection)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        let displayScale = max(1, traitCollection.displayScale)
        distanceLabelBackground.layer.borderWidth = 1.0 / displayScale
    }
    
    override open func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let size: CGSize = super.sizeThatFits(size, apply: apply)
        let isLTR: Bool = articleSemanticContentAttribute != .forceRightToLeft

        let layoutMargins: UIEdgeInsets = calculatedLayoutMargins
        
        let minHeight: CGFloat = compassViewDimension + layoutMargins.top + layoutMargins.bottom
        //let minHeightMinusMargins: CGFloat = minHeight - layoutMargins.top - layoutMargins.bottom
        
        let widthForLabels: CGFloat = size.width - layoutMargins.left - layoutMargins.right - compassViewDimension - spacing

        let x: CGFloat = isLTR ? layoutMargins.left + compassViewDimension + spacing : layoutMargins.left
       
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
        
        let distanceLabelPadding = UIEdgeInsetsMake(-2, -5, -2, -5)
        let distanceLabelFrame = distanceLabel.wmf_preferredFrame(at: CGPoint(x: origin.x - distanceLabelPadding.left, y: origin.y - distanceLabelPadding.top), maximumWidth: widthForLabels, alignedBy: articleSemanticContentAttribute, apply: apply)
        origin.y += distanceLabelFrame.layoutHeight(with: spacing)
        if apply {
            distanceLabelBackground.frame = UIEdgeInsetsInsetRect(distanceLabelFrame, distanceLabelPadding)
        }
        
        if !isSaveButtonHidden {
            origin.y += spacing
            let saveButtonFrame = saveButton.wmf_preferredFrame(at: origin, maximumWidth: widthForLabels, alignedBy: articleSemanticContentAttribute, apply: apply)
            origin.y += saveButtonFrame.height - 2 * saveButton.verticalPadding + spacing
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
        imageView.backgroundColor = theme.colors.midBackground
        distanceLabel.textColor = theme.colors.secondaryText
        distanceLabelBackground.layer.borderColor = theme.colors.secondaryText.cgColor
        compassView.lineColor = theme.colors.accent
    }
}

class ArticleLocationExploreCollectionViewCell: ArticleLocationCollectionViewCell {
    override open func apply(theme: Theme) {
        super.apply(theme: theme)
        setBackgroundColors(theme.colors.cardBackground, selected: theme.colors.cardBackground)
    }
}
