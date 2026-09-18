import Foundation

/// SecureUnarchiveFromDataTransformer allows us to utilize transformable properties with a list of allowed classes
@objc(WMFSecureUnarchiveFromDataTransformer)
class SecureUnarchiveFromDataTransformer: NSSecureUnarchiveFromDataTransformer {
    override class var allowedTopLevelClasses: [AnyClass] {
        // The feed and Places archive these classes into Core Data. Remove them together with the Explore feed.
        let bridgeClasses: [AnyClass] = [WMFFeedArticlePreview.self, WMFFeedTopReadArticlePreview.self, WMFFeedNewsStory.self, WMFFeedOnThisDayEvent.self, WMFFeedImage.self, MWKSearchResult.self, MWKLocationSearchResult.self]
        return super.allowedTopLevelClasses + [NSSet.self, CLLocation.self, CLPlacemark.self, RemoteNotificationLinks.self, RemoteNotificationLink.self] + bridgeClasses
    }
}
