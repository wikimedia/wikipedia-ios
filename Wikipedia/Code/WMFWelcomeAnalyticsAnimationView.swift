import Foundation

public class WMFWelcomeAnalyticsAnimationView : WMFWelcomeAnimationView {

    lazy var fileImgView: UIImageView = {
        let imgView = UIImageView(frame: self.bounds)
        imgView.image = UIImage(named: "ftux-file")
        imgView.contentMode = UIViewContentMode.ScaleAspectFit
        imgView.layer.zPosition = 101
        imgView.layer.opacity = 0
        imgView.layer.transform = self.wmf_leftTransform
        return imgView
    }()
    
    var squashedHeightBarTransform: CATransform3D{
        return CATransform3DMakeScale(1, 0, 1)
    }
    
    var fullHeightBarTransform: CATransform3D{
        return CATransform3DMakeScale(1, -1, 1) // -1 to flip Y so bars grow from bottom up.
    }

    var barOddColor: CGColor{
        return UIColor.wmf_colorWithHex(0x4A90E2, alpha: 1.0).CGColor
    }
    
    var barEvenColor: CGColor{
        return UIColor.wmf_colorWithHex(0x2A4B8D, alpha: 1.0).CGColor
    }

    lazy var bar1: WelcomeBarShapeLayer = {
        let bar = WelcomeBarShapeLayer(
            unitRect: CGRectMake(0.313, 0.64, 0.039, 0.18),
            referenceSize:self.frame.size,
            transform: self.squashedHeightBarTransform
        )
        bar.fillColor = self.barOddColor
        return bar
    }()
    
    lazy var bar2: WelcomeBarShapeLayer = {
        let bar = WelcomeBarShapeLayer(
            unitRect: CGRectMake(0.383, 0.64, 0.039, 0.23),
            referenceSize:self.frame.size,
            transform: self.squashedHeightBarTransform
        )
        bar.fillColor = self.barEvenColor
        return bar
    }()
    
    lazy var bar3: WelcomeBarShapeLayer = {
        let bar = WelcomeBarShapeLayer(
            unitRect: CGRectMake(0.453, 0.64, 0.039, 0.06),
            referenceSize:self.frame.size,
            transform: self.squashedHeightBarTransform
        )
        bar.fillColor = self.barOddColor
        return bar
    }()
    
    lazy var bar4: WelcomeBarShapeLayer = {
        let bar = WelcomeBarShapeLayer(
            unitRect: CGRectMake(0.523, 0.64, 0.039, 0.12),
            referenceSize:self.frame.size,
            transform: self.squashedHeightBarTransform
        )
        bar.fillColor = self.barEvenColor
        return bar
    }()
    
    lazy var bar5: WelcomeBarShapeLayer = {
        let bar = WelcomeBarShapeLayer(
            unitRect: CGRectMake(0.593, 0.64, 0.039, 0.15),
            referenceSize:self.frame.size,
            transform: self.squashedHeightBarTransform
        )
        bar.fillColor = self.barOddColor
        return bar
    }()
    
    lazy var dashedCircle: WelcomeCircleShapeLayer = {
        return WelcomeCircleShapeLayer(
            unitRadius: 0.258,
            unitOrigin: CGPointMake(0.61, 0.44),
            referenceSize: self.frame.size,
            isDashed: true,
            transform: self.wmf_scaleZeroTransform,
            opacity:0.0
        )
    }()
    
    lazy var solidCircle: WelcomeCircleShapeLayer = {
        return WelcomeCircleShapeLayer(
            unitRadius: 0.235,
            unitOrigin: CGPointMake(0.654, 0.41),
            referenceSize: self.frame.size,
            isDashed: false,
            transform: self.wmf_scaleZeroTransform,
            opacity:0.0
        )
    }()
    
    lazy var plus1: WelcomePlusShapeLayer = {
        return WelcomePlusShapeLayer(
            unitOrigin: CGPointMake(0.9, 0.222),
            unitWidth: 0.05,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroTransform,
            opacity: 0.0
        )
    }()
    
    lazy var plus2: WelcomePlusShapeLayer = {
        return WelcomePlusShapeLayer(
            unitOrigin: CGPointMake(0.832, 0.167),
            unitWidth: 0.05,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroTransform,
            opacity: 0.0
        )
    }()
    
    lazy var line1: WelcomeLineShapeLayer = {
        return WelcomeLineShapeLayer(
            unitOrigin: CGPointMake(0.82, 0.778),
            unitWidth: 0.125,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroAndRightTransform,
            opacity: 0.0
        )
    }()
    
    lazy var line2: WelcomeLineShapeLayer = {
        return WelcomeLineShapeLayer(
            unitOrigin: CGPointMake(0.775, 0.736),
            unitWidth: 0.127,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroAndRightTransform,
            opacity: 0.0
        )
    }()
    
    lazy var line3: WelcomeLineShapeLayer = {
        return WelcomeLineShapeLayer(
            unitOrigin: CGPointMake(0.233, 0.385),
            unitWidth: 0.043,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroAndLeftTransform,
            opacity: 0.0
        )
    }()
    
    lazy var line4: WelcomeLineShapeLayer = {
        return WelcomeLineShapeLayer(
            unitOrigin: CGPointMake(0.17, 0.385),
            unitWidth: 0.015,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroAndLeftTransform,
            opacity: 0.0
        )
    }()
    
    lazy var line5: WelcomeLineShapeLayer = {
        return WelcomeLineShapeLayer(
            unitOrigin: CGPointMake(0.11, 0.427),
            unitWidth: 0.043,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroAndLeftTransform,
            opacity: 0.0
        )
    }()
    
    lazy var line6: WelcomeLineShapeLayer = {
        return WelcomeLineShapeLayer(
            unitOrigin: CGPointMake(0.173, 0.427),
            unitWidth: 0.015,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroAndLeftTransform,
            opacity: 0.0
        )
    }()
    
    override public func addAnimationElementsScaledToCurrentFrameSize(){
        removeExistingSubviewsAndSublayers()

        self.addSubview(self.fileImgView)
        
        _ = [
            self.bar1,
            self.bar2,
            self.bar3,
            self.bar4,
            self.bar5
            ].map({ (layer: CALayer) -> () in
                fileImgView.layer.addSublayer(layer)
            })
        
        _ = [
            self.solidCircle,
            self.dashedCircle,
            self.plus1,
            self.plus2,
            self.line1,
            self.line2,
            self.line3,
            self.line4,
            self.line5,
            self.line6
            ].map({ (layer: CALayer) -> () in
                self.layer.addSublayer(layer)
            })
    }
    
    override public func beginAnimations() {
        CATransaction.begin()
        
        fileImgView.layer.wmf_animateToOpacity(1.0,
            transform: CATransform3DIdentity,
            delay: 0.1,
            duration: 1.0
        )
        
        self.solidCircle.wmf_animateToOpacity(0.04,
            transform: CATransform3DIdentity,
            delay: 0.3,
            duration: 1.0
        )

        var barIndex = 0
        let animateBarGrowingUp = { (layer: CALayer) -> () in
            layer.wmf_animateToOpacity(1.0,
                transform: self.fullHeightBarTransform,
                delay: (0.3 + (Double(barIndex) * 0.1)),
                duration: 0.3
            )
            barIndex+=1
        }
        
        _ = [
            self.bar1,
            self.bar2,
            self.bar3,
            self.bar4,
            self.bar5
            ].map(animateBarGrowingUp)
        
        let animate = { (layer: CALayer) -> () in
            layer.wmf_animateToOpacity(0.15,
                transform: CATransform3DIdentity,
                delay: 0.3,
                duration: 1.0
            )
        }
        
        _ = [
            self.dashedCircle,
            self.plus1,
            self.plus2,
            self.line1,
            self.line2,
            self.line3,
            self.line4,
            self.line5,
            self.line6
            ].map(animate)
        
        CATransaction.commit()
    }
}
