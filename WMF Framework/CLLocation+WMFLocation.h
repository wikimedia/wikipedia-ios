@import CoreLocation;
#import <WMF/NSUserActivity+WMFExtensions.h>


@interface CLLocation (WMFLocation)
+ (nullable instancetype)locationWithDictionary:(nullable WMFLocation)dictionary;
@end
