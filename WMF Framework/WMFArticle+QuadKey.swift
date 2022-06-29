import Foundation
import MapKit

extension WMFArticle {
     public var quadKey: QuadKey? {
        get {
            guard let signedQuadKey = signedQuadKey else {
                return nil
            }
            let signedQuadKeyInteger = signedQuadKey.int64Value
            let quadKey = QuadKey(int64: signedQuadKeyInteger)
            return quadKey
        }
        
        set {
            guard let newValue = newValue else {
                signedQuadKey = nil
                return
            }
            let signedQuadKeyInteger = Int64(quadKey: newValue)
            signedQuadKey = NSNumber(value: signedQuadKeyInteger)
        }
    }
    
    public var coordinate: CLLocationCoordinate2D? {
        get {
            guard let quadKey = quadKey else {
                return nil
            }
            let coordinate = QuadKeyCoordinate(quadKey: quadKey)
            let latitude = coordinate.latitudePart.latitude
            let longitude = coordinate.longitudePart.longitude
            return CLLocationCoordinate2DMake(latitude, longitude)
        }
        
        set {
            guard let newValue = newValue else {
                quadKey = nil
                return
            }
            quadKey = QuadKey(latitude: newValue.latitude, longitude: newValue.longitude)
        }
    }
    
    // allows us to keep coordinate optional above
    @objc public func update(scalarCoordinate: CLLocationCoordinate2D) {
        coordinate = CLLocationCoordinate2DIsValid(scalarCoordinate) ? scalarCoordinate : nil
    }
    
    @objc public var location: CLLocation? {
        get {
            guard let coordinate = coordinate else {
                return nil
            }
            return CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        }
        
        set {
            coordinate = newValue?.coordinate
        }
    }
    
    @objc public var mapItem: MKMapItem? {
        guard let coord = self.coordinate,
            CLLocationCoordinate2DIsValid(coord) else {
                return nil
        }

        let placemark = MKPlacemark(coordinate: coord, addressDictionary: nil )
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = self.displayTitle
        return mapItem
    }
}
