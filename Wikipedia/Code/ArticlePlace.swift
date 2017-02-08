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
    let dotView: UIView
    let countLabel: UILabel
    let collapsedDimension: CGFloat = 15
    let groupDimension: CGFloat = 30
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        imageView = UIImageView()
        countLabel = UILabel()
        dotView = UIView()
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        let dimension = 50
        frame = CGRect(x: 0, y: 0, width: dimension, height: dimension)
        
        dotView.layer.borderWidth = 2
        dotView.layer.borderColor = UIColor.white.cgColor
        dotView.clipsToBounds = true
        addSubview(dotView)
        
        imageView.alpha = 0
        imageView.contentMode = .scaleAspectFill
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.clipsToBounds = true
        addSubview(imageView)
        
        countLabel.textColor = UIColor.white
        countLabel.textAlignment = .center
        countLabel.font = UIFont.boldSystemFont(ofSize: 16)
        addSubview(countLabel)
        
        self.annotation = annotation
        update()

    }
    
    func update() {
        if let articlePlace = annotation as? ArticlePlace {
            if articlePlace.articles.count == 1 {
                dotView.backgroundColor = UIColor.wmf_green()
                let article = articlePlace.articles[0]
                if let thumbnailURL = article.thumbnailURL {
                    imageView.backgroundColor = UIColor.white
                    imageView.wmf_setImage(with: thumbnailURL, detectFaces: true, onGPU: true, failure: { (error) in
                         self.imageView.backgroundColor = UIColor.wmf_green()
                    }, success: {
                        
                    })
                } else {
                    imageView.image = nil
                    imageView.backgroundColor = UIColor.wmf_green()
                }
            } else {
                dotView.backgroundColor = UIColor.wmf_green().withAlphaComponent(0.7)
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
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.wmf_reset()
        countLabel.text = nil
        imageView.alpha = 0
        imageView.transform = CGAffineTransform.identity
        dotView.alpha = 1
        alpha = 1
        transform = CGAffineTransform.identity
    }
    
    required init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            dotView.alpha = 1
            imageView.alpha = 0
            imageView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        } else {
            imageView.alpha = 1
            dotView.alpha = 0
        }
        let animations = {
            if selected {
                self.imageView.alpha = 1
                self.imageView.transform = CGAffineTransform.identity
                self.dotView.alpha = 0
            } else {
                self.dotView.alpha = 1
                self.imageView.alpha = 0
                //self.imageView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }
        }
        if (animated) {
            UIView.animate(withDuration: 0.2, animations: animations, completion: nil)
        } else {
            animations()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
        imageView.layer.cornerRadius = imageView.bounds.size.width * 0.5
        if countLabel.text != nil {
            dotView.bounds = CGRect(x: 0, y: 0, width: groupDimension, height: groupDimension)
            dotView.center = CGPoint(x: 0.5*bounds.size.width, y: 0.5*bounds.size.height)
        } else {
            dotView.bounds = CGRect(x: 0, y: 0, width: collapsedDimension, height: collapsedDimension)
            dotView.center = CGPoint(x: 0.5*bounds.size.width, y: 0.5*bounds.size.height)
        }
        dotView.layer.cornerRadius = dotView.bounds.size.width * 0.5
        countLabel.frame = imageView.frame
    }
}
