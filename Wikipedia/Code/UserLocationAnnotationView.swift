import MapKit

class UserLocationAnnotationView: MKAnnotationView {
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        let dimension = 14
        frame = CGRect(x: 0, y: 0, width: dimension, height: dimension)
        
        layer.borderWidth = 3
        layer.borderColor = UIColor.white.cgColor
        backgroundColor = UIColor.wmf_blueTint()
        self.annotation = annotation
    }
    
    required init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = round(0.5*bounds.size.width)
    }

}
