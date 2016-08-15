#import "WMFLocationSearchResults.h"
#import "MWKLocationSearchResult.h"

@interface WMFLocationSearchResults ()

@property(nonatomic, strong, readwrite) NSURL *searchSiteURL;
@property(nonatomic, strong, readwrite) CLLocation *location;
@property(nonatomic, strong, readwrite) NSArray<MWKLocationSearchResult *> *results;

@end

@implementation WMFLocationSearchResults

- (instancetype)initWithSearchSiteURL:(NSURL *)url location:(CLLocation *)location results:(NSArray<MWKLocationSearchResult *> *)results {
    self = [super init];
    if (self) {
        self.searchSiteURL = url;
        self.location = location;
        self.results = [results sortedArrayUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:WMF_SAFE_KEYPATH([MWKLocationSearchResult new], distanceFromQueryCoordinates) ascending:YES] ]];
        ;
    }
    return self;
}

- (NSURL *)urlForResultAtIndex:(NSUInteger)index {
    return [self urlForResult:self.results[index]];
}

- (NSURL *)urlForResult:(MWKLocationSearchResult *)result {
    return [self.searchSiteURL wmf_URLWithTitle:result.displayTitle];
}

@end
