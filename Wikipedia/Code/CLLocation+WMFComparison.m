#import <WMF/CLLocation+WMFComparison.h>
#import <WMF/WMFComparison.h>

@implementation CLLocation (WMFComparison)

- (BOOL)wmf_isEqual:(CLLocation *)rhs {
    if (self == rhs) {
        return YES;
    } else if (![rhs isKindOfClass:[CLLocation class]]) {
        return NO;
    } else {
        return [self distanceFromLocation:rhs] == 0 && self.horizontalAccuracy == rhs.horizontalAccuracy && self.verticalAccuracy == rhs.verticalAccuracy && [self.timestamp isEqualToDate:rhs.timestamp] && self.speed == rhs.speed && self.course == rhs.course;
    }
}

@end
