import UIKit
import MapKit
import WMF

class ArticlePlaceView: MKAnnotationView {
    let imageView: UIImageView
    let selectedImageView: UIImageView
    let dotView: UIView
    let groupView: UIView
    let countLabel: UILabel
    let dimension: CGFloat = 60
    let collapsedDimension: CGFloat = 15
    let groupDimension: CGFloat = 30
    let selectionAnimationDuration = 0.4
    
    var alwaysShowImage = false
    
    func set(alwaysShowImage: Bool, animated: Bool) {
        self.alwaysShowImage = alwaysShowImage
        let scale = collapsedDimension/groupDimension
        let imageViewScaleDownTransform = CGAffineTransform(scaleX: scale, y: scale)
        let dotViewScaleUpTransform = CGAffineTransform(scaleX: 1.0/scale, y: 1.0/scale)
        if alwaysShowImage {
            imageView.alpha = 0
            imageView.isHidden = false
            dotView.alpha = 1
            dotView.isHidden = false
            imageView.transform = imageViewScaleDownTransform
            dotView.transform = CGAffineTransform.identity
        } else {
            dotView.transform = dotViewScaleUpTransform
            imageView.transform = CGAffineTransform.identity
            imageView.alpha = 1
            imageView.isHidden = false
            dotView.alpha = 0
            dotView.isHidden = false
        }
        let animations = {
            if alwaysShowImage {
                self.imageView.alpha = 1
                self.dotView.alpha = 0
                self.imageView.transform = CGAffineTransform.identity
                self.dotView.transform = dotViewScaleUpTransform
            } else {
                self.imageView.alpha = 0
                self.dotView.alpha = 1
                self.imageView.transform = imageViewScaleDownTransform
                self.dotView.transform = CGAffineTransform.identity
            }
        }
        if (animated) {
            UIView.animate(withDuration: selectionAnimationDuration, animations: animations, completion: { (didFinish) in
                self.updateDotAndImageHiddenState()
            })
        } else {
            animations()
            updateDotAndImageHiddenState()
        }
    }
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        selectedImageView = UIImageView()
        imageView = UIImageView()
        countLabel = UILabel()
        dotView = UIView()
        groupView = UIView()
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        frame = CGRect(x: 0, y: 0, width: dimension, height: dimension)
        
        dotView.bounds = CGRect(x: 0, y: 0, width: collapsedDimension, height: collapsedDimension)
        dotView.layer.borderWidth = 2
        dotView.layer.borderColor = UIColor.white.cgColor
        dotView.layer.masksToBounds = true
        dotView.center = CGPoint(x: 0.5*bounds.size.width, y: 0.5*bounds.size.height)
        dotView.layer.cornerRadius = dotView.bounds.size.width * 0.5
        dotView.backgroundColor = UIColor.wmf_green()
        addSubview(dotView)
        
        groupView.bounds = CGRect(x: 0, y: 0, width: groupDimension, height: groupDimension)
        groupView.layer.borderWidth = 2
        groupView.layer.borderColor = UIColor.white.cgColor
        groupView.layer.masksToBounds = true
        groupView.layer.cornerRadius = groupView.bounds.size.width * 0.5
        groupView.backgroundColor = UIColor.wmf_green().withAlphaComponent(0.7)
        addSubview(groupView)
        
        imageView.bounds = CGRect(x: 0, y: 0, width: groupDimension, height: groupDimension)
        imageView.contentMode = .scaleAspectFill
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = imageView.bounds.size.width * 0.5
        addSubview(imageView)
        
        selectedImageView.frame = bounds
        selectedImageView.contentMode = .scaleAspectFill
        selectedImageView.layer.cornerRadius = selectedImageView.bounds.size.width * 0.5
        selectedImageView.layer.borderWidth = 2
        selectedImageView.layer.borderColor = UIColor.white.cgColor
        selectedImageView.layer.masksToBounds = true
        selectedImageView.frame = bounds
        addSubview(selectedImageView)
        
        countLabel.frame = groupView.bounds
        countLabel.textColor = UIColor.white
        countLabel.textAlignment = .center
        countLabel.font = UIFont.boldSystemFont(ofSize: 16)
        groupView.addSubview(countLabel)
        
        prepareForReuse()
        self.annotation = annotation
    }
    
    var zPosition: CGFloat = 1 {
        didSet {
            guard !isSelected else {
                return
            }
            layer.zPosition = zPosition
        }
    }
    
    func update(withArticlePlace articlePlace: ArticlePlace) {
        if articlePlace.articles.count == 1 {
            zPosition = 1
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
            zPosition = 2
            countLabel.text = "\(articlePlace.articles.count)"
        }
        updateDotAndImageHiddenState()
    }
    
    func updateDotAndImageHiddenState() {
        if countLabel.text != nil {
            imageView.isHidden = true
            dotView.isHidden = true
            groupView.isHidden = false
        } else {
            imageView.isHidden = !alwaysShowImage
            dotView.isHidden = alwaysShowImage
            groupView.isHidden = true
        }
    }

    override var annotation: MKAnnotation? {
        didSet {
            guard let articlePlace = annotation as? ArticlePlace else {
                return
            }
            update(withArticlePlace: articlePlace)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.wmf_reset()
        selectedImageView.wmf_reset()
        countLabel.text = nil
        set(alwaysShowImage: false, animated: false)
        setSelected(false, animated: false)
        alpha = 1
        transform = CGAffineTransform.identity
    }
    
    required init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        guard let place = annotation as? ArticlePlace, place.articles.count == 1 else {
            selectedImageView.alpha = 0
            return
        }
        let dotScale = collapsedDimension/dimension
        let imageViewScale = groupDimension/dimension
        let scale = alwaysShowImage ? imageViewScale : dotScale
        let selectedImageViewScaleDownTransform = CGAffineTransform(scaleX: scale, y: scale)
        let dotViewScaleUpTransform = CGAffineTransform(scaleX: 1.0/dotScale, y: 1.0/dotScale)
        let imageViewScaleUpTransform = CGAffineTransform(scaleX: 1.0/imageViewScale, y: 1.0/imageViewScale)
        layer.zPosition = 3
        if selected {
            selectedImageView.transform = selectedImageViewScaleDownTransform
            dotView.transform = CGAffineTransform.identity
            imageView.transform = CGAffineTransform.identity
            
            selectedImageView.alpha = 0
            imageView.alpha = 1
            dotView.alpha = 1
        } else {
            selectedImageView.transform = CGAffineTransform.identity
            dotView.transform = dotViewScaleUpTransform
            imageView.transform = imageViewScaleUpTransform
            
            selectedImageView.alpha = 1
            imageView.alpha = 0
            dotView.alpha = 0
        }
        let transforms = {
            if selected {
                self.selectedImageView.transform = CGAffineTransform.identity
                self.dotView.transform = dotViewScaleUpTransform
                self.imageView.transform = imageViewScaleUpTransform
            } else {
                self.selectedImageView.transform = selectedImageViewScaleDownTransform
                self.dotView.transform = CGAffineTransform.identity
                self.imageView.transform = CGAffineTransform.identity
            }
        }
        let fades = {
            if selected {
                self.selectedImageView.alpha = 1
                self.imageView.alpha = 0
                self.dotView.alpha = 0
            } else {
                self.selectedImageView.alpha = 0
                self.imageView.alpha = 1
                self.dotView.alpha = 1
            }
        }
        
        let done = {
            if !selected {
                self.layer.zPosition = self.zPosition
            }
        }
        if (animated) {
            if (selected) {
                UIView.animate(withDuration: 2*selectionAnimationDuration, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: [], animations: transforms, completion:{ (didFinish) in
                    done()
                })
                UIView.animate(withDuration: 0.5*selectionAnimationDuration, animations: fades, completion: { (didFinish) -> Void in  } )
            } else {
                UIView.animate(withDuration: selectionAnimationDuration, animations: { transforms()
                    fades()
                }, completion: { (didFinish) -> Void in  done() } )
            }
        } else {
            transforms()
            fades()
            done()
        }
    }
    
    func updateLayout() {
        let center = CGPoint(x: 0.5*bounds.size.width, y: 0.5*bounds.size.height)
        selectedImageView.center = center
        imageView.center = center
        dotView.center = center
        groupView.center = center
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
