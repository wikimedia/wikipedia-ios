
#import "WMFBaseExploreSectionController.h"
@import CoreLocation;
@class WMFLocationManager, MWKDataStore;

NS_ASSUME_NONNULL_BEGIN

extern NSString* const WMFNearbySectionIdentifier;

@interface WMFNearbySectionController : WMFBaseExploreSectionController
    <WMFExploreSectionController, WMFTitleProviding, WMFMoreFooterProviding, WMFAnalyticsContentTypeProviding>

- (instancetype)initWithLocation:(CLLocation*)location
                       placemark:(nullable CLPlacemark*)placemark
                 searchSiteURL:(NSURL*)url
                       dataStore:(MWKDataStore*)dataStore NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore NS_UNAVAILABLE;

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore items:(NSArray*)items NS_UNAVAILABLE;

@property (nonatomic, strong, readonly) NSURL* searchSiteURL;
@property (nonatomic, strong, readonly) CLLocation* location;
@property (nonatomic, strong, readonly) CLPlacemark* placemark;

@end

NS_ASSUME_NONNULL_END