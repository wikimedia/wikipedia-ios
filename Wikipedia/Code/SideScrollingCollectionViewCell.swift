import UIKit

internal struct CellArticle {
    let articleURL: URL?
    let title: String?
    let description: String?
    let imageURL: URL?
}

@objc(WMFSideScrollingCollectionViewCellDelegate)
protocol SideScrollingCollectionViewCellDelegate {
    func sideScrollingCollectionViewCell(_ sideScrollingCollectionViewCell: SideScrollingCollectionViewCell, didSelectArticleWithURL articleURL: URL)
}

@objc(WMFSideScrollingCollectionViewCell)
class SideScrollingCollectionViewCell: CollectionViewCell {
    static let articleCellIdentifier = "ArticleRightAlignedImageCollectionViewCell"
    
    weak var selectionDelegate: SideScrollingCollectionViewCellDelegate?
    let imageView = UIImageView()
    let titleLabel = UILabel()
    let subTitleLabel = UILabel()
    let descriptionLabel = UILabel()
    var flowLayout: UICollectionViewFlowLayout? {
        return collectionView.collectionViewLayout as? UICollectionViewFlowLayout
    }
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    let bottomTitleLabel = UILabel()
    let prototypeCell = ArticleRightAlignedImageCollectionViewCell()
    var semanticContentAttributeOverride: UISemanticContentAttribute = .unspecified {
        didSet {
            titleLabel.semanticContentAttribute = semanticContentAttributeOverride
            subTitleLabel.semanticContentAttribute = semanticContentAttributeOverride
            descriptionLabel.semanticContentAttribute = semanticContentAttributeOverride
            collectionView.semanticContentAttribute = semanticContentAttributeOverride
            bottomTitleLabel.semanticContentAttribute = semanticContentAttributeOverride
        }
    }
    
    internal var articles: [CellArticle] = []
    
    override open func setup() {
        addSubview(prototypeCell)
        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(subTitleLabel)
        addSubview(descriptionLabel)
        addSubview(collectionView)
        addSubview(bottomTitleLabel)
        
        //Setup the prototype cell with placeholder content so we can get an accurate height calculation for the collection view that accounts for dynamic type changes
        prototypeCell.configure(with: CellArticle(articleURL: nil, title: "Lorem", description: "Ipsum", imageURL: nil), semanticContentAttribute: .forceLeftToRight, layoutOnly: true)

        prototypeCell.isHidden = true
        
        backgroundColor = .white
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        titleLabel.numberOfLines = 1
        bottomTitleLabel.numberOfLines = 1
        subTitleLabel.numberOfLines = 1
        descriptionLabel.numberOfLines = 0
        flowLayout?.scrollDirection = .horizontal
        collectionView.register(ArticleRightAlignedImageCollectionViewCell.self, forCellWithReuseIdentifier: SideScrollingCollectionViewCell.articleCellIdentifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = backgroundColor
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        super.setup()
    }
    
    override open func reset() {
        super.reset()
        collectionView.contentOffset = CGPoint.init(x: -collectionView.contentInset.left, y: 0)
        margins = UIEdgeInsets(top: 0, left: 13, bottom: 15, right: 13)
        imageView.wmf_reset()
        imageView.wmf_showPlaceholder()
    }
    
    var isImageViewHidden = false {
        didSet {
            imageView.isHidden = isImageViewHidden
            setNeedsLayout()
        }
    }
    
    let imageViewHeight: CGFloat = 170
    var margins: UIEdgeInsets!
    let spacing: CGFloat = 13
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        var origin = CGPoint(x: margins.left, y: margins.top)
        let widthToFit = size.width - margins.left - margins.right
    
        if !isImageViewHidden {
            if (apply) {
                imageView.frame = CGRect(x: 0, y: 0, width: size.width, height: imageViewHeight)
            }
            origin.y += imageViewHeight
        }

        if titleLabel.wmf_hasAnyText {
            origin.y += spacing
            origin.y += titleLabel.wmf_preferredHeight(at: origin, fitting: widthToFit, alignedBy: semanticContentAttributeOverride, spacing: spacing, apply: apply)
        }
        
        if subTitleLabel.wmf_hasAnyText {
            origin.y += 0
            origin.y += subTitleLabel.wmf_preferredHeight(at: origin, fitting: widthToFit, alignedBy: semanticContentAttributeOverride, spacing: spacing, apply: apply)
        }
        
        origin.y += spacing
        origin.y += descriptionLabel.wmf_preferredHeight(at: origin, fitting: widthToFit, alignedBy: semanticContentAttributeOverride, spacing: spacing, apply: apply)
        
        let collectionViewSpacing: CGFloat = 10
        let height = prototypeCell.wmf_preferredHeight(at: origin, fitting: widthToFit, alignedBy: semanticContentAttributeOverride, spacing: 2*collectionViewSpacing, apply: false)
        if (apply) {
            flowLayout?.itemSize = CGSize(width: max(250, round(0.45*size.width)), height: height - 2*collectionViewSpacing)
            flowLayout?.minimumInteritemSpacing = collectionViewSpacing
            flowLayout?.sectionInset = UIEdgeInsets(top: collectionViewSpacing, left: collectionViewSpacing, bottom: collectionViewSpacing, right: collectionViewSpacing)
            collectionView.frame = CGRect(x: 0, y: origin.y, width: size.width, height: height)
            collectionView.contentInset = UIEdgeInsets.init(top: 0, left: origin.x, bottom: 0, right: 0)
            collectionView.reloadData()
        }
        origin.y += height

        if bottomTitleLabel.wmf_hasAnyText {
            origin.y += spacing
            origin.y += bottomTitleLabel.wmf_preferredHeight(at: origin, fitting: widthToFit, alignedBy: semanticContentAttributeOverride, spacing: spacing, apply: apply)
        }
        
        origin.y += margins.bottom
        return CGSize(width: size.width, height: origin.y)
    }
}

extension SideScrollingCollectionViewCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedArticle = articles[indexPath.item]
        guard let articleURL = selectedArticle.articleURL else {
            return
        }
        selectionDelegate?.sideScrollingCollectionViewCell(self, didSelectArticleWithURL:articleURL)
    }
}

extension SideScrollingCollectionViewCell: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return articles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier:  SideScrollingCollectionViewCell.articleCellIdentifier, for: indexPath)
        guard let articleCell = cell as? ArticleRightAlignedImageCollectionViewCell else {
            return cell
        }
        let articleForCell = articles[indexPath.item]
        articleCell.configure(with: articleForCell, semanticContentAttribute: semanticContentAttributeOverride, layoutOnly: false)
        return articleCell
    }
}

fileprivate extension ArticleRightAlignedImageCollectionViewCell {
    func configure(with cellArticle: CellArticle, semanticContentAttribute: UISemanticContentAttribute, layoutOnly: Bool) {
        contentView.layer.cornerRadius = 5
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = .white
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowOpacity = 0.5
        layer.shadowRadius = 2
        layer.shadowColor = UIColor.wmf_cellArticleCellShadow.cgColor
        layer.masksToBounds = false
        backgroundColor = .clear
        titleTextStyle = .subheadline
        descriptionTextStyle = .footnote
        imageViewDimension = 40
        isSaveButtonHidden = true
        margins = UIEdgeInsets(top: 13, left: 13, bottom: 13, right: 13)
        isImageViewHidden = layoutOnly || cellArticle.imageURL == nil
        titleLabel.text = cellArticle.title
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
        
        setNeedsLayout()
    }
}

extension SideScrollingCollectionViewCell {
    @objc(subItemIndexAtPoint:)
    func subItemIndex(at point: CGPoint) -> Int { // NSNotFound for not found
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
    
    @objc(viewForSubItemAtIndex:)
    func viewForSubItem(at index: Int) -> UIView? {
        guard index != NSNotFound, index >= 0, index < collectionView.numberOfItems(inSection: 0) else {
            return nil
        }
        guard let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) else {
            return nil
        }
        return cell
    }
}
