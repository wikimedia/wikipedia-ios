#if OSM

import Mapbox

public class MapAnnotation: NSObject, MGLAnnotation {
    public dynamic var coordinate: CLLocationCoordinate2D

    init?(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        super.init()
        setup()
    }
    
    open func setup() {
    }
}
    
public class MapAnnotationView: MGLAnnotationView {
    var isSetup = false
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    open func setup() {
        isSetup = true
    }
}
    
#else

import MapKit

public class MapAnnotation: NSObject, MKAnnotation {
    public dynamic var coordinate: CLLocationCoordinate2D
    
    init?(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        super.init()
        setup()
    }
    
    open func setup() {
    }
}

public class MapAnnotationView: MKAnnotationView {
    var isSetup = false

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    open func setup() {
        isSetup = true
    }
}
    
#endif
