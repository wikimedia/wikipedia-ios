#import "WMFLegacyContentGroup.h"

@interface WMFLegacyContentGroup ()

@property (nonatomic, strong, readwrite) NSDate *date;
@property (nonatomic, strong, readwrite) NSURL *siteURL;

@property (nonatomic, strong, readwrite) NSURL *articleURL;

@property (nonatomic, strong, readwrite) CLLocation *location;
@property (nonatomic, strong, readwrite) CLPlacemark *placemark;

@property (nonatomic, strong, readwrite) NSDate *mostReadDate;

@property (nonatomic, strong, readwrite) NSString *identifier;
@property (nonatomic, strong, readwrite) NSDate *visibilityStartDate;
@property (nonatomic, strong, readwrite) NSDate *visibilityEndDate;
@property (nonatomic, assign, readwrite) BOOL wasDismissed;
@property (nonatomic, assign, readwrite) BOOL isVisible;

@end

@implementation WMFLegacyContentGroup

@end
