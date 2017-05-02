import UIKit
import MapKit
import WMF

protocol ArticlePlaceViewDelegate: NSObjectProtocol {
    func articlePlaceViewWasTapped(_ articlePlaceView: ArticlePlaceView)
}

class ArticlePlaceView: MKAnnotationView {
    public weak var delegate: ArticlePlaceViewDelegate?
    
    let imageView: UIView
    private let imageImageView: UIImageView
    private let imageImagePlaceholderView: UIImageView
    private let imageOutlineView: UIView
    private let imageBackgroundView: UIView
    private let selectedImageView: UIView
    private let selectedImageImageView: UIImageView
    private let selectedImageImagePlaceholderView: UIImageView
    private let selectedImageOutlineView: UIView
    private let selectedImageBackgroundView: UIView
    private let dotView: UIView
    private let groupView: UIView
    private let countLabel: UILabel
    private let dimension: CGFloat
    private let collapsedDimension: CGFloat
    let groupDimension: CGFloat
    let imageDimension: CGFloat
    private let selectionAnimationDuration = 0.3
    private let springDamping: CGFloat = 0.5
    private let crossFadeRelativeHalfDuration: TimeInterval = 0.1
    private var alwaysShowImage = false
    private let alwaysRasterize = true // set this or rasterize on animations, not both
    private let rasterizeOnAnimations = false
    
    func set(alwaysShowImage: Bool, animated: Bool) {
        self.alwaysShowImage = alwaysShowImage
        let scale = collapsedDimension/imageDimension
        let imageViewScaleDownTransform = CGAffineTransform(scaleX: scale, y: scale)
        let dotViewScaleUpTransform = CGAffineTransform(scaleX: 1.0/scale, y: 1.0/scale)
        if alwaysShowImage {
            loadImage()
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
        
        if (animated && rasterizeOnAnimations) {
            self.imageView.layer.shouldRasterize = true
        }
        let done = {
            if (animated && self.rasterizeOnAnimations) {
                self.imageView.layer.shouldRasterize = false
            }
            guard let articlePlace = self.annotation as? ArticlePlace else {
                return
            }
            self.updateDotAndImageHiddenState(withArticlePlace: articlePlace)
        }
        if animated {
            if alwaysShowImage {
                UIView.animate(withDuration: 2*selectionAnimationDuration, delay: 0, usingSpringWithDamping: springDamping, initialSpringVelocity: 0, options: [.allowUserInteraction], animations: transforms, completion:nil)
                UIView.animateKeyframes(withDuration: 2*selectionAnimationDuration, delay: 0, options: [.allowUserInteraction], animations: {
                    UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: self.crossFadeRelativeHalfDuration, animations:fadesIn)
                    UIView.addKeyframe(withRelativeStartTime: self.crossFadeRelativeHalfDuration, relativeDuration: self.crossFadeRelativeHalfDuration, animations:fadesOut)
                }) { (didFinish) in
                    done()
                }
            } else {
                UIView.animateKeyframes(withDuration: selectionAnimationDuration, delay: 0, options: [.allowUserInteraction], animations: {
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
    
    let selectedImageButton: UIButton
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard superview != nil else {
            selectedImageButton.removeTarget(self, action: #selector(selectedImageViewWasTapped), for: .touchUpInside)
            return
        }
        
        selectedImageButton.addTarget(self, action: #selector(selectedImageViewWasTapped), for: .touchUpInside)
    }
    
    static let smallDotImage = #imageLiteral(resourceName: "places-dot-small")
    static let mediumDotImage = #imageLiteral(resourceName: "places-dot-medium")
    
    static let mediumOpaqueDotImage = #imageLiteral(resourceName: "places-dot-medium-opaque")
    static let mediumOpaqueDotOutlineImage = #imageLiteral(resourceName: "places-dot-outline-medium")
    
    static let extraMediumOpaqueDotImage = #imageLiteral(resourceName: "places-dot-extra-medium-opaque")
    static let extraMediumOpaqueDotOutlineImage = #imageLiteral(resourceName: "places-dot-outline-extra-medium")
    
    static let largeOpaqueDotImage = #imageLiteral(resourceName: "places-dot-large-opaque")
    static let largeOpaqueDotOutlineImage = #imageLiteral(resourceName: "places-dot-outline-large")
    
    static let extraLargeOpaqueDotImage = #imageLiteral(resourceName: "places-dot-extra-large-opaque")
    static let extraLargeOpaqueDotOutlineImage = #imageLiteral(resourceName: "places-dot-outline-extra-large ")
    
    static let mediumPlaceholderImage = #imageLiteral(resourceName: "places-w-medium")
    static let largePlaceholderImage = #imageLiteral(resourceName: "places-w-large")
    
    static let extraMediumPlaceholderImage = #imageLiteral(resourceName: "places-w-extra-medium")
    static let extraLargePlaceholderImage = #imageLiteral(resourceName: "places-w-extra-large")

    
    required init(annotation: MKAnnotation?, reuseIdentifier: String?, isExtraLarge: Bool) {
        selectedImageView = UIView()
        imageView = UIView()
        selectedImageImageView = UIImageView()
        imageImageView = UIImageView()
        countLabel = UILabel()
        dotView = UIView()
        groupView = UIView()
        imageOutlineView = UIView()
        selectedImageOutlineView = UIView()
        imageBackgroundView = UIView()
        selectedImageBackgroundView = UIView()
        selectedImageButton = UIButton()
        imageImagePlaceholderView = UIImageView()
        selectedImageImagePlaceholderView = UIImageView()
        
        let scale = ArticlePlaceView.mediumDotImage.scale
        let mediumOpaqueDotImage = isExtraLarge ? ArticlePlaceView.extraMediumOpaqueDotImage : ArticlePlaceView.mediumOpaqueDotImage
        let mediumOpaqueDotOutlineImage = isExtraLarge ? ArticlePlaceView.extraMediumOpaqueDotOutlineImage : ArticlePlaceView.mediumOpaqueDotOutlineImage
        let largeOpaqueDotImage = isExtraLarge ? ArticlePlaceView.extraLargeOpaqueDotImage : ArticlePlaceView.largeOpaqueDotImage
        let largeOpaqueDotOutlineImage = isExtraLarge ? ArticlePlaceView.extraLargeOpaqueDotOutlineImage : ArticlePlaceView.largeOpaqueDotOutlineImage
        
        let mediumPlaceholderImage = isExtraLarge ? ArticlePlaceView.extraMediumPlaceholderImage : ArticlePlaceView.mediumPlaceholderImage
        let largePlaceholderImage = isExtraLarge ? ArticlePlaceView.extraLargePlaceholderImage : ArticlePlaceView.largePlaceholderImage
        
        collapsedDimension = ArticlePlaceView.smallDotImage.size.width
        groupDimension = ArticlePlaceView.mediumDotImage.size.width
        dimension = largeOpaqueDotOutlineImage.size.width
        imageDimension = mediumOpaqueDotOutlineImage.size.width
        
        let gravity = kCAGravityBottomRight
        
        isPlaceholderHidden = false
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        frame = CGRect(x: 0, y: 0, width: dimension, height: dimension)
        
        dotView.bounds = CGRect(x: 0, y: 0, width: collapsedDimension, height: collapsedDimension)
        dotView.layer.contentsGravity = gravity
        dotView.layer.contentsScale = scale
        dotView.layer.contents = ArticlePlaceView.smallDotImage.cgImage
        dotView.center = CGPoint(x: 0.5*bounds.size.width, y: 0.5*bounds.size.height)
        addSubview(dotView)
        
        groupView.bounds = CGRect(x: 0, y: 0, width: groupDimension, height: groupDimension)
        groupView.layer.contentsGravity = gravity
        groupView.layer.contentsScale = scale
        groupView.layer.contents = ArticlePlaceView.mediumDotImage.cgImage
        addSubview(groupView)
        
        imageView.bounds = CGRect(x: 0, y: 0, width: imageDimension, height: imageDimension)
        imageView.layer.rasterizationScale = scale
        addSubview(imageView)
        
        imageBackgroundView.frame = imageView.bounds
        imageBackgroundView.layer.contentsGravity = gravity
        imageBackgroundView.layer.contentsScale = scale
        imageBackgroundView.layer.contents = mediumOpaqueDotImage.cgImage
        imageView.addSubview(imageBackgroundView)
        
        imageImagePlaceholderView.frame = imageView.bounds
        imageImagePlaceholderView.contentMode = .center
        imageImagePlaceholderView.image = mediumPlaceholderImage
        imageView.addSubview(imageImagePlaceholderView)
        
        imageImageView.frame = UIEdgeInsetsInsetRect(imageView.bounds, UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1))
        imageImageView.contentMode = .scaleAspectFill
        imageImageView.layer.masksToBounds = true
        imageImageView.layer.cornerRadius = imageImageView.bounds.size.width * 0.5
        imageImageView.backgroundColor = UIColor.white
        imageView.addSubview(imageImageView)
        
        imageOutlineView.frame = imageView.bounds
        imageOutlineView.layer.contentsGravity = gravity
        imageOutlineView.layer.contentsScale = scale
        imageOutlineView.layer.contents = mediumOpaqueDotOutlineImage.cgImage
        imageView.addSubview(imageOutlineView)
        
        selectedImageView.bounds = bounds
        selectedImageView.layer.rasterizationScale = scale
        addSubview(selectedImageView)
        
        selectedImageBackgroundView.frame = selectedImageView.bounds
        selectedImageBackgroundView.layer.contentsGravity = gravity
        selectedImageBackgroundView.layer.contentsScale = scale
        selectedImageBackgroundView.layer.contents = largeOpaqueDotImage.cgImage
        selectedImageView.addSubview(selectedImageBackgroundView)
        
        selectedImageImagePlaceholderView.frame = selectedImageView.bounds
        selectedImageImagePlaceholderView.contentMode = .center
        selectedImageImagePlaceholderView.image = largePlaceholderImage
        selectedImageView.addSubview(selectedImageImagePlaceholderView)
        
        selectedImageImageView.frame = UIEdgeInsetsInsetRect(selectedImageView.bounds, UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1))
        selectedImageImageView.contentMode = .scaleAspectFill
        selectedImageImageView.layer.cornerRadius = selectedImageView.bounds.size.width * 0.5
        selectedImageImageView.layer.masksToBounds = true
        selectedImageImageView.backgroundColor = UIColor.white
        selectedImageView.addSubview(selectedImageImageView)
        
        selectedImageOutlineView.frame = selectedImageView.bounds
        selectedImageOutlineView.layer.contentsGravity = gravity
        selectedImageOutlineView.layer.contentsScale = scale
        selectedImageOutlineView.layer.contents = largeOpaqueDotOutlineImage.cgImage
        selectedImageView.addSubview(selectedImageOutlineView)
        
        selectedImageButton.frame = selectedImageView.bounds
        selectedImageButton.accessibilityTraits = UIAccessibilityTraitNone
        selectedImageView.addSubview(selectedImageButton)
        
        countLabel.frame = groupView.bounds
        countLabel.textColor = UIColor.white
        countLabel.textAlignment = .center
        countLabel.font = UIFont.boldSystemFont(ofSize: 16)
        groupView.addSubview(countLabel)
        
        
        prepareForReuse()
        self.annotation = annotation
    }
        
    override convenience init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        self.init(annotation: annotation, reuseIdentifier: reuseIdentifier, isExtraLarge: false)
    }
    
    func selectedImageViewWasTapped(_ sender: UIButton) {
        delegate?.articlePlaceViewWasTapped(self)
    }
    
    var zPosition: CGFloat = 1 {
        didSet {
            guard !isSelected else {
                return
            }
            layer.zPosition = zPosition
        }
    }

    var isPlaceholderHidden: Bool {
        didSet {
            selectedImageImagePlaceholderView.isHidden = isPlaceholderHidden
            imageImagePlaceholderView.isHidden = isPlaceholderHidden
            imageImageView.isHidden = !isPlaceholderHidden
            selectedImageImageView.isHidden = !isPlaceholderHidden
        }
    }
    
    private var shouldRasterize = false {
        didSet {
            imageView.layer.shouldRasterize = shouldRasterize
            selectedImageView.layer.shouldRasterize = shouldRasterize
        }
    }
    
    private var isImageLoaded = false
    func loadImage() {
        guard !isImageLoaded, let articlePlace = annotation as? ArticlePlace, articlePlace.articles.count == 1 else {
            return
        }

        if alwaysRasterize {
            shouldRasterize = false
        }
        isPlaceholderHidden = false
        isImageLoaded = true
        let article = articlePlace.articles[0]
        if let thumbnailURL = article.thumbnailURL {
            imageImageView.wmf_setImage(with: thumbnailURL, detectFaces: true, onGPU: true, failure: { (error) in
                if self.alwaysRasterize {
                    self.shouldRasterize = true
                }
            }, success: {
                self.selectedImageImageView.image = self.imageImageView.image
                self.selectedImageImageView.layer.contentsRect = self.imageImageView.layer.contentsRect
                self.isPlaceholderHidden = true
                if self.alwaysRasterize {
                    self.shouldRasterize = true
                }
            })
        }
    }
    
    func update(withArticlePlace articlePlace: ArticlePlace) {
        if articlePlace.articles.count == 1 {
            zPosition = 1
            isImageLoaded = false
            if isSelected || alwaysShowImage {
                loadImage()
            }
            accessibilityLabel = articlePlace.articles.first?.displayTitle
        } else if articlePlace.articles.count == 0 {
            zPosition = 1
            isPlaceholderHidden = false
            imageImagePlaceholderView.image = #imageLiteral(resourceName: "places-show-more")
            accessibilityLabel = NSLocalizedString("places-accessibility-show-more", value:"Show more articles", comment:"Accessibility label for a button that shows more articles")
        } else {
            zPosition = 2
            let countString = "\(articlePlace.articles.count)"
            countLabel.text = countString
            accessibilityLabel = String.localizedStringWithFormat(NSLocalizedString("places-accessibility-group", value:"%1$@ articles", comment:"Accessibility label for a map icon - %1$@ is replaced with the number of articles in the group\n{{Identical|Article}}"), countString)
        }
        updateDotAndImageHiddenState(withArticlePlace: articlePlace)
    }
    
    func updateDotAndImageHiddenState(withArticlePlace articlePlace: ArticlePlace) {
        switch articlePlace.articles.count {
        case 0:
            fallthrough
        case 1:
            imageView.isHidden = !alwaysShowImage
            dotView.isHidden = alwaysShowImage
            groupView.isHidden = true
        default:
            imageView.isHidden = true
            dotView.isHidden = true
            groupView.isHidden = false
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
        if alwaysRasterize {
            shouldRasterize = false
        }
        isPlaceholderHidden = false
        isImageLoaded = false
        delegate = nil
        imageImageView.wmf_reset()
        selectedImageImageView.wmf_reset()
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
        let imageViewScale = imageDimension/dimension
        let scale = alwaysShowImage ? imageViewScale : dotScale
        let selectedImageViewScaleDownTransform = CGAffineTransform(scaleX: scale, y: scale)
        let dotViewScaleUpTransform = CGAffineTransform(scaleX: 1.0/dotScale, y: 1.0/dotScale)
        let imageViewScaleUpTransform = CGAffineTransform(scaleX: 1.0/imageViewScale, y: 1.0/imageViewScale)
        layer.zPosition = 3
        if selected {
            loadImage()
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
        if (animated && rasterizeOnAnimations) {
            shouldRasterize = true
        }
        let done = {
            if (animated && self.rasterizeOnAnimations) {
                self.shouldRasterize = false
            }
            if !selected {
                self.layer.zPosition = self.zPosition
            }
        }
        if animated {
            let duration = 2*selectionAnimationDuration
            if selected {
                UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: springDamping, initialSpringVelocity: 0, options: [.allowUserInteraction], animations: transforms, completion:nil)
                UIView.animateKeyframes(withDuration: duration, delay: 0, options: [.allowUserInteraction], animations: {
                    UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: self.crossFadeRelativeHalfDuration, animations:fadesIn)
                    UIView.addKeyframe(withRelativeStartTime: self.crossFadeRelativeHalfDuration, relativeDuration: self.crossFadeRelativeHalfDuration, animations:fadesOut)
                }) { (didFinish) in
                    done()
                }
            } else {
                UIView.animateKeyframes(withDuration: 0.5*duration, delay: 0, options: [.allowUserInteraction], animations: {
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
