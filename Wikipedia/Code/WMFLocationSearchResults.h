
#import <Foundation/Foundation.h>
@import CoreLocation;

@class MWKTitle, MWKLocationSearchResult, MWKSite;

@interface WMFLocationSearchResults : NSObject

@property (nonatomic, strong, readonly) MWKSite* searchSite;
@property (nonatomic, strong, readonly) CLLocation* location;
@property (nonatomic, strong, readonly) NSArray<MWKLocationSearchResult*>* results;

- (instancetype)initWithSite:(MWKSite*)site location:(CLLocation*)location results:(NSArray<MWKLocationSearchResult*>*)results;

- (MWKTitle*)titleForResult:(MWKLocationSearchResult*)result;

- (MWKTitle*)titleForResultAtIndex:(NSUInteger)index;

@end
