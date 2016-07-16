
#import <Foundation/Foundation.h>
@import CoreLocation;

@class MWKLocationSearchResult;

@interface WMFLocationSearchResults : NSObject

@property (nonatomic, strong, readonly) NSURL* searchDomainURL;
@property (nonatomic, strong, readonly) CLLocation* location;
@property (nonatomic, strong, readonly) NSArray<MWKLocationSearchResult*>* results;

- (instancetype)initWithSearchDomainURL:(NSURL*)url location:(CLLocation*)location results:(NSArray<MWKLocationSearchResult*>*)results;

- (NSURL*)urlForResult:(MWKLocationSearchResult*)result;

- (NSURL*)urlForResultAtIndex:(NSUInteger)index;

@end
