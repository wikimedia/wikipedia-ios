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


extension ArticleWithLocationTableViewCell {
    func update(userLocation: CLLocation?, heading: CLHeading?) {
        guard let articleLocation = articleWithLocationCollectionViewCell.articleLocation, let userLocation = userLocation else {
            articleWithLocationCollectionViewCell.configureForUnknownDistance()
            return
        }
        
        let distance = articleLocation.distance(from: userLocation)
        articleWithLocationCollectionViewCell.setDistance(distance)
        
        if let heading = heading  {
            let bearing = userLocation.wmf_bearing(to: articleLocation, forCurrentHeading: heading)
            articleWithLocationCollectionViewCell.setBearing(bearing)
        } else {
            let bearing = userLocation.wmf_bearing(to: articleLocation)
            articleWithLocationCollectionViewCell.setBearing(bearing)
        }
    }
}
