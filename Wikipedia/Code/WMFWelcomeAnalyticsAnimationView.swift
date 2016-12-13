import Foundation

open class WMFWelcomeAnalyticsAnimationView : WMFWelcomeAnimationView {

    lazy var fileImgView: UIImageView = {
        let imgView = UIImageView(frame: self.bounds)
        imgView.image = UIImage(named: "ftux-file")
        imgView.contentMode = UIViewContentMode.scaleAspectFit
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
        return UIColor.wmf_color(withHex: 0x4A90E2, alpha: 1.0).cgColor
    }
    
    var barEvenColor: CGColor{
        return UIColor.wmf_color(withHex: 0x2A4B8D, alpha: 1.0).cgColor
    }

    lazy var bar1: WelcomeBarShapeLayer = {
        let bar = WelcomeBarShapeLayer(
            unitRect: CGRect(x: 0.313, y: 0.64, width: 0.039, height: 0.18),
            referenceSize:self.frame.size,
            transform: self.squashedHeightBarTransform
        )
        bar.fillColor = self.barOddColor
        return bar
    }()
    
    lazy var bar2: WelcomeBarShapeLayer = {
        let bar = WelcomeBarShapeLayer(
            unitRect: CGRect(x: 0.383, y: 0.64, width: 0.039, height: 0.23),
            referenceSize:self.frame.size,
            transform: self.squashedHeightBarTransform
        )
        bar.fillColor = self.barEvenColor
        return bar
    }()
    
    lazy var bar3: WelcomeBarShapeLayer = {
        let bar = WelcomeBarShapeLayer(
            unitRect: CGRect(x: 0.453, y: 0.64, width: 0.039, height: 0.06),
            referenceSize:self.frame.size,
            transform: self.squashedHeightBarTransform
        )
        bar.fillColor = self.barOddColor
        return bar
    }()
    
    lazy var bar4: WelcomeBarShapeLayer = {
        let bar = WelcomeBarShapeLayer(
            unitRect: CGRect(x: 0.523, y: 0.64, width: 0.039, height: 0.12),
            referenceSize:self.frame.size,
            transform: self.squashedHeightBarTransform
        )
        bar.fillColor = self.barEvenColor
        return bar
    }()
    
    lazy var bar5: WelcomeBarShapeLayer = {
        let bar = WelcomeBarShapeLayer(
            unitRect: CGRect(x: 0.593, y: 0.64, width: 0.039, height: 0.15),
            referenceSize:self.frame.size,
            transform: self.squashedHeightBarTransform
        )
        bar.fillColor = self.barOddColor
        return bar
    }()
    
    lazy var dashedCircle: WelcomeCircleShapeLayer = {
        return WelcomeCircleShapeLayer(
            unitRadius: 0.258,
            unitOrigin: CGPoint(x: 0.61, y: 0.44),
            referenceSize: self.frame.size,
            isDashed: true,
            transform: self.wmf_scaleZeroTransform,
            opacity:0.0
        )
    }()
    
    lazy var solidCircle: WelcomeCircleShapeLayer = {
        return WelcomeCircleShapeLayer(
            unitRadius: 0.235,
            unitOrigin: CGPoint(x: 0.654, y: 0.41),
            referenceSize: self.frame.size,
            isDashed: false,
            transform: self.wmf_scaleZeroTransform,
            opacity:0.0
        )
    }()
    
    lazy var plus1: WelcomePlusShapeLayer = {
        return WelcomePlusShapeLayer(
            unitOrigin: CGPoint(x: 0.9, y: 0.222),
            unitWidth: 0.05,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroTransform,
            opacity: 0.0
        )
    }()
    
    lazy var plus2: WelcomePlusShapeLayer = {
        return WelcomePlusShapeLayer(
            unitOrigin: CGPoint(x: 0.832, y: 0.167),
            unitWidth: 0.05,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroTransform,
            opacity: 0.0
        )
    }()
    
    lazy var line1: WelcomeLineShapeLayer = {
        return WelcomeLineShapeLayer(
            unitOrigin: CGPoint(x: 0.82, y: 0.778),
            unitWidth: 0.125,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroAndRightTransform,
            opacity: 0.0
        )
    }()
    
    lazy var line2: WelcomeLineShapeLayer = {
        return WelcomeLineShapeLayer(
            unitOrigin: CGPoint(x: 0.775, y: 0.736),
            unitWidth: 0.127,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroAndRightTransform,
            opacity: 0.0
        )
    }()
    
    lazy var line3: WelcomeLineShapeLayer = {
        return WelcomeLineShapeLayer(
            unitOrigin: CGPoint(x: 0.233, y: 0.385),
            unitWidth: 0.043,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroAndLeftTransform,
            opacity: 0.0
        )
    }()
    
    lazy var line4: WelcomeLineShapeLayer = {
        return WelcomeLineShapeLayer(
            unitOrigin: CGPoint(x: 0.17, y: 0.385),
            unitWidth: 0.015,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroAndLeftTransform,
            opacity: 0.0
        )
    }()
    
    lazy var line5: WelcomeLineShapeLayer = {
        return WelcomeLineShapeLayer(
            unitOrigin: CGPoint(x: 0.11, y: 0.427),
            unitWidth: 0.043,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroAndLeftTransform,
            opacity: 0.0
        )
    }()
    
    lazy var line6: WelcomeLineShapeLayer = {
        return WelcomeLineShapeLayer(
            unitOrigin: CGPoint(x: 0.173, y: 0.427),
            unitWidth: 0.015,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroAndLeftTransform,
            opacity: 0.0
        )
    }()
    
    override open func addAnimationElementsScaledToCurrentFrameSize(){
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
    
    override open func beginAnimations() {
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
