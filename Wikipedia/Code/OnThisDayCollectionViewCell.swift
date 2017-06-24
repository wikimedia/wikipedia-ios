import UIKit

@objc(WMFOnThisDayCollectionViewCell)
class OnThisDayCollectionViewCell: SideScrollingCollectionViewCell {

    let timelineView = OnThisDayTimelineView()

    @objc(configureWithOnThisDayEvent:dataStore:layoutOnly:)
    func configure(with onThisDayEvent: WMFFeedOnThisDayEvent, dataStore: MWKDataStore, layoutOnly: Bool) {
        let previews = onThisDayEvent.articlePreviews ?? []
        let currentYear = Calendar.current.component(.year, from: Date())
        
        titleLabel.textColor = .wmf_blue
        subTitleLabel.textColor = .wmf_customGray
        
        titleLabel.text = onThisDayEvent.yearWithEraString()

        if let eventYear = onThisDayEvent.year {
            let yearsSinceEvent = currentYear - eventYear.intValue
            subTitleLabel.text = String.localizedStringWithFormat(WMFLocalizedDateFormatStrings.yearsAgo(), yearsSinceEvent)
        } else {
            subTitleLabel.text = nil
        }
            
        descriptionLabel.text = onThisDayEvent.text
        
        articles = previews.map { (articlePreview) -> CellArticle in
            let articleLanguage = (articlePreview.articleURL as NSURL?)?.wmf_language
            let description = articlePreview.wikidataDescription?.wmf_stringByCapitalizingFirstCharacter(usingWikipediaLanguage: articleLanguage)
            return CellArticle(articleURL:articlePreview.articleURL, title: articlePreview.displayTitle, description: description, imageURL: articlePreview.thumbnailURL)
        }
        
        let articleLanguage = (onThisDayEvent.articlePreviews?.first?.articleURL as NSURL?)?.wmf_language
        descriptionLabel.accessibilityLanguage = articleLanguage
        semanticContentAttributeOverride = MWLanguageInfo.semanticContentAttribute(forWMFLanguage: articleLanguage)
        
        isImageViewHidden = true

        setNeedsLayout()
    }
    
    static let descriptionTextStyle = UIFontTextStyle.subheadline
    var descriptionFont = UIFont.preferredFont(forTextStyle: descriptionTextStyle)
    
    static let titleTextStyle = UIFontTextStyle.title3
    var titleFont = UIFont.preferredFont(forTextStyle: titleTextStyle)
    
    static let subTitleTextStyle = UIFontTextStyle.subheadline
    var subTitleFont = UIFont.preferredFont(forTextStyle: subTitleTextStyle)
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        titleLabel.font = titleFont
        subTitleLabel.font = subTitleFont
        descriptionLabel.font = descriptionFont
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {

        let timelineViewWidth:CGFloat = 66.0
        timelineView.frame = CGRect(x: bounds.origin.x, y: bounds.origin.y, width: timelineViewWidth, height: bounds.size.height)
        
        margins.left = timelineViewWidth
        return super.sizeThatFits(size, apply: apply)
    }
    
    override open func setup() {
        super.setup()
        collectionView.backgroundColor = .clear
        insertSubview(timelineView, belowSubview: collectionView)
    }
    
    var pauseDotsAnimation: Bool = true {
        didSet {
            timelineView.pauseDotsAnimation = pauseDotsAnimation
        }
    }
    
    override var isHidden: Bool {
        didSet {
            timelineView.pauseDotsAnimation = isHidden
        }
    }

    var shouldAnimateDots: Bool = false {
        didSet {
            timelineView.shouldAnimateDots = shouldAnimateDots
        }
    }
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        timelineView.dotY = titleLabel.convert(titleLabel.bounds, to: timelineView).midY
    }
}

class OnThisDayTimelineView: UIView {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    open func setup() {
        backgroundColor = .clear
    }

    public var shouldAnimateDots: Bool = false
    
    public var pauseDotsAnimation: Bool = true {
        didSet {
            displayLink?.isPaused = pauseDotsAnimation
        }
    }
    
    public var dotY: CGFloat = 0

    private lazy var outerDotShapeLayer: CAShapeLayer = {
        let shape = CAShapeLayer()
        shape.fillColor = UIColor.white.cgColor
        shape.strokeColor = UIColor.wmf_blue.cgColor
        shape.lineWidth = 1.0
        self.layer.addSublayer(shape)
        return shape
    }()

    private lazy var innerDotShapeLayer: CAShapeLayer = {
        let shape = CAShapeLayer()
        shape.fillColor = UIColor.wmf_blue.cgColor
        shape.strokeColor = UIColor.wmf_blue.cgColor
        shape.lineWidth = 1.0
        self.layer.addSublayer(shape)
        return shape
    }()

    private lazy var displayLink: CADisplayLink? = {
        guard self.shouldAnimateDots == true else {
            return nil
        }
        let link = CADisplayLink(target: self, selector: #selector(maybeUpdateDotsRadii(_:)))
        link.add(to: RunLoop.main, forMode: RunLoopMode.commonModes)
        return link
    }()
    
    override func removeFromSuperview() {
        displayLink?.invalidate()
        displayLink = nil
        super.removeFromSuperview()
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        drawVerticalLine(in: context, rect: rect)
    }
    
    private func drawVerticalLine(in context: CGContext, rect: CGRect){
        context.setLineWidth(1.0)
        context.setStrokeColor(UIColor.wmf_blue.cgColor)
        context.move(to: CGPoint(x: rect.midX, y: rect.minY))
        context.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        context.strokePath()
    }
    
    // Returns CGFloat in range from 0.0 to 1.0. 0.0 indicates dot should be minimized.
    // 1.0 indicates dot should be maximized. Approaches 1.0 as timelineView.dotY
    // approaches vertical center. Approaches 0.0 as timelineView.dotY approaches top
    // or bottom.
    private func dotRadiusNormal(with y:CGFloat, in container:UIView) -> CGFloat {
        let yInContainer = convert(CGPoint(x:0, y:y), to: container).y
        let halfContainerHeight = container.bounds.size.height * 0.5
        return max(0.0, 1.0 - (abs(yInContainer - halfContainerHeight) / halfContainerHeight))
    }

    private var lastDotRadiusNormal: CGFloat = -1.0 // -1.0 so dots with dotAnimationNormal of "0.0" are visible initially
    
    @objc private func maybeUpdateDotsRadii(_ : CADisplayLink) {
        guard let containerView = window else {
            return
        }

        // Shift the "full-width dot" point up a bit - otherwise it's in the vertical center of screen.
        let yOffset = containerView.bounds.size.height * 0.18

        var thisRadiusNormal = dotRadiusNormal(with: dotY + yOffset, in: containerView)

        // Reminder: can reduce precision to 1 (significant digit) to reduce how often dot radii are updated.
        let precision: CGFloat = 2
        let roundingNumber = pow(10, precision)
        thisRadiusNormal = (thisRadiusNormal * roundingNumber).rounded(.up) / roundingNumber
        
        guard thisRadiusNormal != lastDotRadiusNormal else {
            return
        }
        
        let dotCenter = CGPoint(x: frame.midX, y: dotY)
        updateDotsRadii(with: dotCenter, radiusNormal: thisRadiusNormal)
        
        lastDotRadiusNormal = thisRadiusNormal
    }
    
    private func updateDotsRadii(with center: CGPoint, radiusNormal: CGFloat) {
        let baseRadius:CGFloat = 9.0
        let endAngle:CGFloat = CGFloat.pi * 2.0
        
        let outerDotRadius = baseRadius * max(radiusNormal, 0.4)
        outerDotShapeLayer.path = UIBezierPath(arcCenter: center, radius: outerDotRadius, startAngle: 0.0, endAngle:endAngle, clockwise: true).cgPath
        
        let innerDotRadius = baseRadius * max((radiusNormal - 0.4), 0.0)
        innerDotShapeLayer.path = UIBezierPath(arcCenter: center, radius: innerDotRadius, startAngle: 0.0, endAngle:endAngle, clockwise: true).cgPath
    }
}
