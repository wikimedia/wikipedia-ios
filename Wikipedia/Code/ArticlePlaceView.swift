import UIKit
import MapKit
import WMF

class ArticlePlaceView: MKAnnotationView {
    let imageView: UIImageView
    let selectedImageView: UIImageView
    let dotView: UIView
    let countLabel: UILabel
    let collapsedDimension: CGFloat = 15
    let groupDimension: CGFloat = 30
    let selectionAnimationDuration = 0.25
    
    var alwaysShowImage = false
    
    func set(alwaysShowImage: Bool, animated: Bool) {
        if alwaysShowImage {
            imageView.alpha = 0
            imageView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        } else {
            imageView.alpha = 1
        }
        let animations = {
            if alwaysShowImage {
                self.imageView.alpha = 1
                self.imageView.transform = CGAffineTransform.identity
            } else {
                self.imageView.alpha = 0
                self.imageView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            }
        }
        if (animated) {
            UIView.animate(withDuration: selectionAnimationDuration, animations: animations, completion: nil)
        } else {
            animations()
        }
    }
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        selectedImageView = UIImageView()
        imageView = UIImageView()
        countLabel = UILabel()
        dotView = UIView()
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        let dimension = 60
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
        
        selectedImageView.alpha = 0
        selectedImageView.contentMode = .scaleAspectFill
        selectedImageView.layer.borderWidth = 2
        selectedImageView.layer.borderColor = UIColor.white.cgColor
        selectedImageView.clipsToBounds = true
        addSubview(selectedImageView)
        
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
                        self.selectedImageView.backgroundColor = UIColor.wmf_green()
                    }, success: {
                        self.selectedImageView.wmf_setImage(with: thumbnailURL, detectFaces: true, onGPU: true, failure: { (error) in
                            
                        }, success: {
                            
                        })
                    })
                } else {
                    selectedImageView.image = nil
                    selectedImageView.backgroundColor = UIColor.wmf_green()
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
        selectedImageView.wmf_reset()
        countLabel.text = nil
        set(alwaysShowImage: false, animated: false)
        selectedImageView.alpha = 0
        selectedImageView.transform = CGAffineTransform.identity
        imageView.alpha = 0
        imageView.transform = CGAffineTransform.identity
        alpha = 1
        transform = CGAffineTransform.identity
    }
    
    required init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            selectedImageView.alpha = 0
            selectedImageView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        } else {
            selectedImageView.alpha = 1
        }
        let animations = {
            if selected {
                self.selectedImageView.alpha = 1
                self.selectedImageView.transform = CGAffineTransform.identity
            } else {
                self.selectedImageView.alpha = 0
                //self.imageView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }
        }
        if (animated) {
            UIView.animate(withDuration: selectionAnimationDuration, animations: animations, completion: nil)
        } else {
            animations()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        selectedImageView.frame = bounds
        selectedImageView.layer.cornerRadius = selectedImageView.bounds.size.width * 0.5
        
        imageView.bounds = CGRect(x: 0, y: 0, width: groupDimension, height: groupDimension)
        imageView.center = CGPoint(x: 0.5*bounds.size.width, y: 0.5*bounds.size.height)
        imageView.layer.cornerRadius = imageView.bounds.size.width * 0.5
        
        if countLabel.text != nil {
            imageView.isHidden = true
            dotView.bounds = CGRect(x: 0, y: 0, width: groupDimension, height: groupDimension)
            dotView.center = CGPoint(x: 0.5*bounds.size.width, y: 0.5*bounds.size.height)
        } else {
            imageView.isHidden = false
            dotView.bounds = CGRect(x: 0, y: 0, width: collapsedDimension, height: collapsedDimension)
            dotView.center = CGPoint(x: 0.5*bounds.size.width, y: 0.5*bounds.size.height)
        }
        dotView.layer.cornerRadius = dotView.bounds.size.width * 0.5
        countLabel.frame = imageView.frame
    }
}
