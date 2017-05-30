import Foundation

extension WMFNearbyArticleCollectionViewCell {
    func update(userLocation: CLLocation?, heading: CLHeading?) {
        guard let articleLocation = articleLocation, let userLocation = userLocation else {
            configureForUnknownDistance()
            return
        }
        
        let distance = articleLocation.distance(from: userLocation)
        setDistance(distance)
        
        if let heading = heading  {
            let bearing = userLocation.wmf_bearing(to: articleLocation, forCurrentHeading: heading)
            setBearing(bearing)
        } else {
            let bearing = userLocation.wmf_bearing(to: articleLocation)
            setBearing(bearing)
        }
    }
}


extension WMFNearbyArticleTableViewCell {
    func update(userLocation: CLLocation?, heading: CLHeading?) {
        guard let articleLocation = articleLocation, let userLocation = userLocation else {
            configureForUnknownDistance()
            return
        }
        
        let distance = articleLocation.distance(from: userLocation)
        setDistance(distance)
        
        if let heading = heading  {
            let bearing = userLocation.wmf_bearing(to: articleLocation, forCurrentHeading: heading)
            setBearing(bearing)
        } else {
            let bearing = userLocation.wmf_bearing(to: articleLocation)
            setBearing(bearing)
        }
    }
}
