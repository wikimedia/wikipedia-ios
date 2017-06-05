import Mapbox

func MGLCoordinateRegionMakeWithDistance(_ centerCoordinate: CLLocationCoordinate2D, _ latitudinalMeters: CLLocationDistance, _ longitudinalMeters: CLLocationDistance) -> MGLCoordinateRegion {
    let mkRegion = MKCoordinateRegionMakeWithDistance(centerCoordinate, latitudinalMeters, longitudinalMeters)
    return MGLCoordinateRegion(center: mkRegion.center, span: MGLCoordinateSpan(latitudeDelta: mkRegion.span.latitudeDelta, longitudeDelta: mkRegion.span.longitudeDelta))
}

struct MGLCoordinateRegion {
    var center: CLLocationCoordinate2D
    var span: MGLCoordinateSpan
    
    var coordinateBounds: MGLCoordinateBounds {
        get {
            let sw = CLLocationCoordinate2D(latitude: center.latitude - span.latitudeDelta, longitude: center.longitude + span.longitudeDelta)
            let ne = CLLocationCoordinate2D(latitude: center.latitude + span.latitudeDelta, longitude: center.longitude - span.longitudeDelta)
            return MGLCoordinateBounds(sw: sw, ne: ne)
        }
    }
    
    init(center: CLLocationCoordinate2D, span: MGLCoordinateSpan) {
        self.center = center
        self.span = span
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

extension MGLMapView {
    func regionThatFits(_ region: MGLCoordinateRegion) -> MGLCoordinateRegion {
        return region
    }
    
    var region: MGLCoordinateRegion {
        get {
            return MGLCoordinateRegion(visibleCoordinateBounds)
        }
        set {
            visibleCoordinateBounds = newValue.coordinateBounds
        }
    }
}
