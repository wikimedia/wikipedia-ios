@import CoreLocation;
#import <WMF/NSUserActivity+WMFExtensions.h>


@interface CLLocation (WMFDictionary)
+ (nullable instancetype)locationWithDictionary:(nullable WMFLocation)dictionary;
@end
