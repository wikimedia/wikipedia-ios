import UIKit
import MapKit
import WMF

class ArticlePlaceView: MKAnnotationView {
    let imageView: UIImageView
    let selectedImageView: UIImageView
    let dotView: UIView
    let countLabel: UILabel
    let dimension: CGFloat = 60
    let collapsedDimension: CGFloat = 15
    let groupDimension: CGFloat = 30
    let selectionAnimationDuration = 0.25
    
    var alwaysShowImage = false
    
    func set(alwaysShowImage: Bool, animated: Bool) {
        let scale = collapsedDimension/groupDimension
        let imageViewScaleDownTransform = CGAffineTransform(scaleX: scale, y: scale)
        let dotViewScaleUpTransform = CGAffineTransform(scaleX: 1.0/scale, y: 1.0/scale)
        if alwaysShowImage {
            imageView.alpha = 0
            imageView.transform = imageViewScaleDownTransform
            dotView.transform = CGAffineTransform.identity
        } else {
            dotView.transform = dotViewScaleUpTransform
            imageView.transform = CGAffineTransform.identity
            imageView.alpha = 1
        }
        let animations = {
            if alwaysShowImage {
                self.imageView.alpha = 1
                self.imageView.transform = CGAffineTransform.identity
                self.dotView.transform = dotViewScaleUpTransform
            } else {
                self.imageView.alpha = 0
                self.imageView.transform = imageViewScaleDownTransform
                self.dotView.transform = CGAffineTransform.identity
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
                    selectedImageView.backgroundColor = UIColor.white
                    imageView.backgroundColor = UIColor.white
                    imageView.wmf_setImage(with: thumbnailURL, detectFaces: true, onGPU: true, failure: { (error) in
                        self.imageView.backgroundColor = UIColor.wmf_green()
                        self.selectedImageView.backgroundColor = UIColor.wmf_green()
                        self.selectedImageView.image = nil
                        self.imageView.image = nil
                    }, success: {
                        self.selectedImageView.wmf_setImage(with: thumbnailURL, detectFaces: true, onGPU: true, failure: { (error) in
                            self.selectedImageView.backgroundColor = UIColor.wmf_green()
                            self.selectedImageView.image = nil
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
        dotView.transform = CGAffineTransform.identity
        dotView.alpha = 1
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
        let dotScale = collapsedDimension/dimension
        let imageViewScale = groupDimension/dimension
        let scale = alwaysShowImage ? imageViewScale : dotScale
        let selectedImageViewScaleDownTransform = CGAffineTransform(scaleX: scale, y: scale)
        let dotViewScaleUpTransform = CGAffineTransform(scaleX: 1.0/dotScale, y: 1.0/dotScale)
        let imageViewScaleUpTransform = CGAffineTransform(scaleX: 1.0/imageViewScale, y: 1.0/imageViewScale)
        if selected {
            selectedImageView.alpha = 0
            selectedImageView.transform = selectedImageViewScaleDownTransform
            dotView.transform = CGAffineTransform.identity
            imageView.transform = CGAffineTransform.identity
        } else {
            selectedImageView.alpha = 1
            selectedImageView.transform = CGAffineTransform.identity
            dotView.transform = dotViewScaleUpTransform
            imageView.transform = imageViewScaleUpTransform
        }
        let animations = {
            if selected {
                self.selectedImageView.alpha = 1
                self.selectedImageView.transform = CGAffineTransform.identity
                self.dotView.transform = dotViewScaleUpTransform
                self.imageView.transform = imageViewScaleUpTransform
            } else {
                self.selectedImageView.alpha = 0
                self.selectedImageView.transform = selectedImageViewScaleDownTransform
                self.dotView.transform = CGAffineTransform.identity
                self.imageView.transform = CGAffineTransform.identity
            }
        }
        if (animated) {
            UIView.animate(withDuration: selectionAnimationDuration, animations: animations, completion: nil)
        } else {
            animations()
        }
    }
    
    func updateLayout() {
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
    
    override var frame: CGRect {
        didSet {
           updateLayout()
        }
    }
    
    override var bounds: CGRect {
        didSet {
            updateLayout()
        }
    }
}
