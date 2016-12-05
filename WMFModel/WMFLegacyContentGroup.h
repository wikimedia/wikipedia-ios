#import <Mantle/Mantle.h>

@interface WMFLegacyContentGroup : MTLModel //This exists solely for the migration from YapDB to Core Data

@property (nonatomic, strong, readonly) NSDate *date;
@property (nonatomic, strong, readonly) NSURL *siteURL;

@property (nonatomic, strong, readonly) NSURL *articleURL;

@property (nonatomic, strong, readonly) CLLocation *location;
@property (nonatomic, strong, readonly) CLPlacemark *placemark;

@property (nonatomic, strong, readonly) NSDate *mostReadDate;

@property (nonatomic, strong, readonly) NSString *identifier;
@property (nonatomic, strong, readonly) NSDate *visibilityStartDate;
@property (nonatomic, strong, readonly) NSDate *visibilityEndDate;
@property (nonatomic, assign, readonly) BOOL wasDismissed;
@property (nonatomic, assign, readonly) BOOL isVisible;

@end
