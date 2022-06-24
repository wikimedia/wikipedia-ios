import MapKit

extension MKCoordinateRegion {
    var width: CLLocationDistance {
        let halfLongitudeDelta = span.longitudeDelta * 0.5
        let left =  CLLocation(latitude: center.latitude, longitude: center.longitude - halfLongitudeDelta)
        let right =  CLLocation(latitude: center.latitude, longitude: center.longitude + halfLongitudeDelta)
        let width = right.distance(from: left)
        return width
    }
    
    var height: CLLocationDistance {
        let halfLatitudeDelta = span.latitudeDelta * 0.5
        let top = CLLocation(latitude: center.latitude + halfLatitudeDelta, longitude: center.longitude)
        let bottom = CLLocation(latitude: center.latitude - halfLatitudeDelta, longitude: center.longitude)
        let height = top.distance(from: bottom)
        return height
    }
}
