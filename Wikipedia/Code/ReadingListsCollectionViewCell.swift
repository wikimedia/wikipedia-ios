import WMFComponents
import WMFNativeLocalizations
import WMFData

class ReadingListsCollectionViewCell: ArticleCollectionViewCell {
    private var bottomSeparator = UIView()
    private var topSeparator = UIView()

    private let imageGrid = UIView()
    private var gridImageViews: [UIImageView] = []

    private var isDefault: Bool = false

    private var singlePixelDimension: CGFloat = 0.5

    override func setup() {
        imageView.layer.cornerRadius = 3

        bottomSeparator.isOpaque = true
        contentView.addSubview(bottomSeparator)
        topSeparator.isOpaque = true
        contentView.addSubview(topSeparator)

        let topRow = UIStackView(arrangedSubviews: [UIImageView(), UIImageView()])
        topRow.axis = NSLayoutConstraint.Axis.horizontal
        topRow.distribution = UIStackView.Distribution.fillEqually

        let bottomRow = UIStackView(arrangedSubviews: [UIImageView(), UIImageView()])
        bottomRow.axis = NSLayoutConstraint.Axis.horizontal
        bottomRow.distribution = UIStackView.Distribution.fillEqually

        gridImageViews = (topRow.arrangedSubviews + bottomRow.arrangedSubviews).compactMap { $0 as? UIImageView }

        gridImageViews.forEach {
            $0.accessibilityIgnoresInvertColors = true
            $0.contentMode = .scaleAspectFill
            $0.clipsToBounds = true
        }

        let outermostStackView = UIStackView(arrangedSubviews: [topRow, bottomRow])
        outermostStackView.axis = NSLayoutConstraint.Axis.vertical
        outermostStackView.distribution = UIStackView.Distribution.fillEqually

        imageGrid.addSubview(outermostStackView)
        outermostStackView.frame = imageGrid.frame
        outermostStackView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        imageGrid.layer.cornerRadius = 3
        imageGrid.masksToBounds = true
        contentView.addSubview(imageGrid)

        singlePixelDimension = traitCollection.displayScale > 0 ? 1.0 / traitCollection.displayScale : 0.5

        registerForTraitChanges([UITraitDisplayScale.self]) { [weak self] (cell: Self, previousTraitCollection: UITraitCollection) in
            guard let self else { return }
            self.singlePixelDimension = self.traitCollection.displayScale > 0 ? 1.0 / self.traitCollection.displayScale : 0.5
        }

        super.setup()
    }

    open override func reset() {
        super.reset()
        bottomSeparator.isHidden = true
        topSeparator.isHidden = true
        updateFonts(with: traitCollection)
    }

    override func updateStyles() {
        styles = HtmlUtils.Styles(font: WMFFont.for(.boldCallout, compatibleWith: traitCollection), boldFont: WMFFont.for(.boldCallout, compatibleWith: traitCollection), italicsFont: WMFFont.for(.italicCallout, compatibleWith: traitCollection), boldItalicsFont: WMFFont.for(.boldItalicCallout, compatibleWith: traitCollection), color: theme.colors.primaryText, linkColor: theme.colors.link, lineSpacing: 1)
    }

    override open func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let size = super.sizeThatFits(size, apply: apply)
        let layoutMargins = calculatedLayoutMargins

        var widthMinusMargins = size.width - layoutMargins.left - layoutMargins.right
        let minHeight = imageViewDimension + layoutMargins.top + layoutMargins.bottom
        let minHeightMinusMargins = minHeight - layoutMargins.top - layoutMargins.bottom

        let labelsAdditionalSpacing: CGFloat = 20
        if !isImageGridHidden || !isImageViewHidden {
            widthMinusMargins = widthMinusMargins - spacing - imageViewDimension - labelsAdditionalSpacing
        }

        var x = layoutMargins.left
        if isArticleRTL {
            x = size.width - x - widthMinusMargins
        }
        var origin = CGPoint(x: x, y: layoutMargins.top)

        let labelHorizontalAlignment: HorizontalAlignment = isArticleRTL ? .right : .left

        if isDefault {
            let titleLabelFrame = titleLabel.wmf_preferredFrame(at: origin, maximumWidth: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
            origin.y += titleLabelFrame.layoutHeight(with: 0)
            let descriptionLabelFrame = descriptionLabel.wmf_preferredFrame(at: origin, maximumWidth: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
            origin.y += descriptionLabelFrame.layoutHeight(with: 0)
        } else {
            let titleLabelFrame = titleLabel.wmf_preferredFrame(at: CGPoint(x: origin.x, y: layoutMargins.top), maximumSize: CGSize(width: widthMinusMargins, height: UIView.noIntrinsicMetric), minimumSize: CGSize(width: UIView.noIntrinsicMetric, height: minHeightMinusMargins), horizontalAlignment: labelHorizontalAlignment, verticalAlignment: .center, apply: apply)
            origin.y += titleLabelFrame.layoutHeight(with: 0)
        }

        descriptionLabel.isHidden = !descriptionLabel.wmf_hasText

        origin.y += layoutMargins.bottom
        let height = max(origin.y, minHeight)
        let separatorXPositon: CGFloat = 0
        let separatorWidth = size.width

        if apply {
            if !bottomSeparator.isHidden {
                bottomSeparator.frame = CGRect(x: separatorXPositon, y: height - singlePixelDimension, width: separatorWidth, height: singlePixelDimension)
            }

            if !topSeparator.isHidden {
                topSeparator.frame = CGRect(x: separatorXPositon, y: 0, width: separatorWidth, height: singlePixelDimension)
            }
        }

        if apply {
            let imageViewY = floor(0.5*height - 0.5*imageViewDimension)
            var x = layoutMargins.right
            if !isArticleRTL {
                x = size.width - x - imageViewDimension
            }
            imageGrid.frame = CGRect(x: x, y: imageViewY, width: imageViewDimension, height: imageViewDimension)
            imageGrid.isHidden = isImageGridHidden
        }

        if apply && !isImageViewHidden {
            let imageViewY = floor(0.5*height - 0.5*imageViewDimension)
            var x = layoutMargins.right
            if !isArticleRTL {
                x = size.width - x - imageViewDimension
            }
            imageView.frame = CGRect(x: x, y: imageViewY, width: imageViewDimension, height: imageViewDimension)
        }

        return CGSize(width: size.width, height: height)
    }

    override func configureForCompactList(at index: Int) {
        layoutMarginsAdditions.top = 5
        layoutMarginsAdditions.bottom = 5
        styles = HtmlUtils.Styles(font: WMFFont.for(.subheadline, compatibleWith: traitCollection), boldFont: WMFFont.for(.boldSubheadline, compatibleWith: traitCollection), italicsFont: WMFFont.for(.italicSubheadline, compatibleWith: traitCollection), boldItalicsFont: WMFFont.for(.boldItalicSubheadline, compatibleWith: traitCollection), color: theme.colors.primaryText, linkColor: theme.colors.link, lineSpacing: 1)
        descriptionTextStyle = .footnote
        updateFonts(with: traitCollection)
        imageViewDimension = 40
    }

    private var isImageGridHidden: Bool = false {
        didSet {
            imageGrid.isHidden = isImageGridHidden
            setNeedsLayout()
        }
    }

    func configure(readingList: ReadingList, isDefault: Bool = false, index: Int, shouldShowSeparators: Bool = false, theme: Theme, lastFourArticlesWithLeadImages: [WMFArticle], layoutOnly: Bool) {
        configure(with: readingList.name, description: readingList.readingListDescription, isDefault: isDefault, index: index, shouldShowSeparators: shouldShowSeparators, theme: theme, lastFourArticlesWithLeadImages: lastFourArticlesWithLeadImages, layoutOnly: layoutOnly)
    }

    func configure(with name: String?, description: String?, isDefault: Bool = false, index: Int, shouldShowSeparators: Bool = false, theme: Theme, lastFourArticlesWithLeadImages: [WMFArticle], layoutOnly: Bool) {

        articleSemanticContentAttribute = .unspecified

        self.isDefault = isDefault
        isAlertButtonHidden = true

        titleLabel.text = name
        descriptionLabel.text = description

        let imageWidthToRequest = imageView.frame.size.width < 300 ? ImageUtils.nearbyThumbnailWidth() : ImageUtils.leadImageWidth()
        let imageURLs = lastFourArticlesWithLeadImages.compactMap { $0.imageURL(forWidth: imageWidthToRequest) }

        isImageGridHidden = imageURLs.count != 4 // we need 4 images for the grid
        isImageViewHidden = !(isImageGridHidden && imageURLs.count >= 1) // we need at least one image to display

        if !layoutOnly && !isImageGridHidden {
            _ = zip(gridImageViews, imageURLs).compactMap { $0.wmf_setImage(with: $1, detectFaces: true, failure: { (error) in }, success: { })}
        }

        if isImageGridHidden, let imageURL = imageURLs.first {
            if !layoutOnly {
                imageView.wmf_setImage(with: imageURL, detectFaces: true, failure: { (error) in }, success: { })
            }
        } else {
            isImageViewHidden = true
        }

        configureForCompactList(at: index)

        if shouldShowSeparators {
            topSeparator.isHidden = true
            bottomSeparator.isHidden = false
        } else {
            topSeparator.isHidden = true
            bottomSeparator.isHidden = true
        }

        apply(theme: theme)
        extractLabel?.text = nil
        setNeedsLayout()
    }

    public override func apply(theme: Theme) {
        super.apply(theme: theme)
        bottomSeparator.backgroundColor = theme.colors.border
        topSeparator.backgroundColor = theme.colors.border
    }
}

