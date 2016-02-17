
#import "WMFLocationSearchResults.h"
#import "MWKLocationSearchResult.h"
#import "MWKTitle.h"
#import "MWKSite.h"

@interface WMFLocationSearchResults ()

@property (nonatomic, strong, readwrite) MWKSite* searchSite;
@property (nonatomic, strong, readwrite) CLLocation* location;
@property (nonatomic, strong, readwrite) NSArray<MWKLocationSearchResult*>* results;

@end

@implementation WMFLocationSearchResults

- (instancetype)initWithSite:(MWKSite*)site location:(CLLocation*)location results:(NSArray<MWKLocationSearchResult*>*)results {
    self = [super init];
    if (self) {
        self.searchSite = site;
        self.location   = location;
        self.results    = [results sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:WMF_SAFE_KEYPATH([MWKLocationSearchResult new], distanceFromQueryCoordinates) ascending:YES]]];;
    }
    return self;
}

- (MWKTitle*)titleForResultAtIndex:(NSUInteger)index {
    return [self titleForResult:self.results[index]];
}

- (MWKTitle*)titleForResult:(MWKLocationSearchResult*)result {
    return [[MWKTitle alloc] initWithString:result.displayTitle site:self.searchSite];
}

@end
