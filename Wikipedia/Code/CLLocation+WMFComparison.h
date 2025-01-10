#import <CoreLocation/CoreLocation.h>

@interface CLLocation (WMFComparison)

- (BOOL)wmf_isEqual:(CLLocation *)location;

@end
