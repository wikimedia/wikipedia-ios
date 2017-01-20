import Foundation


extension WMFArticle {
    var coordinate: CLLocationCoordinate2D? {
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
}
