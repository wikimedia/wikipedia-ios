import UIKit

class NewsArticleCollectionViewCell: CollectionViewCell {
    let imageView = UIImageView()
    let titleLabel = UILabel()
    let descriptionLabel = UILabel()

    override func setup() {
        super.setup()
    }
    
    
    var isImageViewHidden = false {
        didSet {
            imageView.isHidden = isImageViewHidden
            setNeedsLayout()
        }
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        
        return size
    }
}

struct NewsArticle {
    let title: String?
    let description: String?
    let imageURL: URL?
}

class NewsCollectionViewCell: CollectionViewCell {
    let imageView = UIImageView()
    let descriptionLabel = UILabel()
    let collectionView = UICollectionView()
    let prototypeCell = NewsArticleCollectionViewCell()
    var articles: [NewsArticle] = []
    
    override func setup() {
        //Setup the prototype cell with placeholder content so we can get an accurate height calculation for the collection view that accounts for dynamic type changes
        prototypeCell.titleLabel.text = "Lorem"
        prototypeCell.descriptionLabel.text = "Ipsum"
        prototypeCell.isHidden = true
        addSubview(prototypeCell)
        addSubview(imageView)
        addSubview(descriptionLabel)
        addSubview(collectionView)
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        collectionView.collectionViewLayout = flowLayout
        collectionView.register(NewsArticleCollectionViewCell.self, forCellWithReuseIdentifier: "NewsArticleCollectionViewCell")
        collectionView.dataSource = self
        collectionView.delegate = self
        super.setup()
    }

    
    var isImageViewHidden = false {
        didSet {
            imageView.isHidden = isImageViewHidden
            setNeedsLayout()
        }
    }
    

    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        
        return size
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
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewsArticleCollectionViewCell", for: indexPath) as? NewsArticleCollectionViewCell else {
            return UICollectionViewCell()
        }
        let newsArticle = articles[indexPath.item]
        cell.titleLabel.text = newsArticle.title
        cell.descriptionLabel.text = newsArticle.description
        
        return cell
    }
}
