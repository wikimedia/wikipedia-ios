
#import "WMFLocationSearchResults.h"
#import "MWKLocationSearchResult.h"

@interface WMFLocationSearchResults ()

@property (nonatomic, strong, readwrite) CLLocation* location;
@property (nonatomic, strong, readwrite) NSArray* results;

@end

@implementation WMFLocationSearchResults

- (instancetype)initWithLocation:(CLLocation*)location results:(NSArray*)results {
    self = [super init];
    if (self) {
        self.location = location;
        self.results  = [results sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:WMF_SAFE_KEYPATH([MWKLocationSearchResult new], distanceFromQueryCoordinates) ascending:YES]]];;
    }
    return self;
}

@end
