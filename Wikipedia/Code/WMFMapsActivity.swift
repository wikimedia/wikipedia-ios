import Foundation
import MapKit

class WMFMapsActivity : UIActivity {
    
    public var mapItem: MKMapItem?
    
    override open var activityType: UIActivity.ActivityType? {
        get {
            return UIActivity.ActivityType(rawValue: String(describing: self))
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
            return WMFLocalizedString("share-open-in-maps", value:"Open in Maps", comment:"Button to open current article's location in the Maps app.")
        }
    }
    
    override open var activityImage: UIImage? {
        get {
            return UIImage(named: "share-open-in-maps")
        }
    }
    
    override func perform() {
        
        guard let mapItem = self.mapItem else {
            assertionFailure("MapItem not set")
            activityDidFinish(false)
            return
        }
        
        mapItem.openInMaps(launchOptions: nil)
        
        activityDidFinish(true)
    }
}


class WMFGetDirectionsInMapsActivity : WMFMapsActivity {

    override open var activityTitle: String? {
        get {
            return  WMFLocalizedString("share-get-directions-in-maps", value:"Get Directions", comment:"Button to get directions to the current article's location in the Maps app.")
        }
    }
    
    override open var activityImage: UIImage? {
        get {
            return UIImage(named: "share-get-directions")
        }
    }
    
    override func perform() {
        
        guard let mapItem = self.mapItem else {
            assertionFailure("MapItem not set")
            activityDidFinish(false)
            return
        }
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault])
        activityDidFinish(true)
    }
}
