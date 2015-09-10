
#import <Foundation/Foundation.h>
@import CoreLocation;

@class MWKTitle, MWKLocationSearchResult;

@interface WMFLocationSearchResults : NSObject

@property (nonatomic, strong, readonly) MWKSite* searchSite;
@property (nonatomic, strong, readonly) CLLocation* location;
@property (nonatomic, strong, readonly) NSArray* results;

- (instancetype)initWithSite:(MWKSite*)site Location:(CLLocation*)location results:(NSArray*)results;

- (MWKTitle*)titleForResult:(MWKLocationSearchResult*)result;

- (MWKTitle*)titleForResultAtIndex:(NSUInteger)index;

@end
