import Foundation

struct WelcomePlus {
    var position: CGPoint
    var animation: WelcomeAnimation
}

struct WelcomeCircle {
    var position: CGPoint
    var radius: CGFloat
    var isDashed: Bool
    var animation: WelcomeAnimation
}

struct WelcomeLine {
    var position: CGPoint
    var width: CGFloat
    var animation: WelcomeAnimation
}

struct WelcomeImage {
    var name: String
    var frame: CGRect
    var zPosition: CGFloat
    var animation: WelcomeAnimation
}

struct WelcomeBar {
    var frame: CGRect
    var color: UIColor
    var cornerRadius: CGFloat
    var animation: WelcomeAnimation
}

struct WelcomeAnimation {
    var delay: Double
    var duration: Double
    var initialOpacity: Double
    var finalOpacity: Double
    var initialTransform: CATransform3D
    var finalTransform: CATransform3D
}

extension UIBezierPath {
    class func wmf_circlePathWithRadius(radius: CGFloat) -> UIBezierPath {
        return UIBezierPath(
            arcCenter: CGPointZero,
            radius: radius,
            startAngle: 0.0,
            endAngle: CGFloat(M_PI * 2.0),
            clockwise: true
        )
    }
    class func wmf_horizontalLinePathWithWidth(width: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        path.moveToPoint(CGPointMake(width * -0.5, 0.0))
        path.addLineToPoint(CGPointMake(width * 0.5, 0.0))
        return path
    }
    class func wmf_verticalLinePathWithHeight(height: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        path.moveToPoint(CGPointMake(0.0, height * -0.5))
        path.addLineToPoint(CGPointMake(0.0, height * 0.5))
        return path
    }
    class func wmf_plusPathWithWidth(width: CGFloat) -> UIBezierPath {
        let path = UIBezierPath.wmf_horizontalLinePathWithWidth(width)
        path.appendPath(UIBezierPath.wmf_verticalLinePathWithHeight(width))
        return path
    }
}

extension CAShapeLayer {
    func wmf_applyCommonSettingsForSize(size: CGSize, position: CGPoint, initialOpacity: Double) -> Void {
        self.lineCap = "round"
        self.opacity = Float(initialOpacity)
        self.lineWidth = size.width * 0.014
        self.strokeEnd = 1.0
        self.position = CGPointMake(size.width * position.x, size.height * position.y)
        self.zPosition = 100
    }
    class func wmf_addLine(line: WelcomeLine, toView: UIView) -> CAShapeLayer {
        let shape = CAShapeLayer()
        shape.path = UIBezierPath.wmf_horizontalLinePathWithWidth(toView.frame.size.width * line.width).CGPath
        shape.strokeColor = UIColor.blackColor().CGColor
        shape.transform = line.animation.initialTransform
        shape.wmf_applyCommonSettingsForSize(toView.frame.size, position: line.position, initialOpacity: line.animation.initialOpacity)
        toView.layer.addSublayer(shape)
        return shape;
    }
    class func wmf_addDashedCircle(circle: WelcomeCircle, toView: UIView) -> CAShapeLayer {
        let shape = CAShapeLayer()
        shape.path = UIBezierPath.wmf_circlePathWithRadius(toView.frame.size.width * circle.radius).CGPath
        shape.fillColor = UIColor.clearColor().CGColor
        shape.strokeColor = UIColor.blackColor().CGColor
        shape.lineDashPattern = [toView.frame.size.width * 0.029, toView.frame.size.width * 0.047]
        shape.transform = circle.animation.initialTransform
        shape.wmf_applyCommonSettingsForSize(toView.frame.size, position: circle.position, initialOpacity: circle.animation.initialOpacity)
        toView.layer.addSublayer(shape)
        return shape;
    }
    class func wmf_addCircle(circle: WelcomeCircle, toView: UIView) -> CAShapeLayer {
        let shape = CAShapeLayer()
        shape.path = UIBezierPath.wmf_circlePathWithRadius(toView.frame.size.width * circle.radius).CGPath
        shape.fillColor = UIColor.blackColor().CGColor
        shape.strokeColor = UIColor.clearColor().CGColor
        shape.transform = circle.animation.initialTransform
        shape.wmf_applyCommonSettingsForSize(toView.frame.size, position: circle.position, initialOpacity: circle.animation.initialOpacity)
        toView.layer.addSublayer(shape)
        return shape;
    }
    class func wmf_addPlus(plus: WelcomePlus, toView: UIView) -> CAShapeLayer {
        let shape = CAShapeLayer()
        shape.path = UIBezierPath.wmf_plusPathWithWidth(toView.frame.size.width * 0.04).CGPath
        shape.strokeColor = UIColor.blackColor().CGColor
        shape.transform = plus.animation.initialTransform
        shape.wmf_applyCommonSettingsForSize(toView.frame.size, position: plus.position, initialOpacity: plus.animation.initialOpacity)
        toView.layer.addSublayer(shape)
        return shape;
    }
    class func wmf_addBar(bar: WelcomeBar, toView: UIView) -> CAShapeLayer {
        let shape = CAShapeLayer()
        let rect = CGRectMake(
            0.0,
            0.0,
            toView.frame.size.width * bar.frame.size.width,
            toView.frame.size.height * bar.frame.size.height
        )
        shape.path = UIBezierPath(roundedRect: rect, cornerRadius: bar.cornerRadius).CGPath
        shape.fillColor = bar.color.CGColor
        shape.transform = bar.animation.initialTransform
        shape.position = CGPointMake(
            (toView.frame.size.width * bar.frame.origin.x),
            (toView.frame.size.height * bar.frame.origin.y)
        )
        toView.layer.addSublayer(shape)
        return shape;
    }
}

extension CALayer{
    func wmf_addWelcomeAnimation(animation: WelcomeAnimation) {
        self.transform = animation.initialTransform;
        self.addAnimation(CABasicAnimation.wmf_animationToXF(animation.finalTransform, delay: animation.delay, duration: animation.duration), forKey: nil)
        
        self.opacity = Float(animation.initialOpacity);
        self.addAnimation(CABasicAnimation.wmf_animationToOpacity(animation.finalOpacity, delay: animation.delay, duration: animation.duration), forKey: nil)
    }
}

extension CABasicAnimation{
    class func wmf_animationToXF(transform: CATransform3D, delay: Double, duration: Double) -> CABasicAnimation {
        let anim = CABasicAnimation(keyPath: "transform")
        anim.duration = duration
        anim.beginTime = CACurrentMediaTime() + delay
        anim.fillMode = kCAFillModeForwards
        anim.removedOnCompletion = false
        anim.toValue = NSValue(CATransform3D: transform)
        anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        return anim;
    }
    class func wmf_animationToOpacity(opacity: Double, delay: Double, duration: Double) -> CABasicAnimation {
        let anim = CABasicAnimation(keyPath: "opacity")
        anim.duration = duration
        anim.beginTime = CACurrentMediaTime() + delay
        anim.fillMode = kCAFillModeForwards
        anim.removedOnCompletion = false
        anim.toValue = opacity
        anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        return anim;
    }
}

extension UIView{
    func wmf_addCircles(circles: WelcomeCircle...) {
        for circle: WelcomeCircle in circles {
            let circleShape = circle.isDashed ? CAShapeLayer.wmf_addDashedCircle(circle, toView: self) : CAShapeLayer.wmf_addCircle(circle, toView:self)
            circleShape.wmf_addWelcomeAnimation(circle.animation);
        }
    }
    func wmf_addPluses(pluses: WelcomePlus...) {
        for plus: WelcomePlus in pluses {
            let plusShape = CAShapeLayer.wmf_addPlus(plus, toView:self)
            plusShape.wmf_addWelcomeAnimation(plus.animation);
        }
    }
    func wmf_addLines(lines: WelcomeLine...) {
        for line: WelcomeLine in lines {
            let lineShape = CAShapeLayer.wmf_addLine(line, toView:self)
            lineShape.wmf_addWelcomeAnimation(line.animation);
        }
    }
    func wmf_addBars(bars: WelcomeBar...) {
        for bar: WelcomeBar in bars {
            let barShape = CAShapeLayer.wmf_addBar(bar, toView:self)
            barShape.wmf_addWelcomeAnimation(bar.animation);
        }
    }
    func wmf_addImages(images: WelcomeImage...) -> [UIImageView] {
        return images.map({ (image) -> UIImageView in
            let imageView = UIImageView(frame: image.frame)
            imageView.image = UIImage(named: image.name)
            imageView.contentMode = UIViewContentMode.ScaleAspectFit;
            imageView.layer.zPosition = image.zPosition
            imageView.layer.wmf_addWelcomeAnimation(image.animation);
            self.addSubview(imageView)
            return imageView
        })
    }
    
    func wmf_configureForIntroAnimation(){
        CATransaction.begin()
        
        let finalDashedCircleOpacity = 0.15
        let finalCircleOpacity = 0.09
        let finalPlusOpacity = 0.15
        let finalLinesOpacity = 0.15
        let scaleZeroXF = CATransform3DMakeScale(0, 0, 1)
        let rightXF = CATransform3DMakeTranslation(50, 0, 0)
        
        let view = self
        view.backgroundColor = UIColor.clearColor()

        let bgImageView = UIImageView(frame: view.bounds)
        bgImageView.image = UIImage(named: "background.jpg")
        bgImageView.contentMode = UIViewContentMode.ScaleAspectFit;
        bgImageView.layer.zPosition = 99
        view.addSubview(bgImageView)
        
        let rotationPoint = CGPointMake(0.575,  0.3821)
        
        let angle = CGFloat((M_PI * 2.0) / 360.0) * -45.0;
        let rotateTransform = CATransform3DMakeRotation(angle, 0.0, 0.0, 1.0)
        
        let rectCorrectingForRotate = CGRectMake(view.bounds.origin.x - (view.bounds.size.width * (0.5 - rotationPoint.x)), view.bounds.origin.y - (view.bounds.size.height * (0.5 - rotationPoint.y)), view.bounds.size.width, view.bounds.size.height)

        let images = view.wmf_addImages(
            WelcomeImage(
                name: "ftux-telescope-base",
                frame: view.bounds,
                zPosition: 101,
                animation: WelcomeAnimation(
                    delay: 0.3,
                    duration: 1.0,
                    initialOpacity: 1.0,
                    finalOpacity: 1.0,
                    initialTransform: CATransform3DIdentity,
                    finalTransform: CATransform3DIdentity
                )
            ),
            WelcomeImage(
                name: "ftux-telescope-tube",
                frame: rectCorrectingForRotate,
                zPosition: 101,
                animation: WelcomeAnimation(
                    delay: 0.3,
                    duration: 1.0,
                    initialOpacity: 1.0,
                    finalOpacity: 1.0,
                    initialTransform: rotateTransform,
                    finalTransform: CATransform3DIdentity
                )
            )
        )
        images[1].layer.anchorPoint = rotationPoint
        
        view.wmf_addCircles(
            WelcomeCircle(
                position: CGPointMake(0.625, 0.55),
                radius: 0.32,
                isDashed: false,
                animation:WelcomeAnimation(
                    delay: 0.3,
                    duration: 1.0,
                    initialOpacity: 0.0,
                    finalOpacity: finalCircleOpacity,
                    initialTransform: scaleZeroXF,
                    finalTransform: CATransform3DIdentity
                )
            ),
            WelcomeCircle(
                position: CGPointMake(0.521, 0.531),
                radius: 0.304,
                isDashed: true,
                animation: WelcomeAnimation(
                    delay: 0.3,
                    duration: 1.0,
                    initialOpacity: 0.0,
                    finalOpacity: finalDashedCircleOpacity,
                    initialTransform: scaleZeroXF,
                    finalTransform: CATransform3DIdentity
                )
            )
        )
        
        view.wmf_addPluses(
            WelcomePlus(
                position: CGPointMake(0.033, 0.219),
                animation: WelcomeAnimation(
                    delay: 0.3,
                    duration: 1.0,
                    initialOpacity: 0.0,
                    finalOpacity: finalPlusOpacity,
                    initialTransform: scaleZeroXF,
                    finalTransform: CATransform3DIdentity
                )
            ),
            WelcomePlus(
                position: CGPointMake(0.11, 0.16),
                animation: WelcomeAnimation(
                    delay: 0.3,
                    duration: 1.0,
                    initialOpacity: 0.0,
                    finalOpacity: finalPlusOpacity,
                    initialTransform: scaleZeroXF,
                    finalTransform: CATransform3DIdentity
                )
            )
        )
        
        let linesXF: CATransform3D  = CATransform3DConcat(scaleZeroXF, rightXF)
        view.wmf_addLines(
            WelcomeLine(
                position: CGPointMake(0.91, 0.778),
                width: 0.144,
                animation: WelcomeAnimation(
                    delay: 0.3,
                    duration: 1.0,
                    initialOpacity: 0.0,
                    finalOpacity: finalLinesOpacity,
                    initialTransform: linesXF,
                    finalTransform: CATransform3DIdentity
                )
            ),
            WelcomeLine(
                position: CGPointMake(0.836, 0.81),
                width: 0.06,
                animation: WelcomeAnimation(
                    delay: 0.3,
                    duration: 1.0,
                    initialOpacity: 0.0,
                    finalOpacity: finalLinesOpacity,
                    initialTransform: linesXF,
                    finalTransform: CATransform3DIdentity
                )
            ),
            WelcomeLine(
                position: CGPointMake(0.907, 0.81),
                width: 0.0125,
                animation: WelcomeAnimation(
                    delay: 0.3,
                    duration: 1.0,
                    initialOpacity: 0.0,
                    finalOpacity: finalLinesOpacity,
                    initialTransform: linesXF,
                    finalTransform: CATransform3DIdentity
                )
            )
        )
        
        CATransaction.commit()
    }
    
    func wmf_configureForLanguagesAnimation(){
        CATransaction.begin()

        let finalDashedCircleOpacity = 0.15
        let finalCircleOpacity = 0.04
        let finalPlusOpacity = 0.15
        let finalLinesOpacity = 0.15
        let scaleZeroXF = CATransform3DMakeScale(0, 0, 1)
        let leftXF = CATransform3DMakeTranslation(-50, 0, 0)

        let lowerLeftXF = CATransform3DMakeTranslation(-50, 50, 0)
        let lowerRightXF = CATransform3DMakeTranslation(50, 50, 0)
        
        let view = self
        view.backgroundColor = UIColor.clearColor()
        
        view.wmf_addImages(
            WelcomeImage(
                name: "ftux-left-bubble",
                frame: view.bounds,
                zPosition: 102,
                animation: WelcomeAnimation(
                    delay: 0.1,
                    duration: 1.0,
                    initialOpacity: 0.0,
                    finalOpacity: 1.0,
                    initialTransform: CATransform3DConcat(scaleZeroXF, lowerLeftXF),
                    finalTransform: CATransform3DIdentity
                )
            ),
            WelcomeImage(
                name: "ftux-right-bubble",
                frame: view.bounds,
                zPosition: 101,
                animation: WelcomeAnimation(
                    delay: 0.3,
                    duration: 1.0,
                    initialOpacity: 0.0,
                    finalOpacity: 1.0,
                    initialTransform: CATransform3DConcat(scaleZeroXF, lowerRightXF),
                    finalTransform: CATransform3DIdentity
                )
            )
        )
        
        view.wmf_addCircles(
            WelcomeCircle(
                position: CGPointMake(0.39, 0.5),
                radius: 0.31,
                isDashed: false,
                animation:WelcomeAnimation(
                    delay: 0.1,
                    duration: 1.0,
                    initialOpacity: 0.0,
                    finalOpacity: finalCircleOpacity,
                    initialTransform: scaleZeroXF,
                    finalTransform: CATransform3DIdentity
                )
            ),
            WelcomeCircle(
                position: CGPointMake(0.508, 0.518),
                radius: 0.31,
                isDashed: true,
                animation: WelcomeAnimation(
                    delay: 0.1,
                    duration: 1.0,
                    initialOpacity: 0.0,
                    finalOpacity: finalDashedCircleOpacity,
                    initialTransform: scaleZeroXF,
                    finalTransform: CATransform3DIdentity
                )
            )
        )
 
        view.wmf_addPluses(
            WelcomePlus(
                position: CGPointMake(0.825, 0.225),
                animation: WelcomeAnimation(
                    delay: 0.1,
                    duration: 1.0,
                    initialOpacity: 0.0,
                    finalOpacity: finalPlusOpacity,
                    initialTransform: scaleZeroXF,
                    finalTransform: CATransform3DIdentity
                )
            ),
            WelcomePlus(
                position: CGPointMake(0.755, 0.17),
                animation: WelcomeAnimation(
                    delay: 0.1,
                    duration: 1.0,
                    initialOpacity: 0.0,
                    finalOpacity: finalPlusOpacity,
                    initialTransform: scaleZeroXF,
                    finalTransform: CATransform3DIdentity
                )
            ),
            WelcomePlus(
                position: CGPointMake(0.112, 0.353),
                animation: WelcomeAnimation(
                    delay: 0.1,
                    duration: 1.0,
                    initialOpacity: 0.0,
                    finalOpacity: finalPlusOpacity,
                    initialTransform: scaleZeroXF,
                    finalTransform: CATransform3DIdentity
                )
            )
        )
        
        let linesXF: CATransform3D  = CATransform3DConcat(scaleZeroXF, leftXF)
        view.wmf_addLines(
            WelcomeLine(
                position: CGPointMake(0.845, 0.865),
                width: 0.135,
                animation: WelcomeAnimation(
                    delay: 0.1,
                    duration: 1.0,
                    initialOpacity: 0.0,
                    finalOpacity: finalLinesOpacity,
                    initialTransform: linesXF,
                    finalTransform: CATransform3DIdentity
                )
            ),
            WelcomeLine(
                position: CGPointMake(0.255, 0.162),
                width: 0.135,
                animation: WelcomeAnimation(
                    delay: 0.1,
                    duration: 1.0,
                    initialOpacity: 0.0,
                    finalOpacity: finalLinesOpacity,
                    initialTransform: linesXF,
                    finalTransform: CATransform3DIdentity
                )
            ),
            WelcomeLine(
                position: CGPointMake(0.205, 0.127),
                width: 0.135,
                animation: WelcomeAnimation(
                    delay: 0.1,
                    duration: 1.0,
                    initialOpacity: 0.0,
                    finalOpacity: finalLinesOpacity,
                    initialTransform: linesXF,
                    finalTransform: CATransform3DIdentity
                )
            )
        )
        
        CATransaction.commit()
    }
    
    func wmf_configureForAnalyticsAnimation(){
        CATransaction.begin()

        let finalDashedCircleOpacity = 0.15
        let finalCircleOpacity = 0.04
        let finalPlusOpacity = 0.15
        let finalLinesOpacity = 0.15
        let scaleZeroXF = CATransform3DMakeScale(0, 0, 1)
        let leftXF = CATransform3DMakeTranslation(-50, 0, 0)
        let rightXF = CATransform3DMakeTranslation(50, 0, 0)
        
        let view = self
        view.backgroundColor = UIColor.clearColor()

        let images = view.wmf_addImages(
            WelcomeImage(
                name: "ftux-file",
                frame: view.bounds,
                zPosition: 101,
                animation: WelcomeAnimation(
                    delay: 0.1,
                    duration: 1.0,
                    initialOpacity: 0.0,
                    finalOpacity: 1.0,
                    initialTransform: leftXF,
                    finalTransform: CATransform3DIdentity
                )
            )
        )
        
        view.wmf_addCircles(
            WelcomeCircle(
                position: CGPointMake(0.654, 0.41),
                radius: 0.235,
                isDashed: false,
                animation:WelcomeAnimation(
                    delay: 0.1,
                    duration: 1.0,
                    initialOpacity: 0.0,
                    finalOpacity: finalCircleOpacity,
                    initialTransform: scaleZeroXF,
                    finalTransform: CATransform3DIdentity
                )
            ),
            WelcomeCircle(
                position: CGPointMake(0.61, 0.44),
                radius: 0.258,
                isDashed: true,
                animation: WelcomeAnimation(
                    delay: 0.1,
                    duration: 1.0,
                    initialOpacity: 0.0,
                    finalOpacity: finalDashedCircleOpacity,
                    initialTransform: scaleZeroXF,
                    finalTransform: CATransform3DIdentity
                )
            )
        )
        
        view.wmf_addPluses(
            WelcomePlus(
                position: CGPointMake(0.9, 0.222),
                animation: WelcomeAnimation(
                    delay: 0.1,
                    duration: 1.0,
                    initialOpacity: 0.0,
                    finalOpacity: finalPlusOpacity,
                    initialTransform: scaleZeroXF,
                    finalTransform: CATransform3DIdentity
                )
            ),
            WelcomePlus(
                position: CGPointMake(0.832, 0.167),
                animation: WelcomeAnimation(
                    delay: 0.1,
                    duration: 1.0,
                    initialOpacity: 0.0,
                    finalOpacity: finalPlusOpacity,
                    initialTransform: scaleZeroXF,
                    finalTransform: CATransform3DIdentity
                )
            )
        )

        let linesLeftXF: CATransform3D  = CATransform3DConcat(scaleZeroXF, rightXF)
        let linesRightXF: CATransform3D  = CATransform3DConcat(scaleZeroXF, leftXF)
        view.wmf_addLines(
            WelcomeLine(
                position: CGPointMake(0.82, 0.778),
                width: 0.125,
                animation: WelcomeAnimation(
                    delay: 0.1,
                    duration: 1.0,
                    initialOpacity: 0.0,
                    finalOpacity: finalLinesOpacity,
                    initialTransform: linesLeftXF,
                    finalTransform: CATransform3DIdentity
                )
            ),
            WelcomeLine(
                position: CGPointMake(0.775, 0.736),
                width: 0.127,
                animation: WelcomeAnimation(
                    delay: 0.1,
                    duration: 1.0,
                    initialOpacity: 0.0,
                    finalOpacity: finalLinesOpacity,
                    initialTransform: linesLeftXF,
                    finalTransform: CATransform3DIdentity
                )
            ),
            WelcomeLine(
                position: CGPointMake(0.233, 0.385),
                width: 0.043,
                animation: WelcomeAnimation(
                    delay: 0.1,
                    duration: 1.0,
                    initialOpacity: 0.0,
                    finalOpacity: finalLinesOpacity,
                    initialTransform: linesRightXF,
                    finalTransform: CATransform3DIdentity
                )
            ),
            WelcomeLine(
                position: CGPointMake(0.17, 0.385),
                width: 0.015,
                animation: WelcomeAnimation(
                    delay: 0.1,
                    duration: 1.0,
                    initialOpacity: 0.0,
                    finalOpacity: finalLinesOpacity,
                    initialTransform: linesRightXF,
                    finalTransform: CATransform3DIdentity
                )
            ),
            WelcomeLine(
                position: CGPointMake(0.11, 0.427),
                width: 0.043,
                animation: WelcomeAnimation(
                    delay: 0.1,
                    duration: 1.0,
                    initialOpacity: 0.0,
                    finalOpacity: finalLinesOpacity,
                    initialTransform: linesRightXF,
                    finalTransform: CATransform3DIdentity
                )
            ),
            WelcomeLine(
                position: CGPointMake(0.173, 0.427),
                width: 0.015,
                animation: WelcomeAnimation(
                    delay: 0.1,
                    duration: 1.0,
                    initialOpacity: 0.0,
                    finalOpacity: finalLinesOpacity,
                    initialTransform: linesRightXF,
                    finalTransform: CATransform3DIdentity
                )
            )
        )
        
        let squashedHeightXF = CATransform3DMakeScale(1, 0, 1)
        let fullHeightXF = CATransform3DMakeScale(1, -1, 1) // -1 to flip Y so bars animate from bottom up.
        let blue = UIColor(red: 0.1216, green: 0.5804, blue: 0.8667, alpha: 1.0)
        let green = UIColor(red: 0.0000, green: 0.6941, blue: 0.5490, alpha: 1.0)

        images[0].wmf_addBars(
            WelcomeBar(
                    frame: CGRectMake(0.313, 0.64, 0.039, 0.18),
                    color: blue,
                    cornerRadius: 0.0,
                    animation:WelcomeAnimation(
                        delay: 0.3,
                        duration: 0.3,
                        initialOpacity: 0.0,
                        finalOpacity: 1.0,
                        initialTransform: squashedHeightXF,
                        finalTransform: fullHeightXF
                )
            ),
            WelcomeBar(
                frame: CGRectMake(0.383, 0.64, 0.039, 0.23),
                color: green,
                cornerRadius: 0.0,
                animation:WelcomeAnimation(
                    delay: 0.4,
                    duration: 0.3,
                    initialOpacity: 0.0,
                    finalOpacity: 1.0,
                    initialTransform: squashedHeightXF,
                    finalTransform: fullHeightXF
                )
            ),
            WelcomeBar(
                frame: CGRectMake(0.453, 0.64, 0.039, 0.06),
                color: blue,
                cornerRadius: 0.0,
                animation:WelcomeAnimation(
                    delay: 0.5,
                    duration: 0.3,
                    initialOpacity: 0.0,
                    finalOpacity: 1.0,
                    initialTransform: squashedHeightXF,
                    finalTransform: fullHeightXF
                )
            ),
            WelcomeBar(
                frame: CGRectMake(0.523, 0.64, 0.039, 0.12),
                color: green,
                cornerRadius: 0.0,
                animation:WelcomeAnimation(
                    delay: 0.6,
                    duration: 0.3,
                    initialOpacity: 0.0,
                    finalOpacity: 1.0,
                    initialTransform: squashedHeightXF,
                    finalTransform: fullHeightXF
                )
            ),
            WelcomeBar(
                frame: CGRectMake(0.593, 0.64, 0.039, 0.15),
                color: blue,
                cornerRadius: 0.0,
                animation:WelcomeAnimation(
                    delay: 0.7,
                    duration: 0.3,
                    initialOpacity: 0.0,
                    finalOpacity: 1.0,
                    initialTransform: squashedHeightXF,
                    finalTransform: fullHeightXF
                )
            )
        )
        
        CATransaction.commit()
    }
}
