import Foundation


extension WMFArticle {
    public var coordinate: CLLocationCoordinate2D? {
        get {
            guard let signedQuadKey = signedQuadKey else {
                return nil
            }
            let signedQuadKeyInteger = signedQuadKey.int64Value
            let quadKey = QuadKey(int64: signedQuadKeyInteger)
            let coordinate = QuadKeyCoordinate(quadKey: quadKey)
            let latitude = coordinate.latitudePart.latitude
            let longitude = coordinate.longitudePart.longitude
            return CLLocationCoordinate2DMake(latitude, longitude)
        }
        
        set {
            guard let newValue = newValue else {
                signedQuadKey = nil
                return
            }
            let quadKey = QuadKey(latitude: newValue.latitude, longitude: newValue.longitude)
            let signedQuadKeyInteger = Int64(quadKey: quadKey)
            signedQuadKey = NSNumber(value: signedQuadKeyInteger)
        }
    }
    
    public var location: CLLocation? {
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
}
