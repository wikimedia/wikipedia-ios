public protocol SavedArticlesCollectionViewCellDelegate: NSObjectProtocol {
    func didSelect(_ tag: Tag)
}

class SavedArticlesCollectionViewCell: ArticleCollectionViewCell {
    fileprivate var bottomSeparator = UIView()
    fileprivate var topSeparator = UIView()
    
    fileprivate var singlePixelDimension: CGFloat = 0.5
    
    public var tags: (readingLists: [ReadingList], indexPath: IndexPath) = (readingLists: [], indexPath: IndexPath()) {
        didSet {
            collectionView.reloadData()
            setNeedsLayout()
        }
    }
    
    fileprivate lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(TagCollectionViewCell.self, forCellWithReuseIdentifier: TagCollectionViewCell.reuseIdentifier)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = .clear
        return collectionView
    }()
    
    fileprivate lazy var layout: UICollectionViewFlowLayout? = {
        let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        layout?.scrollDirection = .horizontal
        layout?.sectionInset = UIEdgeInsets.zero
        return layout
    }()
    
    fileprivate lazy var placeholderCell: TagCollectionViewCell = {
        return TagCollectionViewCell()
    }()
    
    fileprivate var theme: Theme = Theme.standard // stored to theme TagCollectionViewCell
    
    weak public var delegate: SavedArticlesCollectionViewCellDelegate?
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        singlePixelDimension = traitCollection.displayScale > 0 ? 1.0/traitCollection.displayScale : 0.5
    }
    
    override func setup() {
        imageView.layer.cornerRadius = 3
        bottomSeparator.isOpaque = true
        contentView.addSubview(bottomSeparator)
        topSeparator.isOpaque = true
        contentView.addSubview(topSeparator)
        contentView.addSubview(collectionView)
        contentView.addSubview(placeholderCell)
        
        wmf_configureSubviewsForDynamicType()
        placeholderCell.isHidden = true

        super.setup()
    }
    
    open override func reset() {
        super.reset()
        bottomSeparator.isHidden = true
        topSeparator.isHidden = true
        titleFontFamily = .system
        titleTextStyle = .body
        updateFonts(with: traitCollection)
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
        
        if descriptionLabel.wmf_hasText || !isSaveButtonHidden || !isImageViewHidden {
            let titleLabelFrame = titleLabel.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
            origin.y += titleLabelFrame.layoutHeight(with: spacing)
            
            let descriptionLabelFrame = descriptionLabel.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
            origin.y += descriptionLabelFrame.layoutHeight(with: 0)
            descriptionLabel.isHidden = false
            
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
        
        let separatorXPositon: CGFloat = 0
        let separatorWidth = size.width
        
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
        
        let tagsCount: CGFloat = CGFloat(tags.readingLists.count)
        if (apply && tagsCount != 0), let layout = layout {
            collectionView.frame = CGRect(x: layoutMargins.left, y: origin.y, width: separatorWidth, height: layout.itemSize.height)
        }
        
        return CGSize(width: size.width, height: height)
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
        
        if shouldShowSeparators {
            topSeparator.isHidden = index > 0
            bottomSeparator.isHidden = false
        } else {
            bottomSeparator.isHidden = true
        }
        self.theme = theme
        apply(theme: theme)
        isSaveButtonHidden = true
        extractLabel?.text = nil
        imageViewDimension = 80
        if (shouldAdjustMargins) {
            adjustMargins(for: index, count: count)
        }
        setNeedsLayout()
    }
    
    public override func apply(theme: Theme) {
        super.apply(theme: theme)
        collectionView.visibleCells.forEach { ($0 as? TagCollectionViewCell)?.apply(theme: theme) }
        bottomSeparator.backgroundColor = theme.colors.border
        topSeparator.backgroundColor = theme.colors.border
    }
    
    fileprivate func tag(at indexPath: IndexPath) -> Tag {
        return Tag(readingList: tags.readingLists[indexPath.item], index: indexPath.item, indexPath: tags.indexPath)
    }
}

// MARK: - UICollectionViewDataSource

extension SavedArticlesCollectionViewCell: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tags.readingLists.count > 3 ? 3 : tags.readingLists.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TagCollectionViewCell.reuseIdentifier, for: indexPath)
        guard let tagCell = cell as? TagCollectionViewCell else {
            return cell
        }
        tagCell.configure(with: tag(at: indexPath), for: tags.readingLists.count, theme: theme)
        return tagCell
    }

}

// MARK: - UICollectionViewDelegate

extension SavedArticlesCollectionViewCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.didSelect(tag(at: indexPath))
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

extension SavedArticlesCollectionViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard tags.readingLists.count != 0 else {
            return .zero
        }
        
        placeholderCell.configure(with: tag(at: indexPath), for: tags.readingLists.count, theme: theme)
        let size = placeholderCell.wmf_preferredFrame(at: .zero, fitting: placeholderCell.width, alignedBy: semanticContentAttribute, apply: false).size
        // simply returning size is not altering the item's size
        layout?.itemSize = size
        setNeedsLayout()
        return size
    }
}

