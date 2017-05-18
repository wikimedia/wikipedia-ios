import UIKit

fileprivate struct NewsArticle {
    let title: String?
    let description: String?
    let imageURL: URL?
}

@objc(WMFNewsCollectionViewCell)
class NewsCollectionViewCell: CollectionViewCell {
    static let articleCellIdentifier = "ArticleRightAlignedImageCollectionViewCell"
    
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
        //Setup the prototype cell with placeholder content so we can get an accurate height calculation for the collection view that accounts for dynamic type changes
        backgroundColor = .white
        prototypeCell.titleLabel.text = "Lorem"
        prototypeCell.descriptionLabel.text = "Ipsum"
        prototypeCell.isHidden = true
        addSubview(prototypeCell)
        addSubview(imageView)
        addSubview(storyLabel)
        addSubview(collectionView)
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
        
        let height = prototypeCell.wmf_preferredHeight(at: origin, fitting: widthToFit, alignedBy: newsSemanticContentAttribute, spacing: spacing, apply: false)
        if (apply) {
            flowLayout?.itemSize = CGSize(width: 250, height: height)
            flowLayout?.minimumInteritemSpacing = 15
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
    
}

extension NewsCollectionViewCell: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return articles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier:  NewsCollectionViewCell.articleCellIdentifier, for: indexPath) as?  ArticleRightAlignedImageCollectionViewCell else {
            return UICollectionViewCell()
        }
        let newsArticle = articles[indexPath.item]
        cell.titleLabel.text = newsArticle.title
        cell.descriptionLabel.text = newsArticle.description
        cell.articleSemanticContentAttribute = newsSemanticContentAttribute
        cell.isSaveButtonHidden = true
        return cell
    }
}

extension NewsCollectionViewCell {
    @objc(configureWithGroup:dataStore:layoutOnly:)
    func configure(with group: WMFContentGroup, dataStore: MWKDataStore, layoutOnly: Bool) {
        guard let stories = group.content as? [WMFFeedNewsStory], let story = stories.first, let previews = story.articlePreviews else {
            return
        }
        
        storyHTML = story.storyHTML
        articles = previews.map { (articlePreview) -> NewsArticle in
            return NewsArticle(title: articlePreview.displayTitle, description: articlePreview.wikidataDescription, imageURL: articlePreview.thumbnailURL)
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
