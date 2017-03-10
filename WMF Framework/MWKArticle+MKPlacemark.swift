import MapKit.MKMapItem
import CoreLocation.CLLocation

extension MWKArticle {
    
    public var mapItem: MKMapItem? {
        get {
            guard CLLocationCoordinate2DIsValid(self.coordinate) else {
                return nil
            }
        
            let placemark = MKPlacemark(coordinate: self.coordinate, addressDictionary: nil )
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = self.displaytitle
            return mapItem
        }
    }
}
