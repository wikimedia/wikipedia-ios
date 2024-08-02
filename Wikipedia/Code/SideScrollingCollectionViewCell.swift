import WMFComponents

internal struct CellArticle {
    let articleURL: URL?
    let title: String?
    let titleHTML: String?
    let description: String?
    let imageURL: URL?
}

public protocol SideScrollingCollectionViewCellDelegate: AnyObject {
    func sideScrollingCollectionViewCell(_ sideScrollingCollectionViewCell: SideScrollingCollectionViewCell, didSelectArticleWithURL articleURL: URL, at indexPath: IndexPath)
}

public protocol NestedCollectionViewContextMenuDelegate: AnyObject {
    func contextMenu(with contentGroup: WMFContentGroup?, for articleURL: URL?, at itemIndex: Int) -> UIContextMenuConfiguration?
    func willCommitPreview(with animator: UIContextMenuInteractionCommitAnimating)
}

public protocol SubCellProtocol {
    func deselectSelectedSubItems(animated: Bool)
}

open class SideScrollingCollectionViewCell: CollectionViewCell, SubCellProtocol {
    static let articleCellIdentifier = "ArticleRightAlignedImageCollectionViewCell"
    var theme: Theme = Theme.standard
    
    public weak var selectionDelegate: SideScrollingCollectionViewCellDelegate?
    public let imageView = UIImageView()
    public let titleLabel = UILabel()
    public let subTitleLabel = UILabel()
    public let descriptionLabel = UILabel()

    internal var flowLayout: UICollectionViewFlowLayout? {
        return collectionView.collectionViewLayout as? UICollectionViewFlowLayout
    }
    public let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    internal let prototypeCell = ArticleRightAlignedImageCollectionViewCell()
    open var semanticContentAttributeOverride: UISemanticContentAttribute = .unspecified {
        didSet {
            titleLabel.semanticContentAttribute = semanticContentAttributeOverride
            subTitleLabel.semanticContentAttribute = semanticContentAttributeOverride
            descriptionLabel.semanticContentAttribute = semanticContentAttributeOverride
            collectionView.semanticContentAttribute = semanticContentAttributeOverride
        }
    }

    public weak var contextMenuShowingDelegate: NestedCollectionViewContextMenuDelegate?
    
    internal var articles: [CellArticle] = []
    
    override open func setup() {
        titleLabel.isOpaque = true
        subTitleLabel.isOpaque = true
        descriptionLabel.isOpaque = true
        imageView.isOpaque = true
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(subTitleLabel)
        contentView.addSubview(descriptionLabel)
    
        contentView.addSubview(imageView)
        contentView.addSubview(collectionView)
        contentView.addSubview(prototypeCell)
        
        wmf_configureSubviewsForDynamicType()

        // Setup the prototype cell with placeholder content so we can get an accurate height calculation for the collection view that accounts for dynamic type changes
        prototypeCell.configure(with: CellArticle(articleURL: nil, title: "Lorem", titleHTML: "Lorem", description: "Ipsum", imageURL: nil), semanticContentAttribute: .forceLeftToRight, theme: self.theme, layoutOnly: true)

        prototypeCell.isHidden = true

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        titleLabel.numberOfLines = 1
        subTitleLabel.numberOfLines = 1
        descriptionLabel.numberOfLines = 0
        flowLayout?.scrollDirection = .horizontal
        collectionView.register(ArticleRightAlignedImageCollectionViewCell.self, forCellWithReuseIdentifier: SideScrollingCollectionViewCell.articleCellIdentifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        super.setup()
    }
    
    override open func reset() {
        super.reset()
        imageView.wmf_reset()
    }
    
    public var isImageViewHidden = false {
        didSet {
            imageView.isHidden = isImageViewHidden
            setNeedsLayout()
        }
    }
    
    public var imageViewHeight: CGFloat = 130 {
        didSet {
            setNeedsLayout()
        }
    }
    public let spacing: CGFloat = 6
    
    override open func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let layoutMargins = calculatedLayoutMargins
        var origin = CGPoint(x: layoutMargins.left, y: layoutMargins.top)
        let widthToFit = size.width - layoutMargins.left - layoutMargins.right
        if !isImageViewHidden {
            if apply {
                let imageViewWidth = size.width - widthToFit > 50 ? widthToFit : size.width
                imageView.frame = CGRect(x: round(0.5 * (size.width - imageViewWidth)), y: 0, width: imageViewWidth, height: imageViewHeight)
            }
            origin.y += imageViewHeight
        }

        if titleLabel.wmf_hasAnyText {
            origin.y += spacing
            origin.y += titleLabel.wmf_preferredHeight(at: origin, maximumWidth: widthToFit, alignedBy: semanticContentAttributeOverride, spacing: round(0.4 * spacing), apply: apply)
        }
        
        if subTitleLabel.wmf_hasAnyText {
            origin.y += 0
            origin.y += subTitleLabel.wmf_preferredHeight(at: origin, maximumWidth: widthToFit, alignedBy: semanticContentAttributeOverride, spacing: spacing, apply: apply)
        }
        
        origin.y += spacing
        origin.y += descriptionLabel.wmf_preferredHeight(at: origin, maximumWidth: widthToFit, alignedBy: semanticContentAttributeOverride, spacing: spacing, apply: apply)
        
        let collectionViewSpacing: CGFloat = 10
        var height = prototypeCell.wmf_preferredHeight(at: origin, maximumWidth: widthToFit, alignedBy: semanticContentAttributeOverride, spacing: 2*collectionViewSpacing, apply: false)

        if articles.isEmpty {
            height = 0
        }

        if apply {
            flowLayout?.itemSize = CGSize(width: 250, height: height - 2*collectionViewSpacing)
            flowLayout?.minimumInteritemSpacing = collectionViewSpacing
            flowLayout?.minimumLineSpacing = 15
            flowLayout?.sectionInset = UIEdgeInsets(top: collectionViewSpacing, left: collectionViewSpacing, bottom: collectionViewSpacing, right: collectionViewSpacing)
            collectionView.frame = CGRect(x: 0, y: origin.y, width: size.width, height: height)
            if semanticContentAttributeOverride == .forceRightToLeft {
                collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: layoutMargins.right - collectionViewSpacing)
            } else {
                collectionView.contentInset = UIEdgeInsets(top: 0, left: layoutMargins.left - collectionViewSpacing, bottom: 0, right: 0)
            }
            collectionView.reloadData()
            collectionView.layoutIfNeeded()
            deselectSelectedSubItems(animated: false)
        }

        origin.y += height
        origin.y += layoutMargins.bottom
        
        return CGSize(width: size.width, height: origin.y)
    }

    public func resetContentOffset() {
        // Without a layout pass, RTL languages on LTR chrome have an incorrect initial inset.
        layoutIfNeeded()
        let x: CGFloat = semanticContentAttributeOverride == .forceRightToLeft ? collectionView.contentSize.width - collectionView.bounds.size.width + collectionView.contentInset.right : -collectionView.contentInset.left
        collectionView.contentOffset = CGPoint(x: x, y: 0)
    }

    public func deselectSelectedSubItems(animated: Bool) {
        guard let selectedIndexPaths = collectionView.indexPathsForSelectedItems else {
            return
        }
        for indexPath in selectedIndexPaths {
            collectionView.deselectItem(at: indexPath, animated: animated)
        }
    }

    override open func updateBackgroundColorOfLabels() {
        super.updateBackgroundColorOfLabels()
        titleLabel.backgroundColor = labelBackgroundColor
        subTitleLabel.backgroundColor = labelBackgroundColor
        descriptionLabel.backgroundColor = labelBackgroundColor
    }
}

extension SideScrollingCollectionViewCell: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedArticle = articles[indexPath.item]
        guard let articleURL = selectedArticle.articleURL else {
            return
        }
        selectionDelegate?.sideScrollingCollectionViewCell(self, didSelectArticleWithURL: articleURL, at: indexPath)
    }

    // ContextMenu
    public func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let articleURL = articles[safeIndex: indexPath.item]?.articleURL else {
            return nil
        }

        return contextMenuShowingDelegate?.contextMenu(with: nil, for: articleURL, at: indexPath.item)
    }

    public func collectionView(_ collectionView: UICollectionView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        contextMenuShowingDelegate?.willCommitPreview(with: animator)
    }
}

extension SideScrollingCollectionViewCell: UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return articles.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier:  SideScrollingCollectionViewCell.articleCellIdentifier, for: indexPath)
        guard let articleCell = cell as? ArticleRightAlignedImageCollectionViewCell else {
            return cell
        }
        let articleForCell = articles[indexPath.item]
        articleCell.configure(with: articleForCell, semanticContentAttribute: semanticContentAttributeOverride, theme: self.theme, layoutOnly: false)
        return articleCell
    }
}

fileprivate extension ArticleRightAlignedImageCollectionViewCell {
    func configure(with cellArticle: CellArticle, semanticContentAttribute: UISemanticContentAttribute, theme: Theme, layoutOnly: Bool) {
        apply(theme: theme)
        backgroundColor = .clear
        setBackgroundColors(theme.colors.subCellBackground, selected: theme.colors.midBackground)
        backgroundView?.layer.cornerRadius = 3
        backgroundView?.layer.masksToBounds = true
        selectedBackgroundView?.layer.cornerRadius = 3
        selectedBackgroundView?.layer.masksToBounds = true
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowOpacity = 1.0
        layer.shadowRadius = 3
        layer.shadowColor = theme.colors.shadow.cgColor
        layer.masksToBounds = false
        titleLabel.backgroundColor = backgroundView?.backgroundColor
        descriptionLabel.backgroundColor = backgroundView?.backgroundColor
        styles = HtmlUtils.Styles(font: WMFFont.for(.subheadline, compatibleWith: traitCollection), boldFont: WMFFont.for(.boldSubheadline, compatibleWith: traitCollection), italicsFont: WMFFont.for(.italicSubheadline, compatibleWith: traitCollection), boldItalicsFont: WMFFont.for(.boldItalicSubheadline, compatibleWith: traitCollection), color: theme.colors.primaryText, linkColor: theme.colors.link, lineSpacing: 1)
        descriptionTextStyle = .footnote
        boldFont = .boldFootnote
        imageViewDimension = 40
        layoutMargins = UIEdgeInsets(top: 9, left: 10, bottom: 9, right: 10)
        isImageViewHidden = layoutOnly || cellArticle.imageURL == nil
        
        titleHTML = cellArticle.titleHTML ?? cellArticle.title

        descriptionLabel.text = cellArticle.description
        articleSemanticContentAttribute = semanticContentAttribute
        
        if let imageURL = cellArticle.imageURL {
            isImageViewHidden = false
            if !layoutOnly {
                imageView.wmf_setImage(with: imageURL, detectFaces: true, onGPU: true, failure: { (error) in }, success: { })
            }
        } else {
            isImageViewHidden = true
        }
        
        updateFonts(with: traitCollection)
        setNeedsLayout()
    }
}

extension SideScrollingCollectionViewCell {
    public func subItemIndex(at point: CGPoint) -> Int { // NSNotFound for not found
        let collectionViewFrame = collectionView.frame
        guard collectionViewFrame.contains(point) else {
            return NSNotFound
        }
        let pointInCollectionViewCoordinates = convert(point, to: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: pointInCollectionViewCoordinates) else {
            return NSNotFound
        }
        
        return indexPath.item
    }
    
    public func viewForSubItem(at index: Int) -> UIView? {
        guard index != NSNotFound, index >= 0, index < collectionView.numberOfItems(inSection: 0) else {
            return nil
        }
        guard let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) else {
            return nil
        }
        return cell
    }
}

extension SideScrollingCollectionViewCell: Themeable {
    open func apply(theme: Theme) {
        self.theme = theme
        imageView.alpha = theme.imageOpacity
        setBackgroundColors(theme.colors.paperBackground, selected: theme.colors.midBackground)
        titleLabel.textColor = theme.colors.primaryText
        subTitleLabel.textColor = theme.colors.secondaryText
        descriptionLabel.textColor = theme.colors.primaryText
        collectionView.backgroundColor = theme.colors.paperBackground
        descriptionLabel.textColor = theme.colors.primaryText
        updateSelectedOrHighlighted()
        collectionView.reloadData()
        imageView.accessibilityIgnoresInvertColors = true
    }
}
