#import "CLLocation+WMFLocation.h"

@implementation CLLocation (WMFLocation)

+ (nullable instancetype)locationWithDictionary:(nullable WMFLocation)dictionary {
    if (dictionary == nil) {
        return nil;
    }
    
    NSNumber *latitudeNumber = [dictionary objectForKey:@"lat"];
    NSNumber *longitudeNumber = [dictionary objectForKey:@"long"];
    
    if (latitudeNumber == nil || longitudeNumber == nil) {
        return nil;
    }
    
    CLLocationDegrees latitude = [latitudeNumber doubleValue];
    CLLocationDegrees longitude = [longitudeNumber doubleValue];
    CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
    return location;
}

@end
