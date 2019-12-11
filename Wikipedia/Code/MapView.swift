import MapKit
    
class MapView: MKMapView {
    var visibleAnnotations: Set<AnyHashable> {
        return annotations(in: visibleMapRect)
    }
}
