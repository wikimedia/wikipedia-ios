import MapKit

#if OSM
    
import Mapbox

class MapView: MGLMapView {
    override var annotations: [MGLAnnotation] {
        return super.annotations ?? []
    }
    
    override var visibleAnnotations: [MGLAnnotation] {
        return super.annotations ?? []
    }
    
    override var userLocation: MGLUserLocation {
        return super.userLocation ?? MGLUserLocation()
    }
}
    
extension MGLMapView {
    func regionThatFits(_ region: MKCoordinateRegion) -> MKCoordinateRegion {
        return region
    }
    
    var region: MKCoordinateRegion {
        get {
            return MKCoordinateRegion(visibleCoordinateBounds)
        }
        set {
            visibleCoordinateBounds = newValue.coordinateBounds
        }
    }
    
    func setRegion(_ region: MKCoordinateRegion, animated: Bool) {
        self.region = region
    }
}
    
#else
    
class MapView: MKMapView {
    var visibleAnnotations: Set<AnyHashable> {
        return annotations(in: visibleMapRect)
    }
}
    
#endif
