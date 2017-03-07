import UIKit
import MapKit
import WMF

class ArticlePlaceView: MKAnnotationView {
    private let imageView: UIView
    private let imageViewImageView: UIImageView
    private let imageOutlineView: UIView
    private let imageBackgroundView: UIView
    private let selectedImageView: UIView
    private let selectedImageViewImageView: UIImageView
    private let selectedImageOutlineView: UIView
    private let selectedImageBackgroundView: UIView
    private let dotView: UIView
    private let groupView: UIView
    private let countLabel: UILabel
    private let dimension: CGFloat
    private let collapsedDimension: CGFloat
    private let groupDimension: CGFloat
    private let selectionAnimationDuration = 0.3
    private let springDamping: CGFloat = 0.5
    private let crossFadeRelativeHalfDuration: TimeInterval = 0.1
    
    private var alwaysShowImage = false
    
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

        let transforms = {
            if alwaysShowImage {
                self.imageView.transform = CGAffineTransform.identity
                self.dotView.transform = dotViewScaleUpTransform
            } else {
                self.imageView.transform = imageViewScaleDownTransform
                self.dotView.transform = CGAffineTransform.identity
            }
        }
        let fadesIn = {
            if alwaysShowImage {
                self.imageView.alpha = 1
            } else {
                self.dotView.alpha = 1
            }
        }
        let fadesOut = {
            if alwaysShowImage {
                self.dotView.alpha = 0
            } else {
                self.imageView.alpha = 0
            }
        }
        let done = {
            self.updateDotAndImageHiddenState()
        }
        if animated {
            if alwaysShowImage {
                UIView.animate(withDuration: 2*selectionAnimationDuration, delay: 0, usingSpringWithDamping: springDamping, initialSpringVelocity: 0, options: [], animations: transforms, completion:nil)
                UIView.animateKeyframes(withDuration: 2*selectionAnimationDuration, delay: 0, options: [], animations: {
                    UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: self.crossFadeRelativeHalfDuration, animations:fadesIn)
                    UIView.addKeyframe(withRelativeStartTime: self.crossFadeRelativeHalfDuration, relativeDuration: self.crossFadeRelativeHalfDuration, animations:fadesOut)
                }) { (didFinish) in
                    done()
                }
            } else {
                UIView.animateKeyframes(withDuration: selectionAnimationDuration, delay: 0, options: [], animations: {
                    UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1, animations:transforms)
                    UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5, animations:fadesIn)
                    UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5, animations:fadesOut)
                }) { (didFinish) in
                    done()
                }
            }
        } else {
            transforms()
            fadesIn()
            fadesOut()
            done()
        }
    }
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        selectedImageView = UIView()
        imageView = UIView()
        selectedImageViewImageView = UIImageView()
        imageViewImageView = UIImageView()
        countLabel = UILabel()
        dotView = UIView()
        groupView = UIView()
        imageOutlineView = UIView()
        selectedImageOutlineView = UIView()
        imageBackgroundView = UIView()
        selectedImageBackgroundView = UIView()
        
        let smallDotImage = #imageLiteral(resourceName: "places-dot-small")
        let mediumDotImage = #imageLiteral(resourceName: "places-dot-medium")
        let mediumDotOutlineImage = #imageLiteral(resourceName: "places-dot-outline-medium")
        let largeDotOutlineImage = #imageLiteral(resourceName: "places-dot-outline-large")
        
        collapsedDimension = smallDotImage.size.width
        groupDimension = mediumDotImage.size.width
        dimension = largeDotOutlineImage.size.width
        
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        frame = CGRect(x: 0, y: 0, width: dimension, height: dimension)
        
        dotView.bounds = CGRect(x: 0, y: 0, width: collapsedDimension, height: collapsedDimension)
        dotView.layer.contents = smallDotImage.cgImage
        dotView.center = CGPoint(x: 0.5*bounds.size.width, y: 0.5*bounds.size.height)
        addSubview(dotView)
        
        groupView.bounds = CGRect(x: 0, y: 0, width: groupDimension, height: groupDimension)
        groupView.layer.contents = mediumDotImage.cgImage
        addSubview(groupView)
        
        imageView.bounds = CGRect(x: 0, y: 0, width: groupDimension, height: groupDimension)
        addSubview(imageView)
        
        imageBackgroundView.frame = imageView.bounds
        imageBackgroundView.layer.contents = #imageLiteral(resourceName: "places-dot-medium-opaque").cgImage
        imageView.addSubview(imageBackgroundView)
        
        imageViewImageView.frame = UIEdgeInsetsInsetRect(imageView.bounds, UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1))
        imageViewImageView.contentMode = .scaleAspectFill
        imageViewImageView.layer.masksToBounds = true
        imageViewImageView.layer.cornerRadius = imageViewImageView.bounds.size.width * 0.5
        imageView.addSubview(imageViewImageView)
        
        imageOutlineView.frame = imageView.bounds
        imageOutlineView.layer.contents = mediumDotOutlineImage.cgImage
        imageView.addSubview(imageOutlineView)
        
        selectedImageView.bounds = bounds
        addSubview(selectedImageView)
        
        selectedImageBackgroundView.frame = selectedImageView.bounds
        selectedImageBackgroundView.layer.contents = #imageLiteral(resourceName: "places-dot-large-opaque").cgImage
        selectedImageView.addSubview(selectedImageBackgroundView)
        
        selectedImageViewImageView.frame = UIEdgeInsetsInsetRect(selectedImageView.bounds, UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1))
        selectedImageViewImageView.contentMode = .scaleAspectFill
        selectedImageViewImageView.layer.cornerRadius = selectedImageView.bounds.size.width * 0.5
        selectedImageViewImageView.layer.masksToBounds = true
        selectedImageView.addSubview(selectedImageViewImageView)
        
        selectedImageOutlineView.frame = selectedImageView.bounds
        selectedImageOutlineView.layer.contents = largeDotOutlineImage.cgImage
        selectedImageView.addSubview(selectedImageOutlineView)
        
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
    
    func showPlaceholderImage() {
        imageViewImageView.contentMode = .center
        imageViewImageView.backgroundColor = UIColor.clear
        imageViewImageView.image = #imageLiteral(resourceName: "places-w")
        
        selectedImageViewImageView.contentMode = .center
        selectedImageViewImageView.backgroundColor = UIColor.clear
        selectedImageViewImageView.image = #imageLiteral(resourceName: "places-w-big")
    }
    
    func update(withArticlePlace articlePlace: ArticlePlace) {
        if articlePlace.articles.count == 1 {
            zPosition = 1
            let article = articlePlace.articles[0]
            if let thumbnailURL = article.thumbnailURL {
                showPlaceholderImage()
                imageViewImageView.wmf_setImage(with: thumbnailURL, detectFaces: true, onGPU: true, failure: { (error) in
                    
                }, success: {
                    self.imageViewImageView.contentMode = .scaleAspectFill
                    self.imageViewImageView.backgroundColor = UIColor.white
                    self.selectedImageViewImageView.wmf_setImage(with: thumbnailURL, detectFaces: true, onGPU: true, failure: { (error) in
                        self.showPlaceholderImage()
                    }, success: {
                        self.selectedImageViewImageView.backgroundColor = UIColor.white
                        self.selectedImageViewImageView.contentMode = .scaleAspectFill
                    })
                })
            } else {
                showPlaceholderImage()
            }
            accessibilityLabel = articlePlace.articles.first?.displayTitle
        } else {
            zPosition = 2
            let countString = "\(articlePlace.articles.count)"
            countLabel.text = countString
            accessibilityLabel = localizedStringForKeyFallingBackOnEnglish("places-accessibility-group").replacingOccurrences(of: "$1", with: countString)
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
        imageViewImageView.wmf_reset()
        selectedImageViewImageView.wmf_reset()
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
        let fadesIn = {
            if selected {
                self.selectedImageView.alpha = 1
            } else {
                self.imageView.alpha = 1
                self.dotView.alpha = 1
            }
        }
        let fadesOut = {
            if selected {
                self.imageView.alpha = 0
                self.dotView.alpha = 0
            } else {
                self.selectedImageView.alpha = 0
            }
        }
        let done = {
            if !selected {
                self.layer.zPosition = self.zPosition
            }
        }
        if animated {
            let duration = 2*selectionAnimationDuration
            if selected {
                UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: springDamping, initialSpringVelocity: 0, options: [], animations: transforms, completion:nil)
                UIView.animateKeyframes(withDuration: duration, delay: 0, options: [], animations: {
                    UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: self.crossFadeRelativeHalfDuration, animations:fadesIn)
                    UIView.addKeyframe(withRelativeStartTime: self.crossFadeRelativeHalfDuration, relativeDuration: self.crossFadeRelativeHalfDuration, animations:fadesOut)
                }) { (didFinish) in
                    done()
                }
            } else {
                UIView.animateKeyframes(withDuration: 0.5*duration, delay: 0, options: [], animations: {
                    UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1, animations:transforms)
                    UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5, animations:fadesIn)
                    UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5, animations:fadesOut)
                }) { (didFinish) in
                    done()
                }
            }
        } else {
            transforms()
            fadesIn()
            fadesOut()
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
