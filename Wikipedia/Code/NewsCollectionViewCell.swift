import UIKit

fileprivate struct NewsArticle {
    let articleURL: URL?
    let title: String?
    let description: String?
    let imageURL: URL?
}

@objc(WMFNewsCollectionViewCellDelegate)
protocol NewsCollectionViewCellDelegate {
    func newsCollectionViewCell(_ newsCollectionViewCell: NewsCollectionViewCell, didSelectNewsArticleWithURL articleURL: URL)
}

@objc(WMFNewsCollectionViewCell)
class NewsCollectionViewCell: CollectionViewCell {
    static let articleCellIdentifier = "ArticleRightAlignedImageCollectionViewCell"
    
    weak var newsDelegate: NewsCollectionViewCellDelegate?
    let imageView = UIImageView()
    let storyLabel = UILabel()
    var flowLayout: UICollectionViewFlowLayout? {
        return collectionView.collectionViewLayout as? UICollectionViewFlowLayout
    }
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    let prototypeCell = ArticleRightAlignedImageCollectionViewCell()
    var newsSemanticContentAttribute: UISemanticContentAttribute = .forceLeftToRight
    fileprivate var articles: [NewsArticle] = []
    
    override func setup() {
        addSubview(prototypeCell)
        addSubview(imageView)
        addSubview(storyLabel)
        addSubview(collectionView)
        
        //Setup the prototype cell with placeholder content so we can get an accurate height calculation for the collection view that accounts for dynamic type changes
        prototypeCell.configure(with: NewsArticle(articleURL: nil, title: "Lorem", description: "Ipsum", imageURL: nil), semanticContentAttribute: .forceLeftToRight, layoutOnly: true)

        prototypeCell.isHidden = true
        
        backgroundColor = .white
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        storyLabel.numberOfLines = 0
        flowLayout?.scrollDirection = .horizontal
        collectionView.register(ArticleRightAlignedImageCollectionViewCell.self, forCellWithReuseIdentifier: NewsCollectionViewCell.articleCellIdentifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = backgroundColor
        super.setup()
    }
    
    var isImageViewHidden = false {
        didSet {
            imageView.isHidden = isImageViewHidden
            setNeedsLayout()
        }
    }
    
    let imageViewHeight: CGFloat = 170
    let margins = UIEdgeInsets(top: 0, left: 13, bottom: 0, right: 13)
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
        
        origin.y += spacing
        origin.y += storyLabel.wmf_preferredHeight(at: origin, fitting: widthToFit, alignedBy: newsSemanticContentAttribute, spacing: spacing, apply: apply)
        
        let collectionViewSpacing: CGFloat = 10
        let height = prototypeCell.wmf_preferredHeight(at: origin, fitting: widthToFit, alignedBy: newsSemanticContentAttribute, spacing: 2*collectionViewSpacing, apply: false)
        if (apply) {
            flowLayout?.itemSize = CGSize(width: 250, height: height - 2*collectionViewSpacing)

            flowLayout?.minimumInteritemSpacing = collectionViewSpacing
            flowLayout?.sectionInset = UIEdgeInsets(top: collectionViewSpacing, left: collectionViewSpacing, bottom: collectionViewSpacing, right: collectionViewSpacing)
            collectionView.frame = CGRect(x: 0, y: origin.y, width: size.width, height: height)
            collectionView.reloadData()
        }
        origin.y += height

        origin.y += margins.bottom
        return CGSize(width: size.width, height: origin.y)
    }
    
    static let textStyle = UIFontTextStyle.subheadline
    var font = UIFont.preferredFont(forTextStyle: textStyle)
    var linkFont = UIFont.preferredFont(forTextStyle: textStyle)
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        font = UIFont.preferredFont(forTextStyle: NewsCollectionViewCell.textStyle)
        linkFont = UIFont.boldSystemFont(ofSize: font.pointSize)
        updateStoryHTMLStyle()
    }
    
    func updateStoryHTMLStyle() {
        guard let storyHTML = storyHTML else {
            storyLabel.text = nil
            return
        }
        let attributedString = storyHTML.wmf_attributedStringByRemovingHTML(with: font, linkFont: linkFont)
        storyLabel.attributedText = attributedString
    }
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.wmf_reset()
        imageView.wmf_showPlaceholder()
    }
    
    var storyHTML: String? {
        didSet {
            updateStoryHTMLStyle()
        }
    }
}

extension NewsCollectionViewCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let newsArticle = articles[indexPath.item]
        guard let articleURL = newsArticle.articleURL else {
            return
        }
        newsDelegate?.newsCollectionViewCell(self, didSelectNewsArticleWithURL:articleURL)
    }
}

extension NewsCollectionViewCell: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return articles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier:  NewsCollectionViewCell.articleCellIdentifier, for: indexPath)
        guard let articleCell = cell as? ArticleRightAlignedImageCollectionViewCell else {
            return cell
        }
        let newsArticle = articles[indexPath.item]
        articleCell.configure(with: newsArticle, semanticContentAttribute: newsSemanticContentAttribute, layoutOnly: false)
        return articleCell
    }
}

extension NewsCollectionViewCell {
    @objc(configureWithStory:dataStore:layoutOnly:)
    func configure(with story: WMFFeedNewsStory, dataStore: MWKDataStore, layoutOnly: Bool) {
        let previews = story.articlePreviews ?? []
        storyHTML = story.storyHTML
        articles = previews.map { (articlePreview) -> NewsArticle in
            return NewsArticle(articleURL:articlePreview.articleURL, title: articlePreview.displayTitle, description: articlePreview.wikidataDescription, imageURL: articlePreview.thumbnailURL)
        }
        let imageWidthToRequest = traitCollection.wmf_potdImageWidth
        if let articleURL = story.featuredArticlePreview?.articleURL ?? previews.first?.articleURL, let article = dataStore.fetchArticle(with: articleURL), let imageURL = article.imageURL(forWidth: imageWidthToRequest) {
            isImageViewHidden = false
            if !layoutOnly {
                imageView.wmf_setImage(with: imageURL, detectFaces: true, onGPU: true, failure: { [weak self] (error) in self?.isImageViewHidden = true }, success: { })
            }
        } else {
            isImageViewHidden = true
        }
    }
}

fileprivate extension ArticleRightAlignedImageCollectionViewCell {
    func configure(with newsArticle: NewsArticle, semanticContentAttribute: UISemanticContentAttribute, layoutOnly: Bool) {
        contentView.layer.cornerRadius = 5
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = .white
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowOpacity = 0.5
        layer.shadowRadius = 2
        layer.shadowColor = UIColor.wmf_newsArticleCellShadow.cgColor
        layer.masksToBounds = false
        backgroundColor = .clear
        titleTextStyle = .subheadline
        descriptionTextStyle = .footnote
        imageViewDimension = 40
        margins = UIEdgeInsets(top: 13, left: 13, bottom: 13, right: 13)
        isImageViewHidden = layoutOnly || newsArticle.imageURL == nil
        titleLabel.text = newsArticle.title
        descriptionLabel.text = newsArticle.description
        articleSemanticContentAttribute = semanticContentAttribute
        isSaveButtonHidden = true
        
        if let imageURL = newsArticle.imageURL {
            isImageViewHidden = false
            if !layoutOnly {
                imageView.wmf_setImage(with: imageURL, detectFaces: true, onGPU: true, failure: { [weak self] (error) in self?.isImageViewHidden = true }, success: { })
            }
        } else {
            isImageViewHidden = true
        }
    }
}
