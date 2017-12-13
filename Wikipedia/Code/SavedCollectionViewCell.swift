import WMF

class ReadingListTagsView: SizeThatFitsView {
    var buttons: [UIButton] = []
    fileprivate var needsSubviews = false
    
    var readingLists: [ReadingList] = [] {
        didSet {
            needsSubviews = true
        }
    }
    
    public override var frame: CGRect {
        didSet {
            setNeedsLayout()
        }
    }
    
    fileprivate let minButtonWidth: CGFloat = 26
    var maximumWidth: CGFloat = 0
    var buttonWidth: CGFloat  = 0
    
    fileprivate func createSubviews() {
        for view in subviews {
            view.removeFromSuperview()
        }
        
        var maxButtonWidth: CGFloat = 0
        
        for (index, readingList) in readingLists.enumerated() {
            guard let name = readingList.name else {
                assertionFailure("Reading list with no name")
                return
            }
            let button = UIButton(type: .custom)
            button.setTitle(name, for: .normal)
            button.titleLabel?.numberOfLines = 1
            button.contentEdgeInsets = UIEdgeInsetsMake(6, 6, 6, 6)
            button.backgroundColor = UIColor.blue
            button.tag = index
            button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
            maxButtonWidth = max(maxButtonWidth, button.intrinsicContentSize.width)
            insertSubview(button, at: 0)
            buttons.append(button)
        }
        buttonWidth = max(minButtonWidth, maxButtonWidth)
        maximumWidth = buttonWidth * CGFloat(subviews.count)
        setNeedsLayout()
    }
    
    @objc fileprivate func buttonPressed(_ sender: UIButton) {
        let readingList = readingLists[sender.tag]
        print("pressed \(readingList.name)")
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        var height: CGFloat = 0
        if apply {
            if size.width > 0 && needsSubviews {
                createSubviews()
                needsSubviews = false
            }
            let numberOfButtons = CGFloat(subviews.count)
            let buttonDelta = (min(size.width, maximumWidth) / numberOfButtons) + 5
            var x: CGFloat = 0
            for button in buttons {
                button.frame = CGRect(x: x, y: 0, width: buttonWidth, height: button.intrinsicContentSize.height)
                x += buttonDelta
                height = button.intrinsicContentSize.height
            }
        }
        return CGSize(width: maximumWidth, height: height)

    }
}

class SavedCollectionViewCell: ArticleRightAlignedImageCollectionViewCell {
    
    public var readingLists: [ReadingList] = [] {
        didSet {
            contentView.insertSubview(readingListTagsView, at: 0)
            imageViewDimension = 70
            readingListTagsView.readingLists = readingLists
            setNeedsLayout()
        }
    }
    
    fileprivate lazy var readingListTagsView: ReadingListTagsView = {
        return ReadingListTagsView()
    }()
    
    override func reset() {
        super.reset()
        readingListTagsView.removeFromSuperview()
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let superSize = super.sizeThatFits(size, apply: apply)
        guard !readingLists.isEmpty else {
            return superSize
        }
        let tagsViewSize = readingListTagsView.sizeThatFits(size, apply: true)
        let newSize = CGSize(width: superSize.width, height: superSize.height)
        readingListTagsView.frame = CGRect(origin: CGPoint(x: layoutMargins.left, y: newSize.height - tagsViewSize.height), size: tagsViewSize)
        print("readingListTagsView.frame: \(readingListTagsView.frame.origin.y)")
        return newSize
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
