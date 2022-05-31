import Foundation

extension ArticleLocationCollectionViewCell {
    func update(userLocation: CLLocation?, heading: CLHeading?) {
        guard let articleLocation = articleLocation, let userLocation = userLocation else {
            configureForUnknownDistance()
            return
        }

        distance = articleLocation.distance(from: userLocation)

        if let heading = heading {
            bearing = userLocation.wmf_bearing(to: articleLocation, forCurrentHeading: heading)
        } else {
            bearing = userLocation.wmf_bearing(to: articleLocation)
        }
    }
}
