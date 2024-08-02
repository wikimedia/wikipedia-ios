import WMFComponents

public protocol SavedArticlesCollectionViewCellDelegate: NSObjectProtocol {
    func didSelect(_ tag: Tag)
}

class SavedArticlesCollectionViewCell: ArticleCollectionViewCell {
    private var bottomSeparator = UIView()
    private var topSeparator = UIView()
    
    private var singlePixelDimension: CGFloat = 0.5
    
    public var tags: (readingLists: [ReadingList], indexPath: IndexPath) = (readingLists: [], indexPath: IndexPath()) {
        didSet {
            configuredTags = []
            collectionView.reloadData()
            setNeedsLayout()
        }
    }
    
    private var configuredTags: [Tag] = [] {
        didSet {
            setNeedsLayout()
        }
    }
    
    private var isTagsViewHidden: Bool = true {
        didSet {
            collectionView.isHidden = isTagsViewHidden
            setNeedsLayout()
        }
    }
    
    override var alertType: ReadingListAlertType? {
        didSet {
            guard let alertType = alertType else {
                return
            }
            var alertLabelText: String? = nil
            let alertImage: UIImage? = UIImage(named: "error-icon")
            
            switch alertType {
            case .listLimitExceeded:
                alertLabelText = WMFLocalizedString("reading-lists-article-not-synced-list-limit-exceeded", value: "List limit exceeded, unable to sync article", comment: "Text of the alert label informing the user that article couldn't be synced.")
            case .entryLimitExceeded:
                alertLabelText = WMFLocalizedString("reading-lists-article-not-synced-article-limit-exceeded", value: "Article limit exceeded, unable to sync article", comment: "Text of the alert label informing the user that article couldn't be synced.")
            case .genericNotSynced:
                alertLabelText = WMFLocalizedString("reading-lists-article-not-synced", value: "Not synced", comment: "Text of the alert label informing the user that article couldn't be synced.")
            case .downloading:
                alertLabelText = WMFLocalizedString("reading-lists-article-queued-to-be-downloaded", value: "Article queued to be downloaded", comment: "Text of the alert label informing the user that article is queued to be downloaded.")
            case .articleError(let articleError):
                alertLabelText = articleError.localizedDescription
            }
            
            alertButton.setTitle(alertLabelText, for: .normal)
            alertButton.setImage(alertImage, for: .normal)
            setNeedsLayout()
        }
    }
    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(TagCollectionViewCell.self, forCellWithReuseIdentifier: TagCollectionViewCell.identifier)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = false
        return collectionView
    }()
    
    private lazy var collectionViewHeight: CGFloat = {
        guard let layout = layout else {
            return 0
        }
        return self.collectionView(collectionView, layout: layout, sizeForItemAt: IndexPath(item: 0, section: 0)).height
    }()
    
    private lazy var layout: UICollectionViewFlowLayout? = {
        let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        layout?.scrollDirection = .horizontal
        layout?.sectionInset = UIEdgeInsets.zero
        return layout
    }()
    
    private lazy var placeholderCell: TagCollectionViewCell = {
        return TagCollectionViewCell()
    }()
    
    weak public var delegate: SavedArticlesCollectionViewCellDelegate?
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        singlePixelDimension = traitCollection.displayScale > 0 ? 1.0/traitCollection.displayScale : 0.5
        configuredTags = []
        collectionView.reloadData()
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

        singlePixelDimension = traitCollection.displayScale > 0 ? 1.0/traitCollection.displayScale : 0.5
        
        super.setup()
    }
    
    open override func reset() {
        super.reset()
        bottomSeparator.isHidden = true
        topSeparator.isHidden = true
        collectionViewAvailableWidth = 0
        configuredTags = []
        updateFonts(with: traitCollection)
    }
    
    override func updateStyles() {
        styles = HtmlUtils.Styles(font: WMFFont.for(.boldCallout, compatibleWith: traitCollection), boldFont: WMFFont.for(.boldCallout, compatibleWith: traitCollection), italicsFont: WMFFont.for(.italicCallout, compatibleWith: traitCollection), boldItalicsFont: WMFFont.for(.boldItalicCallout, compatibleWith: traitCollection), color: theme.colors.primaryText, linkColor: theme.colors.link, lineSpacing: 1)
    }
    
    private var collectionViewAvailableWidth: CGFloat = 0
    
    override open func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let size = super.sizeThatFits(size, apply: apply)
        let layoutMargins = calculatedLayoutMargins
        
        var widthMinusMargins = layoutWidth(for: size)
        let minHeight = imageViewDimension + layoutMargins.top + layoutMargins.bottom
        
        let labelsAdditionalSpacing: CGFloat = 20
        if !isImageViewHidden {
            widthMinusMargins = widthMinusMargins - spacing - imageViewDimension - labelsAdditionalSpacing
        }
        
        let titleLabelAvailableWidth: CGFloat
        
        if isStatusViewHidden {
            titleLabelAvailableWidth = widthMinusMargins
        } else if isImageViewHidden {
            titleLabelAvailableWidth = widthMinusMargins - statusViewDimension - spacing
        } else {
            titleLabelAvailableWidth = widthMinusMargins - statusViewDimension - 2 * spacing
        }
        
        var x = layoutMargins.left
        if isArticleRTL {
            x = size.width - x - widthMinusMargins
        }
        var origin = CGPoint(x: x, y: layoutMargins.top)
        
        if descriptionLabel.wmf_hasText || !isImageViewHidden {
            let titleLabelFrame = titleLabel.wmf_preferredFrame(at: origin, maximumWidth: titleLabelAvailableWidth, alignedBy: articleSemanticContentAttribute, apply: apply)
            origin.y += titleLabelFrame.layoutHeight(with: spacing)
            
            let descriptionLabelFrame = descriptionLabel.wmf_preferredFrame(at: origin, maximumWidth: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
            origin.y += descriptionLabelFrame.layoutHeight(with: 0)
        } else {
            origin.y += titleLabel.wmf_preferredHeight(at: origin, maximumWidth: titleLabelAvailableWidth, alignedBy: articleSemanticContentAttribute, spacing: 0, apply: apply)
        }
        
        descriptionLabel.isHidden = !descriptionLabel.wmf_hasText
        
        if apply && !isStatusViewHidden {
            let x = isArticleRTL ? titleLabel.frame.minX - spacing - statusViewDimension : titleLabel.frame.maxX + spacing
            let statusViewFrame = CGRect(x: x, y: (titleLabel.frame.midY - 0.5 * statusViewDimension), width: statusViewDimension, height: statusViewDimension)
            statusView.frame = statusViewFrame
            statusView.cornerRadius = 0.5 * statusViewDimension
        }

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
            imageView.frame = CGRect(x: x, y: imageViewY, width: imageViewDimension, height: imageViewDimension)
            imageView.isHidden = isImageViewHidden
        }
        
        var yAlignedWithImageBottom = imageView.frame.maxY - layoutMargins.bottom - (spacing * 0.5)
        if !isTagsViewHidden {
            yAlignedWithImageBottom -= layoutMargins.bottom
        }
        
        if apply && !isAlertButtonHidden {
            let effectiveImageDimension = isImageViewHidden ? 0 : imageViewDimension + spacing
            let xPosition = isArticleRTL ? layoutMargins.right + effectiveImageDimension : layoutMargins.left
            let maxButtonHeight: CGFloat = 44
            let yPosition = height - layoutMargins.bottom - maxButtonHeight
            let availableWidth = layoutWidth(for: size) - spacing - effectiveImageDimension // don't reuse widthMinusMargins
            let origin = CGPoint(x: xPosition, y: yPosition)
            alertButton.wmf_preferredFrame(at: origin, maximumSize: CGSize(width: availableWidth, height: maxButtonHeight), minimumSize: .zero, horizontalAlignment: isArticleRTL ? .right : .left, verticalAlignment: .bottom, apply: apply)
        }
        
        if apply && !isTagsViewHidden {
            collectionViewAvailableWidth = widthMinusMargins
            collectionView.frame = CGRect(x: origin.x, y: yAlignedWithImageBottom, width: collectionViewAvailableWidth, height: collectionViewHeight)
            collectionView.semanticContentAttribute = articleSemanticContentAttribute
        }
        
        return CGSize(width: size.width, height: height)
    }
    
    func configureAlert(for entry: ReadingListEntry, with article: WMFArticle, in readingList: ReadingList?, listLimit: Int, entryLimit: Int, isInDefaultReadingList: Bool = false) {
        if let error = entry.APIError {
            switch error {
            case .entryLimit where isInDefaultReadingList:
                isAlertButtonHidden = false
                alertType = .genericNotSynced
            case .entryLimit:
                isAlertButtonHidden = false
                alertType = .entryLimitExceeded(limit: entryLimit)
            default:
                isAlertButtonHidden = true
            }
        }
        
        if let error = readingList?.APIError {
            switch error {
            case .listLimit:
                isAlertButtonHidden = false
                alertType = .listLimitExceeded(limit: listLimit)
            default:
                break
            }
        }
        
        switch alertType ?? .downloading {
        case .downloading:
            fallthrough
        case .articleError:
            if article.error != .none {
                isAlertButtonHidden = false
                alertType = .articleError(article.error)
            } else if !article.isDownloaded {
                isAlertButtonHidden = false
                alertType = .downloading
            } else {
                isAlertButtonHidden = true
                alertType = nil
            }
        default:
            break
        }
    }
    
    func configure(article: WMFArticle, index: Int, shouldShowSeparators: Bool = false, theme: Theme, layoutOnly: Bool) {

        titleHTML = article.displayTitleHTML
        descriptionLabel.text = article.capitalizedWikidataDescriptionOrSnippet
        
        let imageWidthToRequest = imageView.frame.size.width < 300 ? traitCollection.wmf_nearbyThumbnailWidth : traitCollection.wmf_leadImageWidth // 300 is used to distinguish between full-width images and thumbnails. Ultimately this (and other thumbnail requests) should be updated with code that checks all the available buckets for the width that best matches the size of the image view.
        if let imageURL = article.imageURL(forWidth: imageWidthToRequest) {
            isImageViewHidden = false
            if !layoutOnly {
                imageView.wmf_setImage(with: imageURL, detectFaces: true, onGPU: true, failure: { (error) in }, success: { })
            }
        } else {
            isImageViewHidden = true
        }
        
        let articleLanguageCode = article.url?.wmf_languageCode
        titleLabel.accessibilityLanguage = articleLanguageCode
        descriptionLabel.accessibilityLanguage = articleLanguageCode
        extractLabel?.accessibilityLanguage = articleLanguageCode
        articleSemanticContentAttribute = MWKLanguageLinkController.semanticContentAttribute(forContentLanguageCode: article.url?.wmf_contentLanguageCode)
        
        isStatusViewHidden = article.isDownloaded
        
        isTagsViewHidden = tags.readingLists.isEmpty || !isAlertButtonHidden
        
        if shouldShowSeparators {
            topSeparator.isHidden = index != 0
            bottomSeparator.isHidden = false
        } else {
            bottomSeparator.isHidden = true
        }
        self.theme = theme
        apply(theme: theme)
        extractLabel?.text = nil
        imageViewDimension = 100
    
        setNeedsLayout()
    }
    
    public override func apply(theme: Theme) {
        super.apply(theme: theme)
        collectionView.visibleCells.forEach { ($0 as? TagCollectionViewCell)?.apply(theme: theme) }
        bottomSeparator.backgroundColor = theme.colors.border
        topSeparator.backgroundColor = theme.colors.border
    }
    
    private func tag(at indexPath: IndexPath) -> Tag? {
        guard tags.readingLists.indices.contains(indexPath.item) else {
            return nil
        }
        return Tag(readingList: tags.readingLists[indexPath.item], index: indexPath.item, indexPath: tags.indexPath)
    }
}

// MARK: - UICollectionViewDataSource

extension SavedArticlesCollectionViewCell: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tags.readingLists.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TagCollectionViewCell.identifier, for: indexPath)
        guard let tagCell = cell as? TagCollectionViewCell else {
            return cell
        }
        guard configuredTags.indices.contains(indexPath.item) else {
            return cell
        }
        tagCell.configure(with: configuredTags[indexPath.item], for: tags.readingLists.count, theme: theme)
        return tagCell
    }

}

// MARK: - UICollectionViewDelegate

extension SavedArticlesCollectionViewCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard configuredTags.indices.contains(indexPath.item) else {
            return
        }
        delegate?.didSelect(configuredTags[indexPath.item])
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

extension SavedArticlesCollectionViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard !isTagsViewHidden else {
            return .zero
        }
        
        guard var tagToConfigure = tag(at: indexPath) else {
            return .zero
        }

        if let lastConfiguredTag = configuredTags.last, lastConfiguredTag.isLast, tagToConfigure.index > lastConfiguredTag.index {
            tagToConfigure.isCollapsed = true
            return .zero
        }
        
        let tagsCount = tags.readingLists.count
        
        guard collectionViewAvailableWidth > 0 else {
            placeholderCell.configure(with: tagToConfigure, for: tagsCount, theme: theme)
            return placeholderCell.sizeThatFits(CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric))
        }
        
        guard collectionViewAvailableWidth - spacing >= 0 else {
            assertionFailure("collectionViewAvailableWidth - spacing will be: \(collectionViewAvailableWidth - spacing)")
            return .zero
        }
        
        collectionViewAvailableWidth -= spacing
        
        placeholderCell.configure(with: tagToConfigure, for: tagsCount, theme: theme)
        var placeholderCellSize = placeholderCell.sizeThatFits(CGSize(width: collectionViewAvailableWidth, height: UIView.noIntrinsicMetric))
        
        let isLastTagToConfigure = tagToConfigure.index + 1 == tags.readingLists.count
        
        if collectionViewAvailableWidth - placeholderCellSize.width - spacing <= placeholderCell.minWidth, !isLastTagToConfigure {
            tagToConfigure.isLast = true
            placeholderCell.configure(with: tagToConfigure, for: tagsCount, theme: theme)
            placeholderCellSize = placeholderCell.sizeThatFits(CGSize(width: collectionViewAvailableWidth, height: UIView.noIntrinsicMetric))
        }
        
        collectionViewAvailableWidth -= placeholderCellSize.width
        
        if !configuredTags.contains(where: { $0.readingList == tagToConfigure.readingList && $0.indexPath == tagToConfigure.indexPath }) {
            configuredTags.append(tagToConfigure)
        }
        return placeholderCellSize
    }
}

