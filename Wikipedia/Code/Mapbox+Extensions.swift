import Mapbox
import MapKit

extension MKCoordinateSpan {
    init(_ span: MGLCoordinateSpan) {
        self.init(latitudeDelta: span.latitudeDelta, longitudeDelta:span.longitudeDelta)
    }
}

extension MKCoordinateRegion {
    var coordinateBounds: MGLCoordinateBounds {
        get {
            let sw = CLLocationCoordinate2D(latitude: center.latitude - span.latitudeDelta, longitude: center.longitude + span.longitudeDelta)
            let ne = CLLocationCoordinate2D(latitude: center.latitude + span.latitudeDelta, longitude: center.longitude - span.longitudeDelta)
            return MGLCoordinateBounds(sw: sw, ne: ne)
        }
    }
    
    init(center: CLLocationCoordinate2D, span: MGLCoordinateSpan) {
        self.init(center: center, span:  MKCoordinateSpan(span))
    }
    
    init(_ bounds: MGLCoordinateBounds) {
        let centerLat = 0.5*(bounds.ne.latitude + bounds.sw.latitude)
        let centerLon = 0.5*(bounds.ne.longitude + bounds.sw.longitude)
        let deltaLat = abs(bounds.ne.latitude - bounds.sw.latitude)
        let deltaLon = abs(bounds.ne.longitude - bounds.sw.longitude)
        
        self.init(center: CLLocationCoordinate2D(latitude: centerLat, longitude:centerLon), span: MGLCoordinateSpan(latitudeDelta: deltaLat, longitudeDelta: deltaLon))
    }
    
    init() {
        self.init(center: CLLocationCoordinate2D(latitude: 0, longitude:0), span: MGLCoordinateSpan(latitudeDelta: 0, longitudeDelta: 0))
    }
}
