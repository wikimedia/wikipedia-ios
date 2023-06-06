import Foundation

@objc class PlaceInfoModel: NSObject {
    
    private(set) var latitude: Double = 0
    private(set) var longitude: Double = 0
    
    @objc init?(_ dictionary: [String: Any]?) {
        
        let anyToDouble: (Any?) -> Double? = { input in
            return input
                .flatMap(String.init(describing:))
                .flatMap(Double.init)
        }
        guard let placeInfo = dictionary?["placeInfo"] as? [String: Any],
              let latitude = anyToDouble(placeInfo["latitude"]),
              let longitude = anyToDouble(placeInfo["longitude"]) else {
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
