import Foundation

open class WMFWelcomeAnalyticsAnimationBackgroundView : WMFWelcomeAnimationView {

    lazy var fileImgView: UIImageView = {
        let imgView = UIImageView(frame: bounds)
        imgView.image = UIImage(named: "ftux-file")
        imgView.contentMode = UIViewContentMode.scaleAspectFit
        imgView.layer.zPosition = 101
        imgView.layer.opacity = 0
        imgView.layer.transform = wmf_leftTransform
        return imgView
    }()
    
    var squashedHeightBarTransform: CATransform3D{
        return CATransform3DMakeScale(1, 0, 1)
    }
    
    var fullHeightBarTransform: CATransform3D{
        return CATransform3DMakeScale(1, -1, 1) // -1 to flip Y so bars grow from bottom up.
    }

    var barOddColor: CGColor{
        return UIColor(0x4A90E2).cgColor
    }
    
    var barEvenColor: CGColor{
        return UIColor(0x2A4B8D).cgColor
    }

    lazy var bar1: WelcomeBarShapeLayer = {
        let bar = WelcomeBarShapeLayer(
            unitRect: CGRect(x: 0.313, y: 0.64, width: 0.039, height: 0.18),
            referenceSize: frame.size,
            transform: squashedHeightBarTransform
        )
        bar.fillColor = barOddColor
        return bar
    }()
    
    lazy var bar2: WelcomeBarShapeLayer = {
        let bar = WelcomeBarShapeLayer(
            unitRect: CGRect(x: 0.383, y: 0.64, width: 0.039, height: 0.23),
            referenceSize: frame.size,
            transform: squashedHeightBarTransform
        )
        bar.fillColor = barEvenColor
        return bar
    }()
    
    lazy var bar3: WelcomeBarShapeLayer = {
        let bar = WelcomeBarShapeLayer(
            unitRect: CGRect(x: 0.453, y: 0.64, width: 0.039, height: 0.06),
            referenceSize:frame.size,
            transform: squashedHeightBarTransform
        )
        bar.fillColor = barOddColor
        return bar
    }()
    
    lazy var bar4: WelcomeBarShapeLayer = {
        let bar = WelcomeBarShapeLayer(
            unitRect: CGRect(x: 0.523, y: 0.64, width: 0.039, height: 0.12),
            referenceSize: frame.size,
            transform: squashedHeightBarTransform
        )
        bar.fillColor = barEvenColor
        return bar
    }()
    
    lazy var bar5: WelcomeBarShapeLayer = {
        let bar = WelcomeBarShapeLayer(
            unitRect: CGRect(x: 0.593, y: 0.64, width: 0.039, height: 0.15),
            referenceSize: frame.size,
            transform: squashedHeightBarTransform
        )
        bar.fillColor = barOddColor
        return bar
    }()
    
    lazy var dashedCircle: WelcomeCircleShapeLayer = {
        return WelcomeCircleShapeLayer(
            unitRadius: 0.258,
            unitOrigin: CGPoint(x: 0.61, y: 0.44),
            referenceSize: frame.size,
            isDashed: true,
            transform: wmf_scaleZeroTransform,
            opacity:0.0
        )
    }()
    
    lazy var solidCircle: WelcomeCircleShapeLayer = {
        return WelcomeCircleShapeLayer(
            unitRadius: 0.235,
            unitOrigin: CGPoint(x: 0.654, y: 0.41),
            referenceSize: frame.size,
            isDashed: false,
            transform: wmf_scaleZeroTransform,
            opacity:0.0
        )
    }()
    
    lazy var plus1: WelcomePlusShapeLayer = {
        return WelcomePlusShapeLayer(
            unitOrigin: CGPoint(x: 0.9, y: 0.222),
            unitWidth: 0.05,
            referenceSize: frame.size,
            transform: wmf_scaleZeroTransform,
            opacity: 0.0
        )
    }()
    
    lazy var plus2: WelcomePlusShapeLayer = {
        return WelcomePlusShapeLayer(
            unitOrigin: CGPoint(x: 0.832, y: 0.167),
            unitWidth: 0.05,
            referenceSize: frame.size,
            transform: wmf_scaleZeroTransform,
            opacity: 0.0
        )
    }()
    
    lazy var line1: WelcomeLineShapeLayer = {
        return WelcomeLineShapeLayer(
            unitOrigin: CGPoint(x: 0.82, y: 0.778),
            unitWidth: 0.125,
            referenceSize: frame.size,
            transform: wmf_scaleZeroAndRightTransform,
            opacity: 0.0
        )
    }()
    
    lazy var line2: WelcomeLineShapeLayer = {
        return WelcomeLineShapeLayer(
            unitOrigin: CGPoint(x: 0.775, y: 0.736),
            unitWidth: 0.127,
            referenceSize: frame.size,
            transform: wmf_scaleZeroAndRightTransform,
            opacity: 0.0
        )
    }()
    
    lazy var line3: WelcomeLineShapeLayer = {
        return WelcomeLineShapeLayer(
            unitOrigin: CGPoint(x: 0.233, y: 0.385),
            unitWidth: 0.043,
            referenceSize: frame.size,
            transform: wmf_scaleZeroAndLeftTransform,
            opacity: 0.0
        )
    }()
    
    lazy var line4: WelcomeLineShapeLayer = {
        return WelcomeLineShapeLayer(
            unitOrigin: CGPoint(x: 0.17, y: 0.385),
            unitWidth: 0.015,
            referenceSize: frame.size,
            transform: wmf_scaleZeroAndLeftTransform,
            opacity: 0.0
        )
    }()
    
    lazy var line5: WelcomeLineShapeLayer = {
        return WelcomeLineShapeLayer(
            unitOrigin: CGPoint(x: 0.11, y: 0.427),
            unitWidth: 0.043,
            referenceSize: frame.size,
            transform: wmf_scaleZeroAndLeftTransform,
            opacity: 0.0
        )
    }()
    
    lazy var line6: WelcomeLineShapeLayer = {
        return WelcomeLineShapeLayer(
            unitOrigin: CGPoint(x: 0.173, y: 0.427),
            unitWidth: 0.015,
            referenceSize: frame.size,
            transform: wmf_scaleZeroAndLeftTransform,
            opacity: 0.0
        )
    }()
    
    override open func addAnimationElementsScaledToCurrentFrameSize(){
        removeExistingSubviewsAndSublayers()

        addSubview(fileImgView)
        
        [
            bar1,
            bar2,
            bar3,
            bar4,
            bar5
            ].forEach(fileImgView.layer.addSublayer)
        
        [
            solidCircle,
            dashedCircle,
            plus1,
            plus2,
            line1,
            line2,
            line3,
            line4,
            line5,
            line6
            ].forEach(layer.addSublayer)
    }
    
    override open func beginAnimations() {
        CATransaction.begin()
        
        fileImgView.layer.wmf_animateToOpacity(1.0,
            transform: CATransform3DIdentity,
            delay: 0.1,
            duration: 1.0
        )
        
        solidCircle.wmf_animateToOpacity(0.04,
            transform: CATransform3DIdentity,
            delay: 0.3,
            duration: 1.0
        )

        var barIndex = 0
        let animateBarGrowingUp = { (layer: CALayer) in
            layer.wmf_animateToOpacity(1.0,
                transform: self.fullHeightBarTransform,
                delay: (0.3 + (Double(barIndex) * 0.1)),
                duration: 0.3
            )
            barIndex+=1
        }
        
        [
            bar1,
            bar2,
            bar3,
            bar4,
            bar5
            ].forEach(animateBarGrowingUp)
        
        let animate = { (layer: CALayer) in
            layer.wmf_animateToOpacity(0.15,
                transform: CATransform3DIdentity,
                delay: 0.3,
                duration: 1.0
            )
        }
        
        [
            dashedCircle,
            plus1,
            plus2,
            line1,
            line2,
            line3,
            line4,
            line5,
            line6
            ].forEach(animate)
        
        CATransaction.commit()
    }
}
