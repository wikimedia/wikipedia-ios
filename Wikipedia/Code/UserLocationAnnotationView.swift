import MapKit
import CoreLocation.CLLocation

class UserLocationAnnotationView: MKAnnotationView {
    
    let shapeLayer = CAShapeLayer()
    let dotLayer = CALayer()
    
    
    var isHeadingArrowVisible = false {
        didSet {
            shapeLayer.isHidden = !isHeadingArrowVisible
        }
    }
    
    var heading: CLLocationDirection = 0 {
        didSet {
            let transform = CATransform3DMakeRotation(CGFloat(heading/180.0)*CGFloat.pi, 0, 0, 1.0)
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.3)
            shapeLayer.transform = transform
            CATransaction.setCompletionBlock {
                self.shapeLayer.transform = transform
            }
            CATransaction.commit()
        }
    }
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        let arrowWidth: CGFloat = 12
        let arrowHeight: CGFloat = 8

        let dotImage = #imageLiteral(resourceName: "places-user-location")
        let dotDimension: CGFloat = dotImage.size.width
        let dimension = arrowHeight + dotDimension
        
        frame = CGRect(x: 0, y: 0, width: dimension, height: dimension)
        layer.zPosition = -1
        

        
        let path = UIBezierPath()

        path.move(to: CGPoint(x: 0.5*dimension - 0.5*arrowWidth, y:arrowHeight))
        path.addLine(to: CGPoint(x: 0.5*dimension, y:0))
        path.addLine(to: CGPoint(x: 0.5*dimension + 0.5*arrowWidth, y:arrowHeight))
        path.close()
        
        shapeLayer.isHidden = true
        shapeLayer.frame = layer.bounds
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = UIColor.wmf_blueTint.cgColor
        layer.addSublayer(shapeLayer)
        
        
        dotLayer.bounds = CGRect(x: 0, y: 0, width: dotImage.size.width, height: dotImage.size.height)
        dotLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        dotLayer.contents = dotImage.cgImage
        layer.addSublayer(dotLayer)
        
        self.annotation = annotation
    }
    
    required init?(coder aDecoder: NSCoder) {
        return nil
    }
    

}
