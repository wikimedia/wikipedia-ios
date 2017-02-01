import UIKit
import MapKit
import WMF

class DebugAnnotation: NSObject, MKAnnotation {
    public let coordinate: CLLocationCoordinate2D
    public let title: String?
    public let subtitle: String?
    
    
    init?(coordinate: CLLocationCoordinate2D) {
        self.title = nil
        self.subtitle = nil
        self.coordinate = coordinate
    }
}

class ArticlePlace: NSObject, MKAnnotation {
    public dynamic var coordinate: CLLocationCoordinate2D
    public var nextCoordinate: CLLocationCoordinate2D?
    public let title: String?
    public let subtitle: String?
    public let articles: [WMFArticle]
    public let identifier: String
    
    init?(coordinate: CLLocationCoordinate2D, nextCoordinate: CLLocationCoordinate2D?, articles: [WMFArticle], identifier: String) {
        self.title = nil
        self.subtitle = nil
        self.coordinate = coordinate
        self.nextCoordinate = nextCoordinate
        self.articles = articles
        self.identifier = identifier
    }
    
    public static func identifierForArticles(articles: [WMFArticle]) -> String {
        return articles.reduce("", { (result, article) -> String in
            guard let key = article.key else {
                return result
            }
            return result.appending(key)
        })
    }
}

class ArticlePlaceView: MKAnnotationView {
    let imageView: UIImageView
    let countLabel: UILabel
    let collapsedDimension: CGFloat = 15
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        imageView = UIImageView()
        countLabel = UILabel()
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        let dimension = 40
        frame = CGRect(x: 0, y: 0, width: dimension, height: dimension)
        
        imageView.contentMode = .scaleAspectFill
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.clipsToBounds = true
        addSubview(imageView)
        
        countLabel.textColor = UIColor.white
        countLabel.textAlignment = .center
        countLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        addSubview(countLabel)
        
        self.annotation = annotation
        update()

    }
    
    func update() {
        if let articlePlace = annotation as? ArticlePlace {
            if articlePlace.articles.count == 1 {
                imageView.backgroundColor = UIColor.wmf_green()
                let article = articlePlace.articles[0]
                if let thumbnailURL = article.thumbnailURL, isSelected {
                    imageView.wmf_setImage(with: thumbnailURL, detectFaces: true, onGPU: true, failure: { (error) in
                        
                    }, success: {
                        
                    })
                } else {
                    imageView.image = nil
                }
            } else {
                imageView.backgroundColor = UIColor.wmf_green().withAlphaComponent(0.7)
                countLabel.text = "\(articlePlace.articles.count)"
            }
        }
        
        layoutSubviews()
    }
    
    override var annotation: MKAnnotation? {
        didSet {
            update()
        }
    }
    
    override var isSelected: Bool {
        didSet {
            update()
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.wmf_reset()
        countLabel.text = nil
        alpha = 1
    }
    
    required init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if isSelected || countLabel.text != nil {
            imageView.frame = bounds
        } else {
            imageView.bounds = CGRect(x: 0, y: 0, width: collapsedDimension, height: collapsedDimension)
            imageView.center = CGPoint(x: 0.5*bounds.size.width, y: 0.5*bounds.size.height)
        }
        imageView.layer.cornerRadius = imageView.bounds.size.width * 0.5
        countLabel.frame = imageView.frame
    }
}
