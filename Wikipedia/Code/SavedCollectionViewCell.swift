import WMF

class ReadingListTag: SizeThatFitsView {
    fileprivate let label: UILabel = UILabel()
    let padding = UIEdgeInsetsMake(3, 3, 3, 3)
    
    override func setup() {
        super.setup()
        layer.borderWidth = 1
        label.isOpaque = true
        addSubview(label)
    }
    
    var readingListName: String = "" {
        didSet {
            label.text = readingListName
            setNeedsLayout()
        }
    }
    
    var labelBackgroundColor: UIColor? {
        didSet {
            label.backgroundColor = labelBackgroundColor
        }
    }
    
    override func tintColorDidChange() {
        label.textColor = tintColor
        layer.borderColor = tintColor.cgColor
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        label.font = UIFont.wmf_preferredFontForFontFamily(.system, withTextStyle: .footnote, compatibleWithTraitCollection: traitCollection)
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let insetSize = UIEdgeInsetsInsetRect(CGRect(origin: .zero, size: size), padding)
        let labelSize = label.sizeThatFits(insetSize.size)
        if (apply) {
            layer.cornerRadius = 3
            label.frame = CGRect(origin: CGPoint(x: 0.5*size.width - 0.5*labelSize.width, y: 0.5*size.height - 0.5*labelSize.height), size: labelSize)

        }
        let width = labelSize.width + padding.left + padding.right
        let height = labelSize.height + padding.top + padding.bottom
        return CGSize(width: width, height: height)
    }
}

class SavedCollectionViewCell: ArticleRightAlignedImageCollectionViewCell {
    
    public var readingLists: [ReadingList] = [] {
        didSet {
            setNeedsLayout()
        }
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let superSize = super.sizeThatFits(size, apply: apply)
        
        var tagHeight: CGFloat = 0
        readingLists.forEach { (readingList) in
            let name = readingList.name
            let tag = ReadingListTag()
            tag.readingListName = name!
            addSubview(tag)
            let tagSize = tag.sizeThatFits(size, apply: true)
            tag.frame = CGRect(origin: CGPoint(x: layoutMargins.left, y: superSize.height - tagSize.height), size: tagSize)
            print("tag.frame: \(tag.frame)")
            tagHeight = tagSize.height
        }
        print("tagHeight: \(tagHeight)")
        return CGSize(width: superSize.width, height: superSize.height + tagHeight)
    }
    
    func configure(readingList: ReadingList, index: Int, count: Int, shouldAdjustMargins: Bool = true, shouldShowSeparators: Bool = false, theme: Theme) {
        isImageViewHidden = true
        titleLabel.text = readingList.name
        descriptionLabel.text = readingList.readingListDescription
        configureCommon(shouldShowSeparators: shouldShowSeparators, index: index, theme: theme, shouldAdjustMargins: shouldAdjustMargins, count: count)
    }
    
    func configure(article: WMFArticle, index: Int, count: Int, shouldAdjustMargins: Bool = true, shouldShowSeparators: Bool = false, theme: Theme, layoutOnly: Bool) {
        titleLabel.text = article.displayTitle
        descriptionLabel.text = article.capitalizedWikidataDescriptionOrSnippet
        
        let imageWidthToRequest = imageView.frame.size.width < 300 ? traitCollection.wmf_nearbyThumbnailWidth : traitCollection.wmf_leadImageWidth // 300 is used to distinguish between full-awidth images and thumbnails. Ultimately this (and other thumbnail requests) should be updated with code that checks all the available buckets for the width that best matches the size of the image view.
        if let imageURL = article.imageURL(forWidth: imageWidthToRequest) {
            isImageViewHidden = false
            if !layoutOnly {
                imageView.wmf_setImage(with: imageURL, detectFaces: true, onGPU: true, failure: { (error) in }, success: { })
            }
        } else {
            isImageViewHidden = true
        }
        
        let articleLanguage = article.url?.wmf_language
        titleLabel.accessibilityLanguage = articleLanguage
        descriptionLabel.accessibilityLanguage = articleLanguage
        extractLabel?.accessibilityLanguage = articleLanguage
        articleSemanticContentAttribute = MWLanguageInfo.semanticContentAttribute(forWMFLanguage: articleLanguage)
        
        configureCommon(shouldShowSeparators: shouldShowSeparators, index: index, theme: theme, shouldAdjustMargins: shouldAdjustMargins, count: count)
    }

    fileprivate func configureCommon(shouldShowSeparators: Bool = false, index: Int, theme: Theme, shouldAdjustMargins: Bool = true, count: Int) {
        if shouldShowSeparators {
            topSeparator.isHidden = index != 0
            bottomSeparator.isHidden = false
        } else {
            bottomSeparator.isHidden = true
        }
        apply(theme: theme)
        isSaveButtonHidden = true
        extractLabel?.text = nil
        imageViewDimension = 40
        if (shouldAdjustMargins) {
            adjustMargins(for: index, count: count)
        }
        setNeedsLayout()
    }
    
}
