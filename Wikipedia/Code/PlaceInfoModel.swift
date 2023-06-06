import Foundation

@objc class PlaceInfoModel: NSObject {
    
    private(set) var latitude: Double = 0
    private(set) var longitude: Double = 0

    @objc init?(_ dictionary: [String: Any]?) {
        
        guard let placeInfo = dictionary?["placeInfo"] as? [String: Any],
              let latitude = (placeInfo["latitude"] as? String).flatMap(Double.init),
            let longitude = (placeInfo["longitude"] as? String).flatMap(Double.init) else {
                return nil
            }
        self.latitude = latitude
        self.longitude = longitude
        super.init()
    }
    
    private override init() {
        super.init()
    }
}
