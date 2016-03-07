import Foundation

public class WelcomeAnalyticsAnimationView : WelcomeAnimationView {

    var fileImgView: UIImageView
    var bar1: WelcomeBarShapeLayer?
    var bar2: WelcomeBarShapeLayer?
    var bar3: WelcomeBarShapeLayer?
    var bar4: WelcomeBarShapeLayer?
    var bar5: WelcomeBarShapeLayer?
    var dashedCircle: WelcomeCircleShapeLayer?
    var solidCircle: WelcomeCircleShapeLayer?
    var plus1: WelcomePlusShapeLayer?
    var plus2: WelcomePlusShapeLayer?
    var line1: WelcomeLineShapeLayer?
    var line2: WelcomeLineShapeLayer?
    var line3: WelcomeLineShapeLayer?
    var line4: WelcomeLineShapeLayer?
    var line5: WelcomeLineShapeLayer?
    var line6: WelcomeLineShapeLayer?
    
    required public init?(coder aDecoder: NSCoder) {
        self.fileImgView = UIImageView()
        super.init(coder: aDecoder)
    }

    override public func didMoveToSuperview() {
        super.didMoveToSuperview()

        fileImgView.frame = self.bounds
        fileImgView.image = UIImage(named: "ftux-file")
        fileImgView.contentMode = UIViewContentMode.ScaleAspectFit
        fileImgView.layer.zPosition = 101
        fileImgView.layer.opacity = 0
        fileImgView.layer.transform = self.wmf_leftTransform
        self.addSubview(fileImgView)
        
        let squashedHeightBarTransform = CATransform3DMakeScale(1, 0, 1)

        // Reminder: no need to start bars with opacity 0 because fileImgView, to which the bars are added, already
        // fades from 0 to 1 opacity
        bar1 = WelcomeBarShapeLayer(
            unitRect: CGRectMake(0.313, 0.64, 0.039, 0.18),
            referenceSize:self.frame.size,
            transform: squashedHeightBarTransform
        )
        fileImgView.layer.addSublayer(bar1!)

        bar2 = WelcomeBarShapeLayer(
            unitRect: CGRectMake(0.383, 0.64, 0.039, 0.23),
            referenceSize:self.frame.size,
            transform: squashedHeightBarTransform
        )
        fileImgView.layer.addSublayer(bar2!)

        bar3 = WelcomeBarShapeLayer(
            unitRect: CGRectMake(0.453, 0.64, 0.039, 0.06),
            referenceSize:self.frame.size,
            transform: squashedHeightBarTransform
        )
        fileImgView.layer.addSublayer(bar3!)

        bar4 = WelcomeBarShapeLayer(
            unitRect: CGRectMake(0.523, 0.64, 0.039, 0.12),
            referenceSize:self.frame.size,
            transform: squashedHeightBarTransform
        )
        fileImgView.layer.addSublayer(bar4!)

        bar5 = WelcomeBarShapeLayer(
            unitRect: CGRectMake(0.593, 0.64, 0.039, 0.15),
            referenceSize:self.frame.size,
            transform: squashedHeightBarTransform
        )
        fileImgView.layer.addSublayer(bar5!)

        let blue = UIColor(red: 0.1216, green: 0.5804, blue: 0.8667, alpha: 1.0).CGColor
        let green = UIColor(red: 0.0000, green: 0.6941, blue: 0.5490, alpha: 1.0).CGColor
        bar1?.fillColor = blue
        bar2?.fillColor = green
        bar3?.fillColor = blue
        bar4?.fillColor = green
        bar5?.fillColor = blue
        
        self.solidCircle = WelcomeCircleShapeLayer(
            unitRadius: 0.235,
            unitOrigin: CGPointMake(0.654, 0.41),
            referenceSize: self.frame.size,
            isDashed: false,
            transform: self.wmf_scaleZeroTransform,
            opacity:0.0
        )
        self.layer.addSublayer(self.solidCircle!)
        
        self.dashedCircle = WelcomeCircleShapeLayer(
            unitRadius: 0.258,
            unitOrigin: CGPointMake(0.61, 0.44),
            referenceSize: self.frame.size,
            isDashed: true,
            transform: self.wmf_scaleZeroTransform,
            opacity:0.0
        )
        self.layer.addSublayer(self.dashedCircle!)
        
        self.plus1 = WelcomePlusShapeLayer(
            unitOrigin: CGPointMake(0.9, 0.222),
            unitWidth: 0.05,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroTransform,
            opacity: 0.0
        )
        self.layer.addSublayer(self.plus1!)

        self.plus2 = WelcomePlusShapeLayer(
            unitOrigin: CGPointMake(0.832, 0.167),
            unitWidth: 0.05,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroTransform,
            opacity: 0.0
        )
        self.layer.addSublayer(self.plus2!)

        self.line1 = WelcomeLineShapeLayer(
            unitOrigin: CGPointMake(0.82, 0.778),
            unitWidth: 0.125,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroAndRightTransform,
            opacity: 0.0
        )
        self.layer.addSublayer(self.line1!)

        self.line2 = WelcomeLineShapeLayer(
            unitOrigin: CGPointMake(0.775, 0.736),
            unitWidth: 0.127,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroAndRightTransform,
            opacity: 0.0
        )
        self.layer.addSublayer(self.line2!)

        self.line3 = WelcomeLineShapeLayer(
            unitOrigin: CGPointMake(0.233, 0.385),
            unitWidth: 0.043,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroAndLeftTransform,
            opacity: 0.0
        )
        self.layer.addSublayer(self.line3!)

        self.line4 = WelcomeLineShapeLayer(
            unitOrigin: CGPointMake(0.17, 0.385),
            unitWidth: 0.015,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroAndLeftTransform,
            opacity: 0.0
        )
        self.layer.addSublayer(self.line4!)

        self.line5 = WelcomeLineShapeLayer(
            unitOrigin: CGPointMake(0.11, 0.427),
            unitWidth: 0.043,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroAndLeftTransform,
            opacity: 0.0
        )
        self.layer.addSublayer(self.line5!)

        self.line6 = WelcomeLineShapeLayer(
            unitOrigin: CGPointMake(0.173, 0.427),
            unitWidth: 0.015,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroAndLeftTransform,
            opacity: 0.0
        )
        self.layer.addSublayer(self.line6!)
    }
    
    public func beginAnimations() {
        CATransaction.begin()
        
        fileImgView.layer.wmf_animateToOpacity(1.0,
            transform: CATransform3DIdentity,
            delay: 0.1,
            duration: 1.0
        )
        
        self.solidCircle?.wmf_animateToOpacity(0.04,
            transform: CATransform3DIdentity,
            delay: 0.3,
            duration: 1.0
        )

        var barIndex = 0
        let fullHeightBarTransform = CATransform3DMakeScale(1, -1, 1) // -1 to flip Y so bars grow from bottom up.
        let animateBarGrowingUp = { (layer: CALayer) -> () in
            layer.wmf_animateToOpacity(1.0,
                transform: fullHeightBarTransform,
                delay: (0.3 + (Double(barIndex) * 0.1)),
                duration: 0.3
            )
            barIndex++
        }
        
        _ = [
            self.bar1!,
            self.bar2!,
            self.bar3!,
            self.bar4!,
            self.bar5!
            ].map(animateBarGrowingUp)
        
        let animate = { (layer: CALayer) -> () in
            layer.wmf_animateToOpacity(0.15,
                transform: CATransform3DIdentity,
                delay: 0.3,
                duration: 1.0
            )
        }
        
        _ = [
            self.dashedCircle!,
            self.plus1!,
            self.plus2!,
            self.line1!,
            self.line2!,
            self.line3!,
            self.line4!,
            self.line5!,
            self.line6!
            ].map(animate)
        
        CATransaction.commit()
    }
}
