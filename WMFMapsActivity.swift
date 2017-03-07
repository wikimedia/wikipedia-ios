import Foundation

class WMFMapsActivity : UIActivity {
    
    public var coordinate: CLLocationCoordinate2D?
    
    override open var activityType: UIActivityType? {
        get {
            return UIActivityType(rawValue: String(describing: self))
        }
    }
    
    override open func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        
        for activityItem in activityItems {
            if (activityItem is CLLocationCoordinate2D) {
                return true
            }
        }
        
        return false
    }
    
    override open func prepare(withActivityItems activityItems: [Any]) {
        
        for activityItem in activityItems {
            guard let coordinate = activityItem as? CLLocationCoordinate2D else {
                continue
            }
            self.coordinate = coordinate
        }
    }
}


class WMFOpenInMapsActivity : WMFMapsActivity {

    
    override open var activityTitle: String? {
        get {
            return  localizedStringForKeyFallingBackOnEnglish("share-open-in-maps")
        }
    }
    
    override func perform() {
        DDLogDebug("did it")
        activityDidFinish(true)
    }
}


class WMFGetDirectionsInMapsActivity : WMFMapsActivity {

    override open var activityTitle: String? {
        get {
            return  localizedStringForKeyFallingBackOnEnglish("share-get-directions-in-maps")
        }
    }
    
    override func perform() {
        DDLogDebug("did it")
        activityDidFinish(true)
    }
}
