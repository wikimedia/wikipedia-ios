import WMFComponents

class ReadingListsCollectionViewCell: ArticleCollectionViewCell {
    private var bottomSeparator = UIView()
    private var topSeparator = UIView()
    
    private var articleCountLabel = UILabel()
    var articleCount: Int64 = 0
    
    private let imageGrid = UIView()
    private var gridImageViews: [UIImageView] = []
    
    private var isDefault: Bool = false
    private let defaultListTag = UILabel() // explains that the default list cannot be deleted
    
    private var singlePixelDimension: CGFloat = 0.5
    
    private var displayType: ReadingListsDisplayType = .readingListsTab

    override var alertType: ReadingListAlertType? {
        didSet {
            guard let alertType = alertType else {
                return
            }
            var alertLabelText: String? = nil
            switch alertType {
            case .listLimitExceeded:
                alertLabelText = WMFLocalizedString("reading-lists-list-not-synced-limit-exceeded", value: "List not synced, limit exceeded", comment: "Text of the alert label informing the user that list couldn't be synced.")
            case .entryLimitExceeded:
                alertLabelText = WMFLocalizedString("reading-lists-articles-not-synced-limit-exceeded", value: "Some articles not synced, limit exceeded", comment: "Text of the alert label informing the user that some articles couldn't be synced.")
            default:
                break
            }
            alertButton.setTitle(alertLabelText, for: .normal)
            alertButton.setImage(UIImage(named: "error-icon"), for: .normal)
            setNeedsLayout()
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        singlePixelDimension = traitCollection.displayScale > 0 ? 1.0 / traitCollection.displayScale : 0.5
    }
    
    override func setup() {
        imageView.layer.cornerRadius = 3
        
        bottomSeparator.isOpaque = true
        contentView.addSubview(bottomSeparator)
        topSeparator.isOpaque = true
        contentView.addSubview(topSeparator)
        
        contentView.addSubview(articleCountLabel)
        contentView.addSubview(defaultListTag)
        
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
    
    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        articleCountLabel.font = WMFFont.for(.caption1, compatibleWith: traitCollection)
        defaultListTag.font = WMFFont.for(.italicCaption1, compatibleWith: traitCollection)
    }
    
    override func updateBackgroundColorOfLabels() {
        super.updateBackgroundColorOfLabels()
        articleCountLabel.backgroundColor = labelBackgroundColor
        defaultListTag.backgroundColor = labelBackgroundColor
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
        
        if displayType == .readingListsTab {
            let articleCountLabelSize = articleCountLabel.intrinsicContentSize
            var x = origin.x
            if isArticleRTL {
                x = size.width - articleCountLabelSize.width - layoutMargins.left
            }
            let articleCountLabelFrame = articleCountLabel.wmf_preferredFrame(at: CGPoint(x: x, y: origin.y), maximumSize: articleCountLabelSize, alignedBy: articleSemanticContentAttribute, apply: apply)
            origin.y += articleCountLabelFrame.layoutHeight(with: spacing)
            articleCountLabel.isHidden = false
        } else {
            articleCountLabel.isHidden = true
        }
        
        let labelHorizontalAlignment: HorizontalAlignment = isArticleRTL ? .right : .left
        
        if displayType == .addArticlesToReadingList {
            if isDefault {
                let titleLabelFrame = titleLabel.wmf_preferredFrame(at: origin, maximumWidth: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
                origin.y += titleLabelFrame.layoutHeight(with: 0)
                let descriptionLabelFrame = descriptionLabel.wmf_preferredFrame(at: origin, maximumWidth: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
                origin.y += descriptionLabelFrame.layoutHeight(with: 0)
            } else {
                let titleLabelFrame = titleLabel.wmf_preferredFrame(at: CGPoint(x: origin.x, y: layoutMargins.top), maximumSize: CGSize(width: widthMinusMargins, height: UIView.noIntrinsicMetric), minimumSize: CGSize(width: UIView.noIntrinsicMetric, height: minHeightMinusMargins), horizontalAlignment: labelHorizontalAlignment, verticalAlignment: .center, apply: apply)
                origin.y += titleLabelFrame.layoutHeight(with: 0)
            }
        } else if descriptionLabel.wmf_hasText || !isImageGridHidden || !isImageViewHidden {
            let titleLabelFrame = titleLabel.wmf_preferredFrame(at: origin, maximumWidth: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
            origin.y += titleLabelFrame.layoutHeight(with: spacing)
            
            let descriptionLabelFrame = descriptionLabel.wmf_preferredFrame(at: origin, maximumWidth: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
            origin.y += descriptionLabelFrame.layoutHeight(with: 0)
        } else {
            let titleLabelFrame = titleLabel.wmf_preferredFrame(at: origin, maximumSize: CGSize(width: widthMinusMargins, height: UIView.noIntrinsicMetric), minimumSize: CGSize(width: UIView.noIntrinsicMetric, height: minHeightMinusMargins), horizontalAlignment: labelHorizontalAlignment, verticalAlignment: .center, apply: apply)
            origin.y += titleLabelFrame.layoutHeight(with: 0)
            if !isAlertButtonHidden {
                origin.y += titleLabelFrame.layoutHeight(with: spacing) + spacing * 2
            }
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
        
        let yAlignedWithImageBottom = imageGrid.frame.maxY - layoutMargins.bottom - (0.5 * spacing)

        if apply && !isAlertButtonHidden {
            let effectiveImageDimension = isImageViewHidden ? 0 : imageViewDimension + spacing
            let xPosition = isArticleRTL ? layoutMargins.right + effectiveImageDimension : layoutMargins.left
            let maxButtonHeight: CGFloat = 44
            let yPosition = height - layoutMargins.bottom - maxButtonHeight
            let availableWidth = layoutWidth(for: size) - spacing - effectiveImageDimension // don't reuse widthMinusMargins
            let origin = CGPoint(x: xPosition, y: yPosition)
            alertButton.wmf_preferredFrame(at: origin, maximumSize: CGSize(width: availableWidth, height: maxButtonHeight), minimumSize: .zero, horizontalAlignment: isArticleRTL ? .right : .left, verticalAlignment: .bottom, apply: apply)
        }
        
        if displayType == .readingListsTab && isDefault {
            let defaultListTagSize = defaultListTag.intrinsicContentSize
            var x = origin.x
            if isArticleRTL {
                x = size.width - defaultListTagSize.width - layoutMargins.right
            }
            var y = yAlignedWithImageBottom
            if !isAlertButtonHidden {
                let alertMinY = alertButton.frame.minY
                y = descriptionLabel.frame.maxY + ((alertMinY - descriptionLabel.frame.maxY) * 0.25)
            }
            _ = defaultListTag.wmf_preferredFrame(at: CGPoint(x: x, y: y), maximumSize: defaultListTagSize, alignedBy: articleSemanticContentAttribute, apply: apply)
            defaultListTag.isHidden = false
        } else {
            defaultListTag.isHidden = true
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
    
    func configureAlert(for readingList: ReadingList, listLimit: Int, entryLimit: Int) {
        guard let error = readingList.APIError else {
            return
        }
        
        switch error {
        case .listLimit:
            isAlertButtonHidden = false
            alertType = .listLimitExceeded(limit: listLimit)
        case .entryLimit:
            isAlertButtonHidden = false
            alertType = .entryLimitExceeded(limit: entryLimit)
        default:
            isAlertButtonHidden = true
        }
        
        let isAddArticlesToReadingListDisplayType = displayType == .addArticlesToReadingList
        isAlertButtonHidden = isAddArticlesToReadingListDisplayType
    }
    
    func configure(readingList: ReadingList, isDefault: Bool = false, index: Int, shouldShowSeparators: Bool = false, theme: Theme, for displayType: ReadingListsDisplayType, articleCount: Int64, lastFourArticlesWithLeadImages: [WMFArticle], layoutOnly: Bool) {
        configure(with: readingList.name, description: readingList.readingListDescription, isDefault: isDefault, index: index, shouldShowSeparators: shouldShowSeparators, theme: theme, for: displayType, articleCount: articleCount, lastFourArticlesWithLeadImages: lastFourArticlesWithLeadImages, layoutOnly: layoutOnly)
    }
    
    func configure(with name: String?, description: String?, isDefault: Bool = false, index: Int, shouldShowSeparators: Bool = false, theme: Theme, for displayType: ReadingListsDisplayType, articleCount: Int64, lastFourArticlesWithLeadImages: [WMFArticle], layoutOnly: Bool) {
        
        articleSemanticContentAttribute = .unspecified
        
        imageViewDimension = 100

        self.displayType = displayType
        self.isDefault = isDefault
        self.articleCount = articleCount
    
        articleCountLabel.text = String.localizedStringWithFormat(CommonStrings.articleCountFormat, articleCount).uppercased()
        defaultListTag.text = WMFLocalizedString("saved-default-reading-list-tag", value: "This list cannot be deleted", comment: "Tag on the default reading list cell explaining that the list cannot be deleted")
        titleLabel.text = name
        descriptionLabel.text = description
        
        let imageWidthToRequest = imageView.frame.size.width < 300 ? traitCollection.wmf_nearbyThumbnailWidth : traitCollection.wmf_leadImageWidth
        let imageURLs = lastFourArticlesWithLeadImages.compactMap { $0.imageURL(forWidth: imageWidthToRequest) }
        
        isImageGridHidden = imageURLs.count != 4 // we need 4 images for the grid
        isImageViewHidden = !(isImageGridHidden && imageURLs.count >= 1) // we need at least one image to display
        
        if !layoutOnly && !isImageGridHidden {
            _ = zip(gridImageViews, imageURLs).compactMap { $0.wmf_setImage(with: $1, detectFaces: true, onGPU: true, failure: { (error) in }, success: { })}
        }
        
        if isImageGridHidden, let imageURL = imageURLs.first {
            if !layoutOnly {
                imageView.wmf_setImage(with: imageURL, detectFaces: true, onGPU: true, failure: { (error) in }, success: { })
            }
        } else {
            isImageViewHidden = true
        }
        
        if displayType == .addArticlesToReadingList {
            configureForCompactList(at: index)
        }
        
        if shouldShowSeparators {
            topSeparator.isHidden = index > 0
            bottomSeparator.isHidden = false
        } else {
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
        articleCountLabel.textColor = theme.colors.secondaryText
        defaultListTag.textColor = theme.colors.secondaryText
    }
}

