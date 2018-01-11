class ReadingListsCollectionViewCell: ArticleCollectionViewCell {
    fileprivate var bottomSeparator = UIView()
    fileprivate var topSeparator = UIView()
    fileprivate var articleCountLabel = UILabel()
    var articleCount: Int = 0
    
    fileprivate var singlePixelDimension: CGFloat = 0.5
    
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
        super.setup()
    }
    
    fileprivate var displayType: ReadingListsDisplayType = .readingListsTab {
        didSet {
            guard displayType == .addArticlesToReadingList else {
                return
            }
            layoutMarginsMultipliers.top = 2
            layoutMarginsMultipliers.bottom = 2
            imageViewDimension = 40
        }
    }
    
    fileprivate var isDefault: Bool = false
    
    open override func reset() {
        super.reset()
        bottomSeparator.isHidden = true
        topSeparator.isHidden = true
        titleFontFamily = .system
        titleTextStyle = .body
        updateFonts(with: traitCollection)
    }
    
    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        articleCountLabel.setFont(with: .system, style: .caption2, traitCollection: traitCollection)
    }
    
    override open func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let size = super.sizeThatFits(size, apply: apply)
        let isRTL = articleSemanticContentAttribute == .forceRightToLeft
        
        let margins = self.layoutMargins
        let multipliers = self.layoutMarginsMultipliers
        let layoutMargins = UIEdgeInsets(top: round(margins.top * multipliers.top) + layoutMarginsAdditions.top, left: round(margins.left * multipliers.left) + layoutMarginsAdditions.left, bottom: round(margins.bottom * multipliers.bottom) + layoutMarginsAdditions.bottom, right: round(margins.right * multipliers.right) + layoutMarginsAdditions.right)
        
        var widthMinusMargins = size.width - layoutMargins.left - layoutMargins.right
        let minHeight = imageViewDimension + layoutMargins.top + layoutMargins.bottom
        let minHeightMinusMargins = minHeight - layoutMargins.top - layoutMargins.bottom
        
        if !isImageViewHidden {
            widthMinusMargins = widthMinusMargins - spacing - imageViewDimension
        }
        
        var x = layoutMargins.left
        if isRTL {
            x = size.width - x - widthMinusMargins
        }
        var origin = CGPoint(x: x, y: layoutMargins.top)
        
        if apply && displayType == .readingListsTab && articleCount > 0 {
            let articleCountLabelFrame = articleCountLabel.wmf_preferredFrame(at: origin, fitting: articleCountLabel.intrinsicContentSize, alignedBy: articleSemanticContentAttribute, apply: apply)
            origin.y += articleCountLabelFrame.layoutHeight(with: spacing)
        }

        if descriptionLabel.wmf_hasText || !isSaveButtonHidden || !isImageViewHidden {
            let titleLabelFrame = titleLabel.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
            origin.y += titleLabelFrame.layoutHeight(with: spacing)
            
            let descriptionLabelFrame = descriptionLabel.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
            origin.y += descriptionLabelFrame.layoutHeight(with: 0)
            descriptionLabel.isHidden = displayType == .addArticlesToReadingList && !isDefault
            
            if !isSaveButtonHidden {
                origin.y += spacing
                origin.y += saveButtonTopSpacing - saveButton.verticalPadding
                let saveButtonFrame = saveButton.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
                origin.y += saveButtonFrame.height - saveButton.verticalPadding
            }
        } else {
            let horizontalAlignment: HorizontalAlignment = isRTL ? .right : .left
            let titleLabelFrame = titleLabel.wmf_preferredFrame(at: CGPoint(x: layoutMargins.left, y: layoutMargins.top), maximumViewSize: CGSize(width: widthMinusMargins, height: UIViewNoIntrinsicMetric), minimumLayoutAreaSize: CGSize(width: UIViewNoIntrinsicMetric, height: minHeightMinusMargins), horizontalAlignment: horizontalAlignment, verticalAlignment: .center, apply: apply)
            origin.y += titleLabelFrame.layoutHeight(with: 0)
            descriptionLabel.isHidden = true
        }
        
        origin.y += layoutMargins.bottom
        let height = max(origin.y, minHeight)
        print("height: \(height)")
        
        let separatorXPositon = layoutMargins.left - margins.left
        let separatorWidth = size.width - imageViewDimension * 1.5 - separatorXPositon // size.width when isImageViewHidden?
        
        if (apply) {
            if (!bottomSeparator.isHidden) {
                bottomSeparator.frame = CGRect(x: separatorXPositon, y: height - singlePixelDimension, width: separatorWidth, height: singlePixelDimension)
            }
            
            if (!topSeparator.isHidden) {
                topSeparator.frame = CGRect(x: separatorXPositon, y: 0, width: separatorWidth, height: singlePixelDimension)
            }
        }
        
        if (apply && !isImageViewHidden) {
            let imageViewY = floor(0.5*height - 0.5*imageViewDimension)
            var x = layoutMargins.right
            if !isRTL {
                x = size.width - x - imageViewDimension
            }
            imageView.frame = CGRect(x: x, y: imageViewY, width: imageViewDimension, height: imageViewDimension)
        }
                
        return CGSize(width: size.width, height: height)
    }
    
    func configure(readingList: ReadingList, isDefault: Bool = false, index: Int, count: Int, shouldAdjustMargins: Bool = true, shouldShowSeparators: Bool = false, theme: Theme, for displayType: ReadingListsDisplayType, articleCount: Int, firstFourArticles: [WMFArticle], layoutOnly: Bool) {
        configure(with: readingList.name, description: readingList.readingListDescription, isDefault: isDefault, index: index, count: count, shouldAdjustMargins: shouldAdjustMargins, shouldShowSeparators: shouldShowSeparators, theme: theme, for: displayType, articleCount: articleCount, firstFourArticles: firstFourArticles, layoutOnly: layoutOnly)
    }
    
    func configure(with name: String?, description: String?, isDefault: Bool = false, index: Int, count: Int, shouldAdjustMargins: Bool = true, shouldShowSeparators: Bool = false, theme: Theme, for displayType: ReadingListsDisplayType, articleCount: Int, firstFourArticles: [WMFArticle], layoutOnly: Bool) {
        
        imageViewDimension = 80

        self.displayType = displayType
        self.isDefault = isDefault
        self.articleCount = articleCount
        
        articleCountLabel.text = articleCount > 1 ? "\(articleCount) articles" : "\(articleCount) article"
        titleLabel.text = name
        descriptionLabel.text = description
        
        let imageWidthToRequest = imageView.frame.size.width < 300 ? traitCollection.wmf_nearbyThumbnailWidth : traitCollection.wmf_leadImageWidth // 300 is used to distinguish between full-awidth images and thumbnails. Ultimately this (and other thumbnail requests) should be updated with code that checks all the available buckets for the width that best matches the size of the image view.
        if let imageURL = firstFourArticles.first?.imageURL(forWidth: imageWidthToRequest) {
            isImageViewHidden = false
            if !layoutOnly {
                imageView.wmf_setImage(with: imageURL, detectFaces: true, onGPU: true, failure: { (error) in }, success: { })
            }
        } else {
            isImageViewHidden = true
        }
        
        if shouldShowSeparators {
            bottomSeparator.isHidden = false
        } else {
            bottomSeparator.isHidden = true
        }
        apply(theme: theme)
        isSaveButtonHidden = true
        extractLabel?.text = nil
        if (shouldAdjustMargins) {
            adjustMargins(for: index, count: count)
        }
        setNeedsLayout()
    }
    
    public override func apply(theme: Theme) {
        super.apply(theme: theme)
        bottomSeparator.backgroundColor = theme.colors.border
        topSeparator.backgroundColor = theme.colors.border
        articleCountLabel.textColor = theme.colors.secondaryText
    }
}

