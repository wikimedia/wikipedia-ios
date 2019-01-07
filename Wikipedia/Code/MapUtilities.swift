import MapKit

extension Array where Element == CLLocationCoordinate2D {
    func wmf_boundingRegion(with boundingMetersPerPoint: Double) -> MKCoordinateRegion {
        var rect: MKMapRect?
        for coordinate in self {
            let point = MKMapPoint(coordinate)
            let mapPointsPerMeter = MKMapPointsPerMeterAtLatitude(coordinate.latitude)
            let dimension = mapPointsPerMeter * boundingMetersPerPoint
            let size = MKMapSize(width: dimension, height: dimension)
            let coordinateRect = MKMapRect(origin: MKMapPoint(x: point.x - 0.5*dimension, y: point.y - 0.5*dimension), size: size)
            guard let currentRect = rect else {
                rect = coordinateRect
                continue
            }
            rect = currentRect.union(coordinateRect)
        }
        
        guard let finalRect = rect else {
            return MKCoordinateRegion()
        }
        
        var region = MKCoordinateRegion(finalRect)
        if region.span.latitudeDelta < 0.01 {
            region.span.latitudeDelta = 0.01
        }
        if region.span.longitudeDelta < 0.01 {
            region.span.longitudeDelta = 0.01
        }
        return region
    }
}
