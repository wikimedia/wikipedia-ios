
#import <Foundation/Foundation.h>
@import CoreLocation;

@interface WMFLocationSearchResults : NSObject

@property (nonatomic, strong, readonly) CLLocation* location;
@property (nonatomic, strong, readonly) NSArray* results;

- (instancetype)initWithLocation:(CLLocation*)location results:(NSArray*)results;

@end
