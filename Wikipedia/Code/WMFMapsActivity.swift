import Foundation

class WMFMapsActivity : UIActivity {
    
    public var mapItem: MKMapItem?
    
    override open var activityType: UIActivityType? {
        get {
            return UIActivityType(rawValue: String(describing: self))
        }
    }
    
    override open func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        
        for activityItem in activityItems {
            if (activityItem is MKMapItem) {
                return true
            }
        }
        
        return false
    }
    
    override open func prepare(withActivityItems activityItems: [Any]) {
        
        for activityItem in activityItems {
            guard let mapItem = activityItem as? MKMapItem else {
                continue
            }
            self.mapItem = mapItem
        }
    }
}


class WMFOpenInMapsActivity : WMFMapsActivity {

    
    override open var activityTitle: String? {
        get {
            return localizedStringForKeyFallingBackOnEnglish("share-open-in-maps")
        }
    }
    
    override open var activityImage: UIImage? {
        get {
            return UIImage(named: "places-map")
        }
    }
    
    override func perform() {
        
        guard let mapItem = self.mapItem else {
            assertionFailure("MapItem should have been set")
            return
        }
        
        mapItem.openInMaps(launchOptions: nil)
        
        activityDidFinish(true)
    }
}


class WMFGetDirectionsInMapsActivity : WMFMapsActivity {

    override open var activityTitle: String? {
        get {
            return  localizedStringForKeyFallingBackOnEnglish("share-get-directions-in-maps")
        }
    }
    
    override open var activityImage: UIImage? {
        get {
            return UIImage(named: "places-location-arrow")
        }
    }
    
    override func perform() {
        
        guard let mapItem = self.mapItem else {
            assertionFailure("MapItem should have been set")
            return
        }
        
        if #available(iOS 10.0, *) {
            mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault])
        } else {
            mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
        }
        
        activityDidFinish(true)
    }
}
